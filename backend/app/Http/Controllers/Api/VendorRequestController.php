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

        $requests = $weddingPlan->vendorRequests()->with('vendor.user')->latest()->get();

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
            'data' => $vendorRequest->load('vendor.user'),
        ], 201);
    }

    public function respond(Request $request, VendorRequest $vendorRequest): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->isVendor(), 403, 'Only vendors can respond.');
        abort_unless($user->vendor?->id === $vendorRequest->vendor_id, 403, 'Unauthorized.');

        $validated = $request->validate([
            'status' => ['required', 'in:accepted,declined'],
            'response_message' => ['nullable', 'string'],
        ]);

        $vendorRequest->update($validated);

        AppNotification::create([
            'user_id' => $vendorRequest->couple_id,
            'wedding_plan_id' => $vendorRequest->wedding_plan_id,
            'title' => 'Vendor responded to your request',
            'message' => "Your request was {$validated['status']}.",
            'type' => 'vendor_response',
        ]);

        return response()->json([
            'message' => 'Response submitted successfully.',
            'data' => $vendorRequest->fresh()->load(['vendor.user', 'weddingPlan', 'couple']),
        ]);
    }

    private function authorizePlan(Request $request, WeddingPlan $weddingPlan): void
    {
        abort_if($weddingPlan->user_id !== $request->user()->id, 403, 'Unauthorized.');
    }
}
