<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\FoodLog;
use App\Models\WaterIntake;
use App\Models\Activity;
use App\Models\WorkoutLog;

class ProgressController extends Controller
{
    /**
     * GET /api/progress/summary
     * Ambil data user untuk minggu ini (7 hari terakhir).
     */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $today = Carbon::today();
        $startDate = $today->copy()->subDays(6);

        // Fetch logs
        $waterLogs = WaterIntake::where('user_id', $user->id)
            ->whereDate('date', '>=', $startDate->toDateString())
            ->whereDate('date', '<=', $today->toDateString())
            ->get();

        $foodLogs = FoodLog::where('user_id', $user->id)
            ->whereDate('created_at', '>=', $startDate->toDateString())
            ->whereDate('created_at', '<=', $today->toDateString() . ' 23:59:59')
            ->get();

        $workoutLogs = WorkoutLog::where('user_id', $user->id)
            ->whereDate('completed_at', '>=', $startDate->toDateString())
            ->whereDate('completed_at', '<=', $today->toDateString())
            ->get();

        $activities = Activity::where('user_id', $user->id)
            ->whereDate('started_at', '>=', $startDate->toDateString())
            ->whereDate('started_at', '<=', $today->toDateString() . ' 23:59:59')
            ->get();

        $waterDaily = [];
        $nutritionDaily = [];
        $workoutDaily = [];

        $totalWater = 0;
        $totalNutrition = 0;

        $todayWater = 0;
        $todayNutrition = 0;
        $todayWorkoutMinutes = 0;

        $indonesianDays = [
            0 => 'M', // Minggu
            1 => 'S', // Senin
            2 => 'S', // Selasa
            3 => 'R', // Rabu
            4 => 'K', // Kamis
            5 => 'J', // Jumat
            6 => 'S', // Sabtu
        ];

        // Loop past 7 days (6 days ago until today)
        for ($i = 6; $i >= 0; $i--) {
            $day = $today->copy()->subDays($i);
            $dateStr = $day->toDateString();

            // Sum amount_ml for this day
            $dayWater = (int) $waterLogs->filter(function($log) use ($dateStr) {
                return Carbon::parse($log->date)->toDateString() === $dateStr;
            })->sum('amount_ml');

            // Sum kcal for this day
            $dayNutrition = (int) $foodLogs->filter(function($log) use ($dateStr) {
                return Carbon::parse($log->created_at)->toDateString() === $dateStr;
            })->sum('kcal');

            // Sum workout logs duration_seconds for this day
            $dayWorkoutLogsSeconds = (int) $workoutLogs->filter(function($log) use ($dateStr) {
                return Carbon::parse($log->completed_at)->toDateString() === $dateStr;
            })->sum('duration_seconds');

            // Sum activities duration_seconds for this day
            $dayActivitiesSeconds = (int) $activities->filter(function($log) use ($dateStr) {
                return Carbon::parse($log->started_at)->toDateString() === $dateStr;
            })->sum('duration_seconds');

            $dayWorkoutSeconds = $dayWorkoutLogsSeconds + $dayActivitiesSeconds;
            $dayWorkoutMinutes = (int) round($dayWorkoutSeconds / 60);

            $dayLabel = ($i === 0) ? 'H' : $indonesianDays[$day->dayOfWeek];

            $waterDaily[] = [
                'day' => $dayLabel,
                'amount' => $dayWater
            ];

            $nutritionDaily[] = [
                'day' => $dayLabel,
                'amount' => $dayNutrition
            ];

            $workoutDaily[] = [
                'day' => $dayLabel,
                'amount' => $dayWorkoutMinutes
            ];

            $totalWater += $dayWater;
            $totalNutrition += $dayNutrition;

            if ($i === 0) {
                $todayWater = $dayWater;
                $todayNutrition = $dayNutrition;
                $todayWorkoutMinutes = $dayWorkoutMinutes;
            }
        }

        // Target harian & mingguan
        // Target air: dari user profile jika ada weight (weight * 35), default 2000ml/hari
        $dailyWaterTarget = 2000;
        if ($user->weight) {
            $dailyWaterTarget = (int) round($user->weight * 35);
        }
        $targetWater = $dailyWaterTarget * 7;

