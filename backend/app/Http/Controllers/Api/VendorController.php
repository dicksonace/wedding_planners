<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vendor;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VendorController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Vendor::query()->with(['user', 'services'])->where('is_verified', true);

        if ($request->filled('category')) {
            $query->where('category', $request->string('category'));
        }

        if ($request->filled('location')) {
            $query->where('location', 'like', '%'.$request->string('location').'%');
        }

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($builder) use ($search) {
                $builder->where('business_name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%")
                    ->orWhere('location', 'like', "%{$search}%");
            });
        }

        return response()->json(['data' => $query->latest()->get()]);
    }

    public function show(Vendor $vendor): JsonResponse
    {
        $vendor->load(['user', 'services']);

        return response()->json(['data' => $vendor]);
    }

    public function categories(): JsonResponse
    {
        $categories = [
            [
                'name' => 'Catering',
                'slug' => 'catering',
                'icon' => 'restaurant',
                'image_url' => 'https://images.unsplash.com/photo-1555244162-803834f70033?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Photography',
                'slug' => 'photography',
                'icon' => 'camera',
                'image_url' => 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Videography',
                'slug' => 'videography',
                'icon' => 'videocam',
                'image_url' => 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Decoration',
                'slug' => 'decoration',
                'icon' => 'celebration',
                'image_url' => 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Bridal Wear',
                'slug' => 'bridal-wear',
                'icon' => 'checkroom',
                'image_url' => 'https://images.unsplash.com/photo-1594552072238-b8a33785b261?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Groom Wear',
                'slug' => 'groom-wear',
                'icon' => 'dry_cleaning',
                'image_url' => 'https://images.unsplash.com/photo-1507679799987-4e924cc0f0f1?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Traditional Wear',
                'slug' => 'traditional-wear',
                'icon' => 'style',
                'image_url' => 'https://images.unsplash.com/photo-1583939003579-730e3918a45a?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Makeup & Beauty',
                'slug' => 'makeup-beauty',
                'icon' => 'face',
                'image_url' => 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'MC / Host',
                'slug' => 'mc-host',
                'icon' => 'mic',
                'image_url' => 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'DJ / Music',
                'slug' => 'dj-music',
                'icon' => 'music_note',
                'image_url' => 'https://images.unsplash.com/photo-1571330735066-03aaa9429d89?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Venue',
                'slug' => 'venue',
                'icon' => 'location_city',
                'image_url' => 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Cake',
                'slug' => 'cake',
                'icon' => 'cake',
                'image_url' => 'https://images.unsplash.com/photo-1535254973040-607b474cb50d?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Transport',
                'slug' => 'transport',
                'icon' => 'directions_car',
                'image_url' => 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?auto=format&fit=crop&w=600&q=80',
            ],
            [
                'name' => 'Printing & Invitations',
                'slug' => 'printing-invitations',
                'icon' => 'mail',
                'image_url' => 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?auto=format&fit=crop&w=600&q=80',
            ],
        ];

        return response()->json(['data' => $categories]);
    }
}
