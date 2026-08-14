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

        $plan = $request->user()->weddingPlans()->create($this->planAttributes($validated, creating: true));

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

        $weddingPlan->update($this->planAttributes($validated));

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

    /**
     * Hostinger MySQL rejects NULL on total_budget even though the column has a default.
     *
     * @param  array<string, mixed>  $validated
     * @return array<string, mixed>
     */
    private function planAttributes(array $validated, bool $creating = false): array
    {
        if ($creating || array_key_exists('total_budget', $validated)) {
            $validated['total_budget'] = round((float) ($validated['total_budget'] ?? 0), 2);
        }

        if ($creating || array_key_exists('ceremony_types', $validated)) {
            $validated['ceremony_types'] = array_values($validated['ceremony_types'] ?? []);
        }

        if ($creating && blank($validated['status'] ?? null)) {
            $validated['status'] = 'planning';
        }

        return $validated;
    }
}
