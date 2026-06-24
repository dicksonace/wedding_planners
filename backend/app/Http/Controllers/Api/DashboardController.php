<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $plan = $user->weddingPlans()->withCount(['guests', 'tasks', 'budgetItems'])->latest()->first();

        if (! $plan) {
            return response()->json([
                'data' => [
                    'has_plan' => false,
                    'stats' => null,
                    'upcoming_tasks' => [],
                    'recent_notifications' => $user->notifications()->latest()->limit(5)->get(),
                ],
            ]);
        }

        $plan->load(['budgetItems', 'tasks' => fn ($query) => $query->where('status', '!=', 'completed')->orderBy('due_date')->limit(5)]);

        $estimatedTotal = (float) $plan->budgetItems->sum('estimated_amount');
        $actualTotal = (float) $plan->budgetItems->sum('actual_amount');
        $confirmedGuests = $plan->guests()->where('rsvp_status', 'confirmed')->count();

        return response()->json([
            'data' => [
                'has_plan' => true,
                'plan' => $plan,
                'stats' => [
                    'guests_count' => $plan->guests_count,
                    'confirmed_guests' => $confirmedGuests,
                    'tasks_count' => $plan->tasks_count,
                    'pending_tasks' => $plan->tasks()->where('status', '!=', 'completed')->count(),
                    'total_budget' => (float) $plan->total_budget,
                    'estimated_spent' => $estimatedTotal,
                    'actual_spent' => $actualTotal,
                    'budget_remaining' => max((float) $plan->total_budget - $actualTotal, 0),
                ],
                'upcoming_tasks' => $plan->tasks,
                'recent_notifications' => $user->notifications()->latest()->limit(5)->get(),
            ],
        ]);
    }
}
