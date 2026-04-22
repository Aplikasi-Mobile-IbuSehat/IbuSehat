<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\GeminiController;
use App\Http\Controllers\FoodController;
use App\Http\Controllers\FoodLogController;
use App\Http\Controllers\SupplementController;
use App\Http\Controllers\SupplementLogController;

Route::get('/test', function () {
    return "OK";
});

// Auth routes
Route::post('/auth/google', [AuthController::class, 'googleLogin']);

Route::post('/gemini/chat', [GeminiController::class, 'ask']);

// Public search routes
Route::prefix('foods')->group(function () {
    Route::get('/',           [FoodController::class, 'index']);
    Route::get('/categories', [FoodController::class, 'categories']);
    Route::get('/{id}',       [FoodController::class, 'show']);
});

Route::prefix('supplements')->group(function () {
    Route::get('/',          [SupplementController::class, 'index']);
    Route::get('/sources',   [SupplementController::class, 'sources']);
    Route::get('/{id}',      [SupplementController::class, 'show']);
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn(Request $r) => $r->user());
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/user/onboarding', [AuthController::class, 'updateOnboarding']);

    // Food logging
    Route::prefix('food-logs')->group(function () {
        Route::get('/',           [FoodLogController::class, 'index']);
        Route::post('/',          [FoodLogController::class, 'store']);
        Route::put('/{id}',       [FoodLogController::class, 'update']);
        Route::patch('/{id}',     [FoodLogController::class, 'update']);
        Route::delete('/{id}',    [FoodLogController::class, 'destroy']);
    });

    // Supplement logging
    Route::prefix('supplement-logs')->group(function () {
        Route::get('/',           [SupplementLogController::class, 'index']);
        Route::post('/',          [SupplementLogController::class, 'store']);
        Route::put('/{id}',       [SupplementLogController::class, 'update']);
        Route::patch('/{id}',     [SupplementLogController::class, 'update']);
        Route::delete('/{id}',    [SupplementLogController::class, 'destroy']);
    });

    // Admin/Manage routes (Optional, keeping them if they were there before)
    Route::prefix('foods')->group(function () {
        Route::post('/',          [FoodController::class, 'store']);
        Route::put('/{id}',       [FoodController::class, 'update']);
        Route::delete('/{id}',    [FoodController::class, 'destroy']);
    });
    
    Route::prefix('supplements')->group(function () {
        Route::post('/',         [SupplementController::class, 'store']);
        Route::put('/{id}',      [SupplementController::class, 'update']);
        Route::delete('/{id}',   [SupplementController::class, 'destroy']);
    });
});
