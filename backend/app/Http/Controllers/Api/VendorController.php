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
        return response()->json([
            'data' => [
                'Catering',
                'Photography',
                'Videography',
                'Decoration',
                'MC / Host',
                'DJ / Music',
                'Makeup & Beauty',
                'Traditional Wear',
                'Venue',
                'Cake',
                'Transport',
                'Printing & Invitations',
            ],
        ]);
    }
}
