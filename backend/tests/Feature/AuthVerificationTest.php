<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\URL;
use Tests\TestCase;

class AuthVerificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_requires_email_verification_before_login(): void
    {
        Mail::fake();

        $this->postJson('/api/register', [
            'name' => 'New Couple',
            'email' => 'newcouple@test.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'couple',
        ])->assertCreated()
            ->assertJsonPath('email_verification_required', true)
            ->assertJsonMissing(['token']);

        $this->postJson('/api/login', [
            'email' => 'newcouple@test.com',
            'password' => 'password123',
        ])->assertForbidden()
            ->assertJsonPath('email_verification_required', true);
    }

    public function test_verified_user_can_login(): void
    {
        $user = User::factory()->create([
            'email' => 'verified@test.com',
            'password' => Hash::make('password123'),
            'role' => 'couple',
            'email_verified_at' => now(),
        ]);

        $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password123',
        ])->assertOk()
            ->assertJsonStructure(['token', 'user']);
    }

    public function test_email_verification_link_marks_user_verified(): void
    {
        $user = User::factory()->create([
            'email' => 'verifyme@test.com',
            'role' => 'couple',
            'email_verified_at' => null,
        ]);

        $url = URL::temporarySignedRoute(
            'verification.verify',
            now()->addHour(),
            ['id' => $user->id, 'hash' => sha1($user->getEmailForVerification())]
        );

        $this->get($url)->assertOk();

        $this->assertTrue($user->fresh()->hasVerifiedEmail());
    }

    public function test_resend_verification_email_endpoint(): void
    {
        Mail::fake();

        User::factory()->create([
            'email' => 'resend@test.com',
            'role' => 'couple',
            'email_verified_at' => null,
        ]);

        $this->postJson('/api/email/resend', [
            'email' => 'resend@test.com',
        ])->assertOk();
    }
}
