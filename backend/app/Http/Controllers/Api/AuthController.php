<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::defaults()],
            'role' => ['required', 'in:couple,vendor'],
            'phone' => ['nullable', 'string', 'max:20'],
            'partner_name' => ['nullable', 'string', 'max:255'],
            'region' => ['nullable', 'string', 'max:255'],
            'business_name' => ['required_if:role,vendor', 'string', 'max:255'],
            'category' => ['required_if:role,vendor', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'location' => ['nullable', 'string', 'max:255'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'],
            'phone' => $validated['phone'] ?? null,
            'partner_name' => $validated['partner_name'] ?? null,
            'region' => $validated['region'] ?? null,
        ]);

        if ($user->isVendor()) {
            Vendor::create([
                'user_id' => $user->id,
                'business_name' => $validated['business_name'],
                'category' => $validated['category'],
                'description' => $validated['description'] ?? null,
                'location' => $validated['location'] ?? null,
                'phone' => $validated['phone'] ?? null,
                'is_verified' => true,
            ]);
        }

        $user->sendEmailVerificationNotification();

        return response()->json([
            'message' => 'Registration successful. Please check your email to verify your account before signing in.',
            'email_verification_required' => true,
            'email' => $user->email,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt($credentials)) {
            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        /** @var User $user */
        $user = Auth::user();

        if (! $user->hasVerifiedEmail()) {
            Auth::logout();

            return response()->json([
                'message' => 'Please verify your email before signing in. Check your inbox for the confirmation link.',
                'email_verification_required' => true,
                'email' => $user->email,
            ], 403);
        }

        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'message' => 'Login successful.',
            'user' => $this->formatUser($user->load('vendor')),
            'token' => $token,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out successfully.']);
    }

    public function profile(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $this->formatUser($request->user()->load('vendor')),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:20'],
            'partner_name' => ['nullable', 'string', 'max:255'],
            'region' => ['nullable', 'string', 'max:255'],
        ]);

        $user->update($validated);

        return response()->json([
            'message' => 'Profile updated successfully.',
            'user' => $this->formatUser($user->fresh()->load('vendor')),
        ]);
    }

    private function formatUser(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'phone' => $user->phone,
            'partner_name' => $user->partner_name,
            'region' => $user->region,
            'email_verified' => $user->hasVerifiedEmail(),
            'vendor' => $user->vendor,
        ];
    }
}
