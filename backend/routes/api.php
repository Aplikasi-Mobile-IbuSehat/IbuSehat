<?php

use App\Http\Controllers\ActivityController;
use App\Http\Controllers\GeminiController;
use App\Http\Controllers\WorkoutProgramController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/test', function () {
    return "OK";
});

Route::post('/gemini/chat', [GeminiController::class, 'ask']);
Route::get('/workout-programs', [WorkoutProgramController::class, 'index']);
Route::get('/workout-programs/{id}', [WorkoutProgramController::class, 'show']);

Route::middleware('auth:sanctum')->group(function () {
    // Literal `summary` must be registered before `activities/{activity}`.
    Route::get('activities/summary', [ActivityController::class, 'summary']);
    Route::get('activities', [ActivityController::class, 'index']);
    Route::post('activities', [ActivityController::class, 'store']);
    Route::get('activities/{activity}', [ActivityController::class, 'show']);
});

