<?php

namespace App\Http\Controllers;

use App\Models\WeddingPlan;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class GuestRegistrationController extends Controller
{
    public function show(string $token): View
    {
        $plan = $this->findPlan($token);

        return view('guest-register.show', [
            'plan' => $plan,
            'token' => $token,
        ]);
    }

    public function store(Request $request, string $token): View|RedirectResponse
    {
        $plan = $this->findPlan($token);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['nullable', 'email', 'max:255'],
            'phone' => ['nullable', 'string', 'max:20'],
            'side' => ['nullable', 'in:bride,groom,both'],
            'plus_one' => ['nullable', 'boolean'],
            'attending' => ['required', 'in:yes,no,maybe'],
        ]);

        $status = match ($validated['attending']) {
            'yes' => 'confirmed',
            'no' => 'declined',
            default => 'pending',
        };

        $guest = $plan->guests()->create([
            'name' => $validated['name'],
            'email' => $validated['email'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'side' => $validated['side'] ?? 'both',
            'plus_one' => (bool) ($validated['plus_one'] ?? false),
            'rsvp_status' => $status,
        ]);

        $guest->ensureInvitationToken();

        return view('guest-register.result', [
            'plan' => $plan,
            'guest' => $guest->fresh(),
            'status' => $status,
        ]);
    }

    private function findPlan(string $token): WeddingPlan
    {
        return WeddingPlan::query()
            ->where('guest_registration_token', $token)
            ->firstOrFail();
    }
}
