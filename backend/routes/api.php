<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\GeminiController;
use App\Http\Controllers\FoodController;
use App\Http\Controllers\FoodLogController;
use App\Http\Controllers\SupplementController;
use App\Http\Controllers\SupplementLogController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\FcmTokenController;
use App\Http\Controllers\SleepController;
use App\Http\Controllers\SleepLogController;
use App\Http\Controllers\ActivityController;
use App\Http\Controllers\WorkoutProgramController;

Route::get('/test', function () {
    return "OK";
});

// Auth routes
Route::post('/auth/google', [AuthController::class, 'googleLogin']);

// Payment routes
Route::post('/payment/notification', [PaymentController::class, 'handleNotification']);

// Workout programs
Route::get('/workout-programs', [WorkoutProgramController::class, 'index']);
Route::get('/workout-programs/{id}', [WorkoutProgramController::class, 'show']);

// Public search routes
Route::prefix('foods')->group(function () {
    Route::get('/', [FoodController::class, 'index']);
    Route::get('/categories', [FoodController::class, 'categories']);
    Route::get('/{id}', [FoodController::class, 'show']);
});

Route::prefix('supplements')->group(function () {
    Route::get('/', [SupplementController::class, 'index']);
    Route::get('/sources', [SupplementController::class, 'sources']);
    Route::get('/{id}', [SupplementController::class, 'show']);
});

// Protected routes
Route::middleware('auth:sanctum')->group(function () {

    Route::get('/user', [AuthController::class, 'getUser']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/user/onboarding', [AuthController::class, 'updateOnboarding']);

    // Water Intake
    Route::get('/user/water-intake', [AuthController::class, 'getWaterIntake']);
    Route::post('/user/water-intake/add', [AuthController::class, 'updateWaterIntake']);
    Route::post('/user/water-intake/reduce', [AuthController::class, 'reduceWaterIntake']);

    // FCM
    Route::post('/fcm-token', [FcmTokenController::class, 'store']);

    // Gemini Premium Only
    Route::middleware(['throttle:chat', 'premium.chat-quota'])->group(function () {
        Route::post('/gemini/chat', [GeminiController::class, 'ask']);
    });

    // Payment
    Route::post('/payment/create', [PaymentController::class, 'createTransaction']);

    // Activities
    Route::get('/activities/summary', [ActivityController::class, 'summary']);
    Route::get('/activities', [ActivityController::class, 'index']);
    Route::post('/activities', [ActivityController::class, 'store']);
    Route::get('/activities/{activity}', [ActivityController::class, 'show']);

    // Sleep Dashboard
    Route::get('/sleep/dashboard', [SleepController::class, 'dashboard']);

    // Sleep Logs
    Route::get('/sleep/log/latest', [SleepLogController::class, 'latest']);
    Route::get('/sleep/log/today', [SleepLogController::class, 'today']);
    Route::get('/sleep/log/history', [SleepLogController::class, 'history']);

    Route::get('/sleep/log/detail/{id}', [SleepLogController::class, 'show'])
        ->whereNumber('id');

    Route::get('/sleep/log/{id}', [SleepLogController::class, 'show'])
        ->whereNumber('id');

    Route::get('/sleep/log/weekly-summary', [SleepLogController::class, 'weeklySummary']);

    Route::post('/sleep/log', [SleepLogController::class, 'store']);
    Route::post('/sleep/log/save', [SleepLogController::class, 'save']);

    Route::delete('/sleep/log/{id}', [SleepLogController::class, 'destroy'])
        ->whereNumber('id');

    // Food logging
    Route::prefix('food-logs')->group(function () {
        Route::get('/', [FoodLogController::class, 'index']);
        Route::post('/', [FoodLogController::class, 'store']);
        Route::put('/{id}', [FoodLogController::class, 'update']);
        Route::patch('/{id}', [FoodLogController::class, 'update']);
        Route::delete('/{id}', [FoodLogController::class, 'destroy']);
    });

    // Supplement logging
    Route::prefix('supplement-logs')->group(function () {
        Route::get('/', [SupplementLogController::class, 'index']);
        Route::post('/', [SupplementLogController::class, 'store']);
        Route::put('/{id}', [SupplementLogController::class, 'update']);
        Route::patch('/{id}', [SupplementLogController::class, 'update']);
        Route::delete('/{id}', [SupplementLogController::class, 'destroy']);
    });

    // Food Management
    Route::prefix('foods')->group(function () {
        Route::post('/', [FoodController::class, 'store']);
        Route::put('/{id}', [FoodController::class, 'update']);
        Route::delete('/{id}', [FoodController::class, 'destroy']);
    });

    // Supplement Management
    Route::prefix('supplements')->group(function () {
        Route::post('/', [SupplementController::class, 'store']);
        Route::put('/{id}', [SupplementController::class, 'update']);
        Route::delete('/{id}', [SupplementController::class, 'destroy']);
    });
});