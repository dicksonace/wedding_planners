<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Concerns\AuthorizesCouple;
use App\Models\PlanningTask;
use App\Models\WeddingPlan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlanningTaskController extends Controller
{
    use AuthorizesCouple;

    public function index(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        return response()->json(['data' => $weddingPlan->tasks()->orderBy('due_date')->get()]);
    }

    public function store(Request $request, WeddingPlan $weddingPlan): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'due_date' => ['nullable', 'date'],
            'status' => ['nullable', 'in:pending,in_progress,completed'],
            'priority' => ['nullable', 'in:low,medium,high'],
            'ceremony_type' => ['nullable', 'string', 'max:100'],
        ]);

        $task = $weddingPlan->tasks()->create($validated);

        return response()->json([
            'message' => 'Task created successfully.',
            'data' => $task,
        ], 201);
    }

    public function update(Request $request, WeddingPlan $weddingPlan, PlanningTask $task): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeTask($weddingPlan, $task);

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'due_date' => ['nullable', 'date'],
            'status' => ['nullable', 'in:pending,in_progress,completed'],
            'priority' => ['nullable', 'in:low,medium,high'],
            'ceremony_type' => ['nullable', 'string', 'max:100'],
        ]);

        $task->update($validated);

        return response()->json([
            'message' => 'Task updated successfully.',
            'data' => $task->fresh(),
        ]);
    }

    public function destroy(Request $request, WeddingPlan $weddingPlan, PlanningTask $task): JsonResponse
    {
        $this->authorizeCouple($request);
        $this->authorizePlan($request, $weddingPlan);
        $this->authorizeTask($weddingPlan, $task);
        $task->delete();

        return response()->json(['message' => 'Task deleted successfully.']);
    }

    private function authorizePlan(Request $request, WeddingPlan $weddingPlan): void
    {
        abort_if($weddingPlan->user_id !== $request->user()->id, 403, 'Unauthorized.');
    }

    private function authorizeTask(WeddingPlan $weddingPlan, PlanningTask $task): void
    {
        abort_if($task->wedding_plan_id !== $weddingPlan->id, 404, 'Task not found.');
    }
}
