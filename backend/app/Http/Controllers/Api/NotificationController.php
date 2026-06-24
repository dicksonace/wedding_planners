<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()
            ->notifications()
            ->latest()
            ->limit(50)
            ->get();

        return response()->json(['data' => $notifications]);
    }

    public function markAsRead(Request $request, AppNotification $notification): JsonResponse
    {
        abort_if($notification->user_id !== $request->user()->id, 403, 'Unauthorized.');

        $notification->update(['read_at' => now()]);

        return response()->json([
            'message' => 'Notification marked as read.',
            'data' => $notification->fresh(),
        ]);
    }
}
