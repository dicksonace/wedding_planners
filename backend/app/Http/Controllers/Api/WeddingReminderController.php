<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\AuthorizesCouple;
use App\Models\WeddingPlan;
use App\Models\WeddingReminder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WeddingReminderController extends Controller
{
    use AuthorizesCouple;

    public function index(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $reminders = $weddingPlan->reminders()
            ->orderBy('remind_at')
            ->get();

        return response()->json(['data' => $reminders]);
    }

    public function store(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'category' => ['nullable', 'in:fitting,hair,makeup,venue,vendor,other'],
            'remind_at' => ['required', 'date'],
            'is_done' => ['nullable', 'boolean'],
        ]);

        $reminder = $weddingPlan->reminders()->create($validated);

        return response()->json([
            'message' => 'Reminder added.',
            'data' => $reminder,
        ], 201);
    }

    public function update(Request $request, WeddingPlan $weddingPlan, WeddingReminder $reminder): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        abort_if($reminder->wedding_plan_id !== $weddingPlan->id, 404);

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'category' => ['nullable', 'in:fitting,hair,makeup,venue,vendor,other'],
            'remind_at' => ['sometimes', 'date'],
            'is_done' => ['nullable', 'boolean'],
        ]);

        $reminder->update($validated);

        return response()->json([
            'message' => 'Reminder updated.',
            'data' => $reminder->fresh(),
        ]);
    }

    public function destroy(Request $request, WeddingPlan $weddingPlan, WeddingReminder $reminder): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        abort_if($reminder->wedding_plan_id !== $weddingPlan->id, 404);
        $reminder->delete();

        return response()->json(['message' => 'Reminder removed.']);
    }

    private function authorizePlan(Request $request, WeddingPlan $weddingPlan): void
    {
        abort_if($weddingPlan->user_id !== $request->user()->id, 403, 'Unauthorized.');
    }
}
