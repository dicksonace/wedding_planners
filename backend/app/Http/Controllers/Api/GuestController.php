<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\AuthorizesCouple;
use App\Mail\GuestInvitationMail;
use App\Models\Guest;
use App\Models\WeddingPlan;
use App\Services\GuestListImporter;
use App\Support\AppMail;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
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

        $invitationSent = false;
        if ($sendInvitation && $guest->email) {
            $invitationSent = $this->dispatchInvitation($guest);
        }

        return response()->json([
            'message' => $invitationSent
                ? 'Guest added and invitation email sent.'
                : 'Guest added successfully.',
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

        if (! $this->dispatchInvitation($guest)) {
            return response()->json([
                'message' => 'Unable to send the invitation email right now. Please try again shortly.',
            ], 503);
        }

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
            'file' => ['required', 'file', 'mimes:csv,txt,xlsx,xls,docx,doc', 'max:10240'],
        ]);

        $importer = new GuestListImporter;
        $extracted = $importer->extractRows($request->file('file'));

        if ($extracted['error']) {
            return response()->json(['message' => $extracted['error']], 422);
        }

        $mapped = $importer->mapGuests($extracted['rows']);

        foreach ($mapped['guests'] as $guestData) {
            $weddingPlan->guests()->create($guestData);
        }

        return response()->json([
            'message' => "Imported {$mapped['created']} guest(s). Skipped {$mapped['skipped']}.",
            'created' => $mapped['created'],
            'skipped' => $mapped['skipped'],
            'errors' => $mapped['errors'],
            'data' => $weddingPlan->guests()->latest()->get(),
        ]);
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

    private function dispatchInvitation(Guest $guest): bool
    {
        $guest->load('weddingPlan');
        $token = $guest->ensureInvitationToken();

        $rsvpUrl = url("/rsvp/{$token}");
        $acceptUrl = url("/rsvp/{$token}/accept");
        $declineUrl = url("/rsvp/{$token}/decline");

        $sent = AppMail::send(
            $guest->email,
            new GuestInvitationMail($guest, $rsvpUrl, $acceptUrl, $declineUrl),
        );

        if ($sent) {
            $guest->update(['invitation_sent_at' => now()]);
        }

        return $sent;
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
