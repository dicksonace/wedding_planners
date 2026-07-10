<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class VendorSearchTest extends TestCase
{
    use RefreshDatabase;

    public function test_vendor_search_by_business_name(): void
    {
        $this->seedVendor('Golden Events Ghana', 'Decoration', 'Accra');
        $this->seedVendor('Royal Caterers', 'Catering', 'Kumasi');

        $this->getJson('/api/vendors?search=Golden')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.business_name', 'Golden Events Ghana');
    }

    public function test_vendor_search_by_category_filter(): void
    {
        $this->seedVendor('Photo Pro GH', 'Photography', 'Accra');
        $this->seedVendor('Sweet Cakes GH', 'Cake', 'Accra');

        $this->getJson('/api/vendors?category=Photography')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.category', 'Photography');
    }

    public function test_vendor_search_by_location(): void
    {
        $this->seedVendor('Accra Decor', 'Decoration', 'Accra');
        $this->seedVendor('Northern Lights', 'Decoration', 'Tamale');

        $this->getJson('/api/vendors?search=Tamale')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.location', 'Tamale');
    }

    private function seedVendor(string $businessName, string $category, string $location): Vendor
    {
        $user = User::factory()->create([
            'role' => 'vendor',
            'email_verified_at' => now(),
        ]);

        return Vendor::create([
            'user_id' => $user->id,
            'business_name' => $businessName,
            'category' => $category,
            'description' => "Services by {$businessName}",
            'location' => $location,
            'phone' => '0244000000',
            'is_verified' => true,
        ]);
    }
}
