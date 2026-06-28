<?php

use App\Http\Controllers\ActivityController;
use App\Http\Controllers\GeminiController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\SubscriptionController;
use App\Http\Controllers\WaterIntakeController;
use App\Http\Controllers\WorkoutProgramController;
use App\Http\Controllers\StreakController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\FoodController;
use App\Http\Controllers\FoodLogController;
use App\Http\Controllers\SleepController;
use App\Http\Controllers\SleepLogController;
use App\Http\Controllers\SupplementController;
use App\Http\Controllers\SupplementLogController;
use App\Http\Controllers\ProgressController;

// ─────────────────────────────────────────────
// Sanity-check route
// ─────────────────────────────────────────────
Route::get('/test', function () {
    return response()->json(['status' => 'OK']);
});

// ─────────────────────────────────────────────
// Auth routes (public)
// ─────────────────────────────────────────────
Route::post('/auth/google', [AuthController::class, 'googleLogin']);

// ─────────────────────────────────────────────
// Workout programs (public)
// ─────────────────────────────────────────────
Route::get('/workout-programs', [WorkoutProgramController::class, 'index']);
Route::get('/workout-programs/{id}', [WorkoutProgramController::class, 'show']);

// ─────────────────────────────────────────────
// Foods catalog (public read)
// ─────────────────────────────────────────────
Route::prefix('foods')->group(function () {
    Route::get('/',           [FoodController::class, 'index']);
    Route::get('/categories', [FoodController::class, 'categories']);
    Route::get('/{id}',       [FoodController::class, 'show']);
});

// ─────────────────────────────────────────────
// Supplements catalog (public read)
// ─────────────────────────────────────────────
Route::prefix('supplements')->group(function () {
    Route::get('/',        [SupplementController::class, 'index']);
    Route::get('/sources', [SupplementController::class, 'sources']);
    Route::get('/{id}',    [SupplementController::class, 'show']);
});

// ─────────────────────────────────────────────
// Protected routes (requires Sanctum token)
// ─────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // ── Auth / Session ─────────────────────────
    Route::get('/user', fn(Request $r) => $r->user());
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/user/onboarding', [AuthController::class, 'updateOnboarding']);

    // ── Profil User ────────────────────────────
    Route::get('/profile',            [ProfileController::class, 'show']);
    Route::put('/profile',            [ProfileController::class, 'update']);
    Route::put('/profile/fcm-token',  [ProfileController::class, 'updateFcmToken']);

    // ── Chatbot AI (Gemini) ────────────────────
    // Dipindah ke dalam auth agar tidak bisa diakses tanpa login
    Route::post('/gemini/chat', [GeminiController::class, 'ask']);

    // ── Aktivitas / Progress ───────────────────
    Route::get('activities/summary', [ActivityController::class, 'summary']);
    Route::get('activities',         [ActivityController::class, 'index']);
    Route::post('activities',        [ActivityController::class, 'store']);
    Route::get('activities/{activity}', [ActivityController::class, 'show']);

    // ── Sleep ──────────────────────────────────
    Route::get('/sleep/dashboard',           [SleepController::class, 'dashboard']);
    Route::get('/sleep/log/latest',          [SleepLogController::class, 'latest']);
    Route::get('/sleep/log/today',           [SleepLogController::class, 'today']);
    Route::get('/sleep/log/history',         [SleepLogController::class, 'history']);
    Route::get('/sleep/log/weekly-summary',  [SleepLogController::class, 'weeklySummary']);
    Route::get('/sleep/log/detail/{id}',     [SleepLogController::class, 'show'])->whereNumber('id');
    Route::get('/sleep/log/{id}',            [SleepLogController::class, 'show'])->whereNumber('id');
    Route::post('/sleep/log',                [SleepLogController::class, 'store']);
    Route::post('/sleep/log/save',           [SleepLogController::class, 'save']);
    Route::delete('/sleep/log/{id}',         [SleepLogController::class, 'destroy'])->whereNumber('id');

    // ── Diet: Food Logs ────────────────────────
    Route::prefix('food-logs')->group(function () {
        Route::get('/',        [FoodLogController::class, 'index']);
        Route::post('/',       [FoodLogController::class, 'store']);
        Route::put('/{id}',    [FoodLogController::class, 'update']);
        Route::patch('/{id}',  [FoodLogController::class, 'update']);
        Route::delete('/{id}', [FoodLogController::class, 'destroy']);
    });

    // ── Diet: Supplement Logs ──────────────────
    Route::prefix('supplement-logs')->group(function () {
        Route::get('/',        [SupplementLogController::class, 'index']);
        Route::post('/',       [SupplementLogController::class, 'store']);
        Route::put('/{id}',    [SupplementLogController::class, 'update']);
        Route::patch('/{id}',  [SupplementLogController::class, 'update']);
        Route::delete('/{id}', [SupplementLogController::class, 'destroy']);
    });

    // ── User: Water Intake (kompatibel dengan Flutter WaterIntakeService) ─
    Route::prefix('user/water-intake')->group(function () {
        Route::get('/',      [WaterIntakeController::class, 'index']);
        Route::post('/add',  [WaterIntakeController::class, 'add']);
        Route::post('/reduce', [WaterIntakeController::class, 'reduce']);
    });

    // ── Diet: Water Intake (endpoint lama tetap didukung) ─────────────────
    Route::prefix('water-intake')->group(function () {
        Route::get('/',        [WaterIntakeController::class, 'index']);
        Route::post('/',       [WaterIntakeController::class, 'store']);
        Route::delete('/{id}', [WaterIntakeController::class, 'destroy']);
    });

    // ── Admin: Foods CRUD ──────────────────────
    Route::prefix('foods')->group(function () {
        Route::post('/',       [FoodController::class, 'store']);
        Route::put('/{id}',    [FoodController::class, 'update']);
        Route::delete('/{id}', [FoodController::class, 'destroy']);
    });

    // ── Admin: Supplements CRUD ────────────────
    Route::prefix('supplements')->group(function () {
        Route::post('/',       [SupplementController::class, 'store']);
        Route::put('/{id}',    [SupplementController::class, 'update']);
        Route::delete('/{id}', [SupplementController::class, 'destroy']);
    });

    // ── Premium / Subscription ─────────────────
    Route::prefix('premium')->group(function () {
        Route::get('/status',    [SubscriptionController::class, 'status']);
        Route::post('/subscribe',[SubscriptionController::class, 'subscribe']);
        Route::post('/cancel',   [SubscriptionController::class, 'cancel']);
    });

    // ── Streak & Workout Tracking ──────────────
    Route::post('/workout/complete', [StreakController::class, 'completeWorkout']);
    Route::get('/streak',            [StreakController::class, 'getStreak']);

    // ── Progress & Diet Sync ───────────────────
    Route::get('/progress/summary',   [ProgressController::class, 'summary']);
    Route::post('/diet/food/add',     [ProgressController::class, 'addFood']);
    Route::post('/diet/water/add',    [ProgressController::class, 'addWater']);
});

