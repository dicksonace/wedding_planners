<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\AuthorizesCouple;
use App\Models\AppNotification;
use App\Models\Vendor;
use App\Models\VendorRequest;
use App\Models\WeddingPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VendorRequestController extends Controller
{
    use AuthorizesCouple;

    public function index(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $requests = $weddingPlan->vendorRequests()
            ->with(['vendor.user', 'vendor.services', 'budgetItem'])
            ->latest()
            ->get();

        return response()->json(['data' => $requests]);
    }

    public function store(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $validated = $request->validate([
            'vendor_id' => ['required', 'exists:vendors,id'],
            'message' => ['nullable', 'string'],
        ]);

        $hasPending = VendorRequest::query()
            ->where('wedding_plan_id', $weddingPlan->id)
            ->where('vendor_id', $validated['vendor_id'])
            ->where('status', 'pending')
            ->exists();

        abort_if($hasPending, 422, 'You already have a pending request with this vendor. Cancel it first to send a new one.');

        $vendorRequest = VendorRequest::create([
            'wedding_plan_id' => $weddingPlan->id,
            'vendor_id' => $validated['vendor_id'],
            'couple_id' => $request->user()->id,
            'message' => $validated['message'] ?? null,
            'status' => 'pending',
        ]);

        $vendor = Vendor::with('user')->findOrFail($validated['vendor_id']);

        if ($vendor->user) {
            AppNotification::create([
                'user_id' => $vendor->user->id,
                'wedding_plan_id' => $weddingPlan->id,
                'title' => 'New vendor request',
                'message' => "{$request->user()->name} sent a planning request for {$weddingPlan->title}.",
                'type' => 'vendor_request',
            ]);
        }

        return response()->json([
            'message' => 'Vendor request sent successfully.',
            'data' => $vendorRequest->load(['vendor.user', 'vendor.services']),
        ], 201);
    }

    public function cancel(Request $request, WeddingPlan $weddingPlan, VendorRequest $vendorRequest): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeRequest($weddingPlan, $vendorRequest);

        abort_unless($vendorRequest->status === 'pending', 422, 'Only pending requests can be cancelled.');

        $vendorRequest->update(['status' => 'cancelled']);

        return response()->json([
            'message' => 'Vendor request cancelled.',
            'data' => $vendorRequest->fresh()->load(['vendor.user', 'budgetItem']),
        ]);
    }

    public function respond(Request $request, VendorRequest $vendorRequest): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->isVendor(), 403, 'Only vendors can respond.');
        abort_unless($user->vendor?->id === $vendorRequest->vendor_id, 403, 'Unauthorized.');
        abort_unless($vendorRequest->status === 'pending', 422, 'This request has already been handled.');

        $validated = $request->validate([
            'status' => ['required', 'in:accepted,declined'],
            'response_message' => ['nullable', 'string'],
            'quoted_amount' => ['nullable', 'numeric', 'min:0'],
        ]);

        $updates = [
            'status' => $validated['status'],
            'response_message' => $validated['response_message'] ?? null,
        ];

        if ($validated['status'] === 'accepted') {
            $vendor = $vendorRequest->vendor()->with('services')->first();
            $service = $vendor?->services->first();
            $quoted = $validated['quoted_amount'] ?? $service?->price_from ?? 0;

            $budgetItem = $vendorRequest->weddingPlan->budgetItems()->create([
                'category' => $vendor->category,
                'description' => trim("{$vendor->business_name} — ".($service?->title ?? 'Vendor booking')),
                'estimated_amount' => $quoted,
                'actual_amount' => 0,
                'is_paid' => false,
            ]);

            $updates['budget_item_id'] = $budgetItem->id;
            $updates['quoted_amount'] = $quoted;
        }

        $vendorRequest->update($updates);

        AppNotification::create([
            'user_id' => $vendorRequest->couple_id,
            'wedding_plan_id' => $vendorRequest->wedding_plan_id,
            'title' => $validated['status'] === 'accepted' ? 'Vendor accepted your request' : 'Vendor declined your request',
            'message' => $validated['status'] === 'accepted'
                ? 'The vendor was added to your budget as an expense.'
                : 'Your vendor request was declined.',
            'type' => 'vendor_response',
        ]);

        return response()->json([
            'message' => 'Response submitted successfully.',
            'data' => $vendorRequest->fresh()->load(['vendor.user', 'weddingPlan', 'couple', 'budgetItem']),
        ]);
    }

    private function authorizePlan(Request $request, WeddingPlan $weddingPlan): void
    {
        abort_if($weddingPlan->user_id !== $request->user()->id, 403, 'Unauthorized.');
    }

    private function authorizeRequest(WeddingPlan $weddingPlan, VendorRequest $vendorRequest): void
    {
        abort_if($vendorRequest->wedding_plan_id !== $weddingPlan->id, 404, 'Request not found.');
        abort_if($vendorRequest->couple_id !== auth()->id(), 403, 'Unauthorized.');
    }
}
