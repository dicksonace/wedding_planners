<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Guest;
use App\Models\WeddingPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GuestController extends Controller
{
    public function index(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizePlan($request, $weddingPlan);

        return response()->json(['data' => $weddingPlan->guests()->latest()->get()]);
    }

    public function store(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizePlan($request, $weddingPlan);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:20'],
            'email' => ['nullable', 'email', 'max:255'],
            'side' => ['nullable', 'in:bride,groom,both'],
            'rsvp_status' => ['nullable', 'in:pending,confirmed,declined'],
            'plus_one' => ['nullable', 'boolean'],
            'table_number' => ['nullable', 'integer', 'min:1'],
        ]);

        $guest = $weddingPlan->guests()->create($validated);

        return response()->json([
            'message' => 'Guest added successfully.',
            'data' => $guest,
        ], 201);
    }

    public function update(Request $request, WeddingPlan $weddingPlan, Guest $guest): JsonResponse
    {
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
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeGuest($weddingPlan, $guest);
        $guest->delete();

        return response()->json(['message' => 'Guest removed successfully.']);
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
