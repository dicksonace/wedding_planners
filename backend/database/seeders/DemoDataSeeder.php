<?php

namespace Database\Seeders;

use App\Models\AppNotification;
use App\Models\BudgetItem;
use App\Models\Guest;
use App\Models\PlanningTask;
use App\Models\User;
use App\Models\Vendor;
use App\Models\VendorRequest;
use App\Models\VendorService;
use App\Models\WeddingPlan;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $couple = User::updateOrCreate(
            ['email' => 'couple@wedplan.test'],
            [
                'name' => 'Ernestina & Partner',
                'password' => Hash::make('password'),
                'role' => 'couple',
                'phone' => '0244123456',
                'partner_name' => 'Kwame Mensah',
                'region' => 'Greater Accra',
            ]
        );

        $vendorUser = User::updateOrCreate(
            ['email' => 'vendor@wedplan.test'],
            [
                'name' => 'Golden Events GH',
                'password' => Hash::make('password'),
                'role' => 'vendor',
                'phone' => '0209876543',
                'region' => 'Greater Accra',
            ]
        );

        $vendor = Vendor::updateOrCreate(
            ['user_id' => $vendorUser->id],
            [
                'business_name' => 'Golden Events Ghana',
                'category' => 'Decoration',
                'description' => 'Premium wedding decoration with traditional and modern themes.',
                'location' => 'Accra',
                'phone' => '0209876543',
                'is_verified' => true,
            ]
        );

        VendorService::updateOrCreate(
            ['vendor_id' => $vendor->id, 'title' => 'Full Venue Decoration'],
            [
                'category' => 'Decoration',
                'description' => 'Complete venue styling for traditional and white wedding.',
                'price_from' => 8000,
                'price_to' => 25000,
                'is_active' => true,
            ]
        );

        $plan = WeddingPlan::updateOrCreate(
            ['user_id' => $couple->id, 'title' => 'Our Accra Wedding 2026'],
            [
                'bride_name' => 'Ernestina Blankson',
                'groom_name' => 'Kwame Mensah',
                'wedding_date' => '2026-08-15',
                'location' => 'Accra Conference Centre',
                'region' => 'Greater Accra',
                'total_budget' => 50000,
                'ceremony_types' => ['knocking', 'engagement', 'traditional', 'church', 'reception'],
                'status' => 'planning',
                'notes' => 'Include family introductions and dowry coordination.',
            ]
        );

        Guest::updateOrCreate(
            ['wedding_plan_id' => $plan->id, 'name' => 'Akosua Panford'],
            ['phone' => '0244000111', 'side' => 'bride', 'rsvp_status' => 'confirmed', 'plus_one' => true]
        );

        Guest::updateOrCreate(
            ['wedding_plan_id' => $plan->id, 'name' => 'Yaw Appiah'],
            ['phone' => '0244000222', 'side' => 'groom', 'rsvp_status' => 'pending', 'plus_one' => false]
        );

        BudgetItem::updateOrCreate(
            ['wedding_plan_id' => $plan->id, 'description' => 'Venue booking deposit'],
            ['category' => 'Venue', 'estimated_amount' => 12000, 'actual_amount' => 5000, 'is_paid' => true]
        );

        BudgetItem::updateOrCreate(
            ['wedding_plan_id' => $plan->id, 'description' => 'Photography package'],
            ['category' => 'Photography', 'estimated_amount' => 6000, 'actual_amount' => 0, 'is_paid' => false]
        );

        PlanningTask::updateOrCreate(
            ['wedding_plan_id' => $plan->id, 'title' => 'Knocking ceremony preparation'],
            ['description' => 'Prepare drinks, gifts, and family list.', 'due_date' => '2026-06-20', 'status' => 'in_progress', 'priority' => 'high', 'ceremony_type' => 'knocking']
        );

        PlanningTask::updateOrCreate(
            ['wedding_plan_id' => $plan->id, 'title' => 'Send invitations'],
            ['description' => 'Print and distribute wedding invitations.', 'due_date' => '2026-07-01', 'status' => 'pending', 'priority' => 'medium', 'ceremony_type' => 'reception']
        );

        AppNotification::updateOrCreate(
            ['user_id' => $couple->id, 'title' => 'Welcome to WedPlan Ghana'],
            [
                'wedding_plan_id' => $plan->id,
                'message' => 'Start planning your wedding journey with culturally relevant tools.',
                'type' => 'info',
            ]
        );

        VendorRequest::updateOrCreate(
            [
                'wedding_plan_id' => $plan->id,
                'vendor_id' => $vendor->id,
                'couple_id' => $couple->id,
            ],
            [
                'message' => 'We would like decoration services for our traditional and reception ceremonies.',
                'status' => 'pending',
            ]
        );
    }
}
