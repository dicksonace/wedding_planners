<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\AuthorizesCouple;
use App\Models\BudgetItem;
use App\Models\WeddingPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class BudgetItemController extends Controller
{
    use AuthorizesCouple;

    public function index(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $rawItems = $weddingPlan->budgetItems()->latest()->get();
        $items = $rawItems->map(fn (BudgetItem $item) => $this->formatItem($item));

        return response()->json([
            'data' => $items,
            'summary' => $this->buildSummary($weddingPlan, $rawItems),
        ]);
    }

    public function store(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
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
            'data' => $this->formatItem($item),
        ], 201);
    }

    public function update(Request $request, WeddingPlan $weddingPlan, BudgetItem $budgetItem): JsonResponse
    {
        $this->authorizeCouple($request);
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

        if (($validated['is_paid'] ?? false) && empty($validated['payment_date'])) {
            $validated['payment_date'] = now()->toDateString();
        }

        $budgetItem->update($validated);

        return response()->json([
            'message' => 'Budget item updated successfully.',
            'data' => $this->formatItem($budgetItem->fresh()),
        ]);
    }

    public function destroy(Request $request, WeddingPlan $weddingPlan, BudgetItem $budgetItem): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeItem($weddingPlan, $budgetItem);
        $budgetItem->delete();

        return response()->json(['message' => 'Budget item deleted successfully.']);
    }

    private function formatItem(BudgetItem $item): array
    {
        return [
            'id' => $item->id,
            'wedding_plan_id' => $item->wedding_plan_id,
            'category' => $item->category,
            'description' => $item->description,
            'estimated_amount' => (float) $item->estimated_amount,
            'actual_amount' => (float) $item->actual_amount,
            'is_paid' => $item->is_paid,
            'payment_date' => $item->payment_date?->toDateString(),
            'variance' => (float) $item->actual_amount - (float) $item->estimated_amount,
            'created_at' => $item->created_at,
            'updated_at' => $item->updated_at,
        ];
    }

    private function buildSummary(WeddingPlan $plan, Collection $items): array
    {
        $totalBudget = (float) $plan->total_budget;
        $estimatedTotal = (float) $items->sum('estimated_amount');
        $actualTotal = (float) $items->sum('actual_amount');
        $paidTotal = (float) $items->where('is_paid', true)->sum('actual_amount');
        $unpaidTotal = max($actualTotal - $paidTotal, 0);
        $remaining = max($totalBudget - $actualTotal, 0);
        $overBudget = max($actualTotal - $totalBudget, 0);

        return [
            'total_budget' => $totalBudget,
            'estimated_total' => $estimatedTotal,
            'actual_total' => $actualTotal,
            'paid_total' => $paidTotal,
            'unpaid_total' => $unpaidTotal,
            'budget_remaining' => $remaining,
            'over_budget' => $overBudget,
            'estimated_percent' => $totalBudget > 0 ? round(($estimatedTotal / $totalBudget) * 100, 1) : 0,
            'spent_percent' => $totalBudget > 0 ? round(($actualTotal / $totalBudget) * 100, 1) : 0,
            'items_count' => $items->count(),
            'paid_items_count' => $items->where('is_paid', true)->count(),
        ];
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
