<?php

namespace App\Http\Controllers;

use App\Models\Guest;
use Illuminate\Http\Request;
use Illuminate\View\View;

class RsvpController extends Controller
{
    public function show(string $token): View
    {
        $guest = $this->findGuest($token);
        $plan = $guest->weddingPlan;

        return view('rsvp.show', [
            'guest' => $guest,
            'plan' => $plan,
            'acceptUrl' => url("/rsvp/{$token}/accept"),
            'declineUrl' => url("/rsvp/{$token}/decline"),
        ]);
    }

    public function accept(string $token): View
    {
        $guest = $this->findGuest($token);
        $guest->update(['rsvp_status' => 'confirmed']);

        return view('rsvp.result', [
            'guest' => $guest->fresh(),
            'plan' => $guest->weddingPlan,
            'status' => 'confirmed',
        ]);
    }

    public function decline(string $token): View
    {
        $guest = $this->findGuest($token);
        $guest->update(['rsvp_status' => 'declined']);

        return view('rsvp.result', [
            'guest' => $guest->fresh(),
            'plan' => $guest->weddingPlan,
            'status' => 'declined',
        ]);
    }

    private function findGuest(string $token): Guest
    {
        return Guest::with('weddingPlan')
            ->where('invitation_token', $token)
            ->firstOrFail();
    }
}
