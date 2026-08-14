<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WeddingPlanTest extends TestCase
{
    use RefreshDatabase;

    public function test_couple_can_create_a_plan_with_an_empty_budget(): void
    {
        $user = User::factory()->create(['role' => 'couple']);
        Sanctum::actingAs($user);

        $this->postJson('/api/wedding-plans', [
            'title' => 'Kumasi Wedding',
            'wedding_date' => '2027-05-20',
            'location' => 'Kumasi',
            'region' => 'Ashanti Region',
            'total_budget' => null,
            'ceremony_types' => ['engagement'],
        ])
            ->assertCreated()
            ->assertJsonPath('data.title', 'Kumasi Wedding')
            ->assertJsonPath('data.location', 'Kumasi')
            ->assertJsonPath('data.ceremony_types', ['engagement']);

        $this->assertDatabaseHas('wedding_plans', [
            'user_id' => $user->id,
            'title' => 'Kumasi Wedding',
            'total_budget' => 0,
        ]);
    }

    public function test_dashboard_loads_after_creating_a_plan(): void
    {
        $user = User::factory()->create(['role' => 'couple']);
        Sanctum::actingAs($user);

        $this->postJson('/api/wedding-plans', [
            'title' => 'Kumasi Wedding',
            'location' => 'Kumasi',
            'ceremony_types' => ['engagement'],
        ])->assertCreated();

        $this->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('data.has_plan', true)
            ->assertJsonPath('data.stats.total_budget', 0);
    }
}
