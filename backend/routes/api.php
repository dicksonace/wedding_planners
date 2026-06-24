<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BudgetItemController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\GuestController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PlanningTaskController;
use App\Http\Controllers\Api\VendorController;
use App\Http\Controllers\Api\VendorRequestController;
use App\Http\Controllers\Api\WeddingPlanController;
use Illuminate\Support\Facades\Route;

Route::get('/health', fn () => response()->json([
    'status' => 'ok',
    'app' => 'WedPlan Ghana API',
    'version' => '1.0.0',
]));

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/vendors', [VendorController::class, 'index']);
Route::get('/vendors/categories', [VendorController::class, 'categories']);
Route::get('/vendors/{vendor}', [VendorController::class, 'show']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::get('/dashboard', [DashboardController::class, 'index']);

    Route::apiResource('wedding-plans', WeddingPlanController::class);

    Route::get('wedding-plans/{weddingPlan}/guests', [GuestController::class, 'index']);
    Route::post('wedding-plans/{weddingPlan}/guests', [GuestController::class, 'store']);
    Route::put('wedding-plans/{weddingPlan}/guests/{guest}', [GuestController::class, 'update']);
    Route::delete('wedding-plans/{weddingPlan}/guests/{guest}', [GuestController::class, 'destroy']);

    Route::get('wedding-plans/{weddingPlan}/budget-items', [BudgetItemController::class, 'index']);
    Route::post('wedding-plans/{weddingPlan}/budget-items', [BudgetItemController::class, 'store']);
    Route::put('wedding-plans/{weddingPlan}/budget-items/{budgetItem}', [BudgetItemController::class, 'update']);
    Route::delete('wedding-plans/{weddingPlan}/budget-items/{budgetItem}', [BudgetItemController::class, 'destroy']);

    Route::get('wedding-plans/{weddingPlan}/tasks', [PlanningTaskController::class, 'index']);
    Route::post('wedding-plans/{weddingPlan}/tasks', [PlanningTaskController::class, 'store']);
    Route::put('wedding-plans/{weddingPlan}/tasks/{task}', [PlanningTaskController::class, 'update']);
    Route::delete('wedding-plans/{weddingPlan}/tasks/{task}', [PlanningTaskController::class, 'destroy']);

    Route::get('wedding-plans/{weddingPlan}/vendor-requests', [VendorRequestController::class, 'index']);
    Route::post('wedding-plans/{weddingPlan}/vendor-requests', [VendorRequestController::class, 'store']);
    Route::patch('vendor-requests/{vendorRequest}/respond', [VendorRequestController::class, 'respond']);

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markAsRead']);
});
