<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BudgetItem;
use App\Models\WeddingPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BudgetItemController extends Controller
{
    public function index(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizePlan($request, $weddingPlan);

        $items = $weddingPlan->budgetItems()->latest()->get()->map(fn (BudgetItem $item) => [
            'id' => $item->id,
            'wedding_plan_id' => $item->wedding_plan_id,
            'category' => $item->category,
            'description' => $item->description,
            'estimated_amount' => (float) $item->estimated_amount,
            'actual_amount' => (float) $item->actual_amount,
            'is_paid' => $item->is_paid,
            'payment_date' => $item->payment_date?->toDateString(),
            'created_at' => $item->created_at,
            'updated_at' => $item->updated_at,
        ]);
        $summary = [
            'total_budget' => (float) $weddingPlan->total_budget,
            'estimated_total' => (float) $items->sum('estimated_amount'),
            'actual_total' => (float) $items->sum('actual_amount'),
            'paid_total' => (float) $items->where('is_paid', true)->sum('actual_amount'),
        ];

        return response()->json(['data' => $items, 'summary' => $summary]);
    }

    public function store(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizePlan($request, $weddingPlan);

        $validated = $request->validate([
            'category' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:255'],
            'estimated_amount' => ['nullable', 'numeric', 'min:0'],
            'actual_amount' => ['nullable', 'numeric', 'min:0'],
            'is_paid' => ['nullable', 'boolean'],
            'payment_date' => ['nullable', 'date'],
        ]);

        $item = $weddingPlan->budgetItems()->create($validated);

        return response()->json([
            'message' => 'Budget item added successfully.',
            'data' => $item,
        ], 201);
    }

    public function update(Request $request, WeddingPlan $weddingPlan, BudgetItem $budgetItem): JsonResponse
    {
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeItem($weddingPlan, $budgetItem);

        $validated = $request->validate([
            'category' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'string', 'max:255'],
            'estimated_amount' => ['nullable', 'numeric', 'min:0'],
            'actual_amount' => ['nullable', 'numeric', 'min:0'],
            'is_paid' => ['nullable', 'boolean'],
            'payment_date' => ['nullable', 'date'],
        ]);

        $budgetItem->update($validated);

        return response()->json([
            'message' => 'Budget item updated successfully.',
            'data' => $budgetItem->fresh(),
        ]);
    }

    public function destroy(Request $request, WeddingPlan $weddingPlan, BudgetItem $budgetItem): JsonResponse
    {
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeItem($weddingPlan, $budgetItem);
        $budgetItem->delete();

        return response()->json(['message' => 'Budget item deleted successfully.']);
    }

    private function authorizePlan(Request $request, WeddingPlan $weddingPlan): void
    {
        abort_if($weddingPlan->user_id !== $request->user()->id, 403, 'Unauthorized.');
    }

    private function authorizeItem(WeddingPlan $weddingPlan, BudgetItem $budgetItem): void
    {
        abort_if($budgetItem->wedding_plan_id !== $weddingPlan->id, 404, 'Budget item not found.');
    }
}
