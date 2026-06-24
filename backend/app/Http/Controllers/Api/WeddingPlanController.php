<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\AuthorizesCouple;
use App\Models\WeddingPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WeddingPlanController extends Controller
{
    use AuthorizesCouple;

    public function index(Request $request): JsonResponse
    {
        $this->authorizeCouple($request);

        $plans = $request->user()
            ->weddingPlans()
            ->withCount(['guests', 'tasks', 'budgetItems'])
            ->latest()
            ->get();

        return response()->json(['data' => $plans]);
    }

    public function store(Request $request): JsonResponse
    {
        $this->authorizeCouple($request);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'bride_name' => ['nullable', 'string', 'max:255'],
            'groom_name' => ['nullable', 'string', 'max:255'],
            'wedding_date' => ['nullable', 'date'],
            'location' => ['nullable', 'string', 'max:255'],
            'region' => ['nullable', 'string', 'max:255'],
            'total_budget' => ['nullable', 'numeric', 'min:0'],
            'ceremony_types' => ['nullable', 'array'],
            'ceremony_types.*' => ['string', 'max:100'],
            'status' => ['nullable', 'string', 'max:50'],
            'notes' => ['nullable', 'string'],
        ]);

        $plan = $request->user()->weddingPlans()->create($validated);

        return response()->json([
            'message' => 'Wedding plan created successfully.',
            'data' => $plan,
        ], 201);
    }

    public function show(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $weddingPlan->load(['guests', 'budgetItems', 'tasks', 'vendorRequests.vendor']);

        return response()->json(['data' => $weddingPlan]);
    }

    public function update(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'bride_name' => ['nullable', 'string', 'max:255'],
            'groom_name' => ['nullable', 'string', 'max:255'],
            'wedding_date' => ['nullable', 'date'],
            'location' => ['nullable', 'string', 'max:255'],
            'region' => ['nullable', 'string', 'max:255'],
            'total_budget' => ['nullable', 'numeric', 'min:0'],
            'ceremony_types' => ['nullable', 'array'],
            'ceremony_types.*' => ['string', 'max:100'],
            'status' => ['nullable', 'string', 'max:50'],
            'notes' => ['nullable', 'string'],
        ]);

        $weddingPlan->update($validated);

        return response()->json([
            'message' => 'Wedding plan updated successfully.',
            'data' => $weddingPlan->fresh(),
        ]);
    }

    public function destroy(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $weddingPlan->delete();

        return response()->json(['message' => 'Wedding plan deleted successfully.']);
    }

    private function authorizePlan(Request $request, WeddingPlan $weddingPlan): void
    {
        abort_if($weddingPlan->user_id !== $request->user()->id, 403, 'Unauthorized.');
    }
}
