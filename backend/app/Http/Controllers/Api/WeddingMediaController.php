<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\AuthorizesCouple;
use App\Models\WeddingMedia;
use App\Models\WeddingPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class WeddingMediaController extends Controller
{
    use AuthorizesCouple;

    public function index(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $query = $weddingPlan->media()->latest();

        if ($request->filled('type')) {
            $query->where('type', $request->string('type'));
        }

        return response()->json(['data' => $query->get()]);
    }

    public function store(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $validated = $request->validate([
            'type' => ['required', 'in:invitation,wedding_photo'],
            'title' => ['nullable', 'string', 'max:255'],
            'file' => ['required', 'file', 'mimes:jpg,jpeg,png,webp,gif', 'max:10240'],
        ]);

        $file = $request->file('file');
        $path = $file->store("wedding-plans/{$weddingPlan->id}/media", 'public');

        $media = $weddingPlan->media()->create([
            'user_id' => $request->user()->id,
            'type' => $validated['type'],
            'title' => $validated['title'] ?? null,
            'file_path' => $path,
            'mime_type' => $file->getMimeType(),
            'file_size' => $file->getSize(),
        ]);

        return response()->json([
            'message' => 'Image uploaded successfully.',
            'data' => $media,
        ], 201);
    }

    public function destroy(Request $request, WeddingPlan $weddingPlan, WeddingMedia $medium): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeMedia($weddingPlan, $medium);

        Storage::disk('public')->delete($medium->file_path);
        $medium->delete();

        return response()->json(['message' => 'Image deleted successfully.']);
    }

    private function authorizePlan(Request $request, WeddingPlan $weddingPlan): void
    {
        abort_if($weddingPlan->user_id !== $request->user()->id, 403, 'Unauthorized.');
    }

    private function authorizeMedia(WeddingPlan $weddingPlan, WeddingMedia $medium): void
    {
        abort_if($medium->wedding_plan_id !== $weddingPlan->id, 404, 'Media not found.');
    }
}
