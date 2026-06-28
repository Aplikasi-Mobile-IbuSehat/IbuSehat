<?php

namespace App\Http\Controllers;

use App\Services\StreakService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class StreakController extends Controller
{
    protected StreakService $streakService;

    public function __construct(StreakService $streakService)
    {
        $this->streakService = $streakService;
    }

    /**
     * Complete a workout and update streak
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function completeWorkout(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'workout_id' => 'nullable|integer|exists:workout_programs,id',
            'duration_seconds' => 'nullable|integer|min:0',
            'is_completed' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors(),
            ], 422);
        }

        try {
            $userId = $request->user()->id;
            $workoutId = $request->input('workout_id');
            $durationSeconds = (int) $request->input('duration_seconds', 0);
            $isCompleted = $request->has('is_completed') ? (bool) $request->input('is_completed') : true;

            $result = $this->streakService->completeWorkout($userId, $workoutId, $durationSeconds, $isCompleted);

            return response()->json([
                'success' => true,
                'data' => $result,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mencatat workout: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get streak information with calendar
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function getStreak(Request $request): JsonResponse
    {
        try {
            $userId = $request->user()->id;
            
            // Default to current month if not provided
            $year = $request->input('year', Carbon::now()->year);
            $month = $request->input('month', Carbon::now()->month);

            // Validate year and month
            $validator = Validator::make([
                'year' => $year,
                'month' => $month,
            ], [
                'year' => 'integer|min:2020|max:2100',
                'month' => 'integer|min:1|max:12',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validasi gagal',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $streakData = $this->streakService->getStreakDetails($userId, $year, $month);

            return response()->json([
                'success' => true,
                'data' => $streakData,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data streak: ' . $e->getMessage(),
            ], 500);
        }
    }
}
