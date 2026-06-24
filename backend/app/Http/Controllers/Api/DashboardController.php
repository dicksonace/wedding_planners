<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\AuthorizesCouple;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    use AuthorizesCouple;

    public function index(Request $request): JsonResponse
    {
        $this->authorizeCouple($request);

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

        $plan->load([
            'budgetItems',
            'tasks' => fn ($query) => $query->where('status', '!=', 'completed')->orderBy('due_date')->limit(5),
        ]);

        $estimatedTotal = (float) $plan->budgetItems->sum('estimated_amount');
        $actualTotal = (float) $plan->budgetItems->sum('actual_amount');
        $confirmedGuests = $plan->guests()->where('rsvp_status', 'confirmed')->count();
        $invitedGuests = $plan->guests()->whereNotNull('invitation_sent_at')->count();
        $pendingVendorRequests = $plan->vendorRequests()->where('status', 'pending')->count();

        return response()->json([
            'data' => [
                'has_plan' => true,
                'plan' => $plan,
                'stats' => [
                    'guests_count' => $plan->guests_count,
                    'confirmed_guests' => $confirmedGuests,
                    'invited_guests' => $invitedGuests,
                    'tasks_count' => $plan->tasks_count,
                    'pending_tasks' => $plan->tasks()->where('status', '!=', 'completed')->count(),
                    'pending_vendor_requests' => $pendingVendorRequests,
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
