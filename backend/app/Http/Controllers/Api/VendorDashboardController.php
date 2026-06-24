<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VendorRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VendorDashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->isVendor(), 403, 'Vendors only.');

        $vendor = $user->vendor;
        abort_if(! $vendor, 404, 'Vendor profile not found.');

        $requests = VendorRequest::with(['weddingPlan', 'couple'])
            ->where('vendor_id', $vendor->id)
            ->latest()
            ->get();

        $pending = $requests->where('status', 'pending')->values();
        $accepted = $requests->where('status', 'accepted')->values();

        return response()->json([
            'data' => [
                'vendor' => $vendor->load('services'),
                'stats' => [
                    'total_requests' => $requests->count(),
                    'pending_requests' => $pending->count(),
                    'accepted_requests' => $accepted->count(),
                    'declined_requests' => $requests->where('status', 'declined')->count(),
                ],
                'pending_requests' => $pending,
                'recent_requests' => $requests->take(10),
                'recent_notifications' => $user->notifications()->latest()->limit(5)->get(),
            ],
        ]);
    }
}
