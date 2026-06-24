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

class GuestController extends Controller
{
    use AuthorizesCouple;

    public function index(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        return response()->json(['data' => $weddingPlan->guests()->latest()->get()]);
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
        ]);
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
