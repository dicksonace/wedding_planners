<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Auth\Events\Verified;
use Illuminate\Http\Request;
use Illuminate\View\View;

class EmailVerificationWebController extends Controller
{
    public function verify(Request $request, int $id, string $hash): View
    {
        if (! $request->hasValidSignature()) {
            abort(403, 'This verification link is invalid or has expired.');
        }

        $user = User::findOrFail($id);

        if (! hash_equals($hash, sha1($user->getEmailForVerification()))) {
            abort(403, 'This verification link is invalid.');
        }

        if (! $user->hasVerifiedEmail()) {
            $user->markEmailAsVerified();
            event(new Verified($user));
        }

        return view('auth.email-verified', [
            'email' => $user->email,
        ]);
    }
}
