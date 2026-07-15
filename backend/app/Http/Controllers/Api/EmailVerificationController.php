<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Throwable;

class EmailVerificationController extends Controller
{
    public function resend(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email:rfc,dns'],
        ]);

        $key = 'verify-email:'.$validated['email'];

        if (RateLimiter::tooManyAttempts($key, 3)) {
            return response()->json([
                'message' => 'Too many verification emails sent. Please try again later.',
            ], 429);
        }

        RateLimiter::hit($key, 300);

        $user = User::where('email', $validated['email'])->first();

        if ($user && ! $user->hasVerifiedEmail()) {
            try {
                $user->sendEmailVerificationNotification();
            } catch (Throwable $e) {
                Log::error('Failed to resend verification email.', [
                    'user_id' => $user->id,
                    'email' => $user->email,
                    'error' => $e->getMessage(),
                ]);

                return response()->json([
                    'message' => 'Unable to send confirmation email right now. Please try again shortly.',
                ], 503);
            }
        }

        return response()->json([
            'message' => 'If your account exists and is unverified, a confirmation email has been sent.',
        ]);
    }
}
