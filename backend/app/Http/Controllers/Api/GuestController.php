<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\AuthorizesCouple;
use App\Mail\GuestInvitationMail;
use App\Models\Guest;
use App\Models\WeddingPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class GuestController extends Controller
{
    use AuthorizesCouple;

    public function index(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $guests = $weddingPlan->guests()->latest()->get()->map(function (Guest $guest) {
            $token = $guest->invitation_token;
            return array_merge($guest->toArray(), [
                'invite_url' => $token ? url("/rsvp/{$token}") : null,
            ]);
        });

        return response()->json([
            'data' => $guests,
            'registration' => $this->registrationPayload($weddingPlan),
        ]);
    }

    public function store(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:20'],
            'email' => ['nullable', 'email', 'max:255'],
            'side' => ['nullable', 'in:bride,groom,both'],
            'rsvp_status' => ['nullable', 'in:pending,confirmed,declined'],
            'plus_one' => ['nullable', 'boolean'],
            'table_number' => ['nullable', 'integer', 'min:1'],
            'send_invitation' => ['nullable', 'boolean'],
        ]);

        $sendInvitation = (bool) ($validated['send_invitation'] ?? false);
        unset($validated['send_invitation']);

        $guest = $weddingPlan->guests()->create($validated);

        if ($sendInvitation && $guest->email) {
            $this->dispatchInvitation($guest);
        }

        return response()->json([
            'message' => 'Guest added successfully.',
            'data' => $guest->fresh(),
        ], 201);
    }

    public function update(Request $request, WeddingPlan $weddingPlan, Guest $guest): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeGuest($weddingPlan, $guest);

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:20'],
            'email' => ['nullable', 'email', 'max:255'],
            'side' => ['nullable', 'in:bride,groom,both'],
            'rsvp_status' => ['nullable', 'in:pending,confirmed,declined'],
            'plus_one' => ['nullable', 'boolean'],
            'table_number' => ['nullable', 'integer', 'min:1'],
        ]);

        $guest->update($validated);

        return response()->json([
            'message' => 'Guest updated successfully.',
            'data' => $guest->fresh(),
        ]);
    }

    public function destroy(Request $request, WeddingPlan $weddingPlan, Guest $guest): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeGuest($weddingPlan, $guest);
        $guest->delete();

        return response()->json(['message' => 'Guest removed successfully.']);
    }

    public function sendInvitation(Request $request, WeddingPlan $weddingPlan, Guest $guest): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeGuest($weddingPlan, $guest);

        if (empty($guest->email)) {
            return response()->json(['message' => 'Guest email is required to send an invitation.'], 422);
        }

        $this->dispatchInvitation($guest);

        return response()->json([
            'message' => 'Invitation email sent successfully.',
            'data' => $guest->fresh(),
            'invite_url' => url('/rsvp/'.$guest->fresh()->invitation_token),
        ]);
    }

    public function inviteLink(Request $request, WeddingPlan $weddingPlan, Guest $guest): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeGuest($weddingPlan, $guest);

        $token = $guest->ensureInvitationToken();

        return response()->json([
            'data' => [
                'invite_url' => url("/rsvp/{$token}"),
                'accept_url' => url("/rsvp/{$token}/accept"),
                'decline_url' => url("/rsvp/{$token}/decline"),
                'guest' => $guest->fresh(),
            ],
        ]);
    }

    public function registrationLink(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        return response()->json([
            'data' => $this->registrationPayload($weddingPlan, regenerate: $request->boolean('regenerate')),
        ]);
    }

    public function import(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $request->validate([
            'file' => ['required', 'file', 'mimes:csv,txt,xlsx,xls', 'max:5120'],
        ]);

        $file = $request->file('file');
        $extension = strtolower($file->getClientOriginalExtension());
        $created = 0;
        $skipped = 0;
        $errors = [];

        if (in_array($extension, ['xlsx', 'xls'], true)) {
            return response()->json([
                'message' => 'Please export your Excel file as CSV (Save As → CSV) and upload that. Word files should also be converted to CSV.',
            ], 422);
        }

        $handle = fopen($file->getRealPath(), 'r');
        if ($handle === false) {
            return response()->json(['message' => 'Could not read uploaded file.'], 422);
        }

        $header = null;
        $rowNum = 0;
        while (($row = fgetcsv($handle)) !== false) {
            $rowNum++;
            if ($row === [null] || $row === false) {
                continue;
            }

            $cells = array_map(fn ($c) => trim((string) $c), $row);
            if ($header === null) {
                $header = array_map(fn ($h) => Str::of($h)->lower()->replace(' ', '_')->toString(), $cells);
                // If first row looks like data (has a name-like value and no header keywords), treat as data
                $joined = implode(',', $header);
                if (! str_contains($joined, 'name') && ! str_contains($joined, 'email') && ! str_contains($joined, 'phone')) {
                    $mapped = $this->mapImportRow(['name', 'email', 'phone', 'side'], $cells);
                    if ($mapped) {
                        $weddingPlan->guests()->create($mapped);
                        $created++;
                    } else {
                        $skipped++;
                    }
                    $header = ['name', 'email', 'phone', 'side'];
                }
                continue;
            }

            $mapped = $this->mapImportRow($header, $cells);
            if (! $mapped) {
                $skipped++;
                $errors[] = "Row {$rowNum}: missing name";
                continue;
            }

            $weddingPlan->guests()->create($mapped);
            $created++;
        }
        fclose($handle);

        return response()->json([
            'message' => "Imported {$created} guest(s). Skipped {$skipped}.",
            'created' => $created,
            'skipped' => $skipped,
            'errors' => array_slice($errors, 0, 10),
            'data' => $weddingPlan->guests()->latest()->get(),
        ]);
    }

    /**
     * @param  list<string>  $header
     * @param  list<string>  $cells
     * @return array<string, mixed>|null
     */
    private function mapImportRow(array $header, array $cells): ?array
    {
        $assoc = [];
        foreach ($header as $i => $key) {
            $assoc[$key] = $cells[$i] ?? '';
        }

        $name = $assoc['name'] ?? $assoc['full_name'] ?? $assoc['guest_name'] ?? ($cells[0] ?? '');
        $name = trim((string) $name);
        if ($name === '') {
            return null;
        }

        $side = strtolower((string) ($assoc['side'] ?? 'both'));
        if (! in_array($side, ['bride', 'groom', 'both'], true)) {
            $side = 'both';
        }

        $rsvp = strtolower((string) ($assoc['rsvp'] ?? $assoc['rsvp_status'] ?? 'pending'));
        if (! in_array($rsvp, ['pending', 'confirmed', 'declined'], true)) {
            $rsvp = 'pending';
        }

        return [
            'name' => $name,
            'email' => ($assoc['email'] ?? '') !== '' ? $assoc['email'] : null,
            'phone' => ($assoc['phone'] ?? $assoc['mobile'] ?? '') !== ''
                ? ($assoc['phone'] ?? $assoc['mobile'])
                : null,
            'side' => $side,
            'rsvp_status' => $rsvp,
            'plus_one' => in_array(strtolower((string) ($assoc['plus_one'] ?? '')), ['1', 'yes', 'true', 'y'], true),
        ];
    }

    /**
     * @return array{token: string, url: string, qr_url: string}
     */
    private function registrationPayload(WeddingPlan $weddingPlan, bool $regenerate = false): array
    {
        if ($regenerate || empty($weddingPlan->guest_registration_token)) {
            $weddingPlan->update(['guest_registration_token' => Str::random(48)]);
            $weddingPlan->refresh();
        }

        $token = $weddingPlan->guest_registration_token;
        $url = url("/guest-register/{$token}");

        return [
            'token' => $token,
            'url' => $url,
            'qr_url' => 'https://api.qrserver.com/v1/create-qr-code/?size=280x280&data='.urlencode($url),
        ];
    }

    private function dispatchInvitation(Guest $guest): void
    {
        $guest->load('weddingPlan');
        $token = $guest->ensureInvitationToken();

        $rsvpUrl = url("/rsvp/{$token}");
        $acceptUrl = url("/rsvp/{$token}/accept");
        $declineUrl = url("/rsvp/{$token}/decline");

        Mail::to($guest->email)->send(new GuestInvitationMail($guest, $rsvpUrl, $acceptUrl, $declineUrl));

        $guest->update(['invitation_sent_at' => now()]);
    }

    private function authorizePlan(Request $request, WeddingPlan $weddingPlan): void
    {
        abort_if($weddingPlan->user_id !== $request->user()->id, 403, 'Unauthorized.');
    }

    private function authorizeGuest(WeddingPlan $weddingPlan, Guest $guest): void
    {
        abort_if($guest->wedding_plan_id !== $weddingPlan->id, 404, 'Guest not found.');
    }
}