        // Target kalori: dari user profile jika ada bmr, default 2067kkal/hari
        $dailyCalorieTarget = 2067;
        if ($user->weight && $user->height && $user->age) {
            // BMR wanita (Harris–Benedict): 10 * weight + 6.25 * height - 5 * age - 161
            $bmr = (10 * $user->weight) + (6.25 * $user->height) - (5 * $user->age) - 161;
            $calculated = (int) round($bmr * 1.3); // TDEE lightly active
            if ($calculated > 500) {
                $dailyCalorieTarget = $calculated;
            }
        }
        $targetNutrition = $dailyCalorieTarget * 7;

        // Total workout minutes is the sum of daily workout minutes
        $totalWorkoutMinutes = (int) array_sum(array_column($workoutDaily, 'amount'));
        $targetWorkoutMinutes = 75; // 75 minutes weekly target

        // Percent = (total_aktual / total_target) * 100, max 100
        $waterPercent = $targetWater > 0 ? min(100, (int) round(($totalWater / $targetWater) * 100)) : 0;
        $nutritionPercent = $targetNutrition > 0 ? min(100, (int) round(($totalNutrition / $targetNutrition) * 100)) : 0;
        $workoutPercent = $targetWorkoutMinutes > 0 ? min(100, (int) round(($totalWorkoutMinutes / $targetWorkoutMinutes) * 100)) : 0;

        // Average
        $waterAvg = (int) round($totalWater / 7);
        $nutritionAvg = (int) round($totalNutrition / 7);
        $workoutAvg = (int) round($totalWorkoutMinutes / 7);

        return response()->json([
            'status' => 'success',
            'data' => [
                'weekly' => [
                    'water' => [
                        'total_ml' => $totalWater,
                        'target_ml' => $targetWater,
                        'percent' => $waterPercent,
                        'daily' => $waterDaily,
                        'average' => $waterAvg,
                        'today' => $todayWater,
                        'target_daily_ml' => $dailyWaterTarget
                    ],
                    'nutrition' => [
                        'total_kkal' => $totalNutrition,
                        'target_kkal' => $targetNutrition,
                        'percent' => $nutritionPercent,
                        'daily' => $nutritionDaily,
                        'average' => $nutritionAvg,
                        'today' => $todayNutrition,
                        'target_daily_kkal' => $dailyCalorieTarget
                    ],
                    'workout' => [
                        'total_minutes' => $totalWorkoutMinutes,
                        'target_minutes' => $targetWorkoutMinutes,
                        'percent' => $workoutPercent,
                        'daily' => $workoutDaily,
                        'average' => $workoutAvg,
                        'today' => $todayWorkoutMinutes,
                        'target_daily_minutes' => 25
                    ]
                ]
            ]
        ]);
    }

    /**
     * POST /api/diet/food/add
     */
    public function addFood(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'food_name'   => 'required|string',
            'calories'    => 'required|numeric',
            'weight_gram' => 'required|numeric',
            'logged_at'   => 'nullable|date',
        ]);

        $log = new FoodLog();
        $log->user_id      = Auth::id();
        $log->nama_makanan = $validated['food_name'];
        $log->weight       = $validated['weight_gram'];
        $log->kcal         = $validated['calories'];
        $log->protein      = 0;
        $log->carbs        = 0;
        $log->fat          = 0;
        $log->category     = '';
        $log->jenis        = '';

        if (!empty($validated['logged_at'])) {
            $log->created_at = Carbon::parse($validated['logged_at']);
            $log->updated_at = Carbon::parse($validated['logged_at']);
        }

        $log->save();

        return response()->json([
            'status' => 'success',
            'data' => $log
        ], 201);
    }

    /**
     * POST /api/diet/water/add
     */
    public function addWater(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount_ml' => 'required|integer',
            'logged_at' => 'nullable|date',
        ]);

        $date = !empty($validated['logged_at']) ? Carbon::parse($validated['logged_at'])->toDateString() : now()->toDateString();

        $log = WaterIntake::create([
            'user_id'   => Auth::id(),
            'amount_ml' => $validated['amount_ml'],
            'date'      => $date,
        ]);

        return response()->json([
            'status' => 'success',
            'data' => $log
        ], 201);
    }
}
