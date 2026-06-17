<?php

namespace App\Services;

use App\Models\UserStreak;
use App\Models\WorkoutLog;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class StreakService
{
    /**
     * Complete a workout and update streak
     *
     * @param int $userId
     * @param int|null $workoutId
     * @return array
     */
    public function completeWorkout(int $userId, ?int $workoutId = null): array
    {
        return DB::transaction(function () use ($userId, $workoutId) {
            $today = Carbon::today();

            // 1. Check if user already completed a workout today
            $alreadyCompletedToday = WorkoutLog::where('user_id', $userId)
                ->where('completed_at', $today)
                ->where('is_completed', true)
                ->exists();

            // 2. Save workout log
            $workoutLog = WorkoutLog::create([
                'user_id' => $userId,
                'workout_id' => $workoutId,
                'completed_at' => $today,
                'is_completed' => true,
            ]);

            // If already completed today, don't update streak
            if ($alreadyCompletedToday) {
                $userStreak = $this->getUserStreak($userId);
                return [
                    'streak_active' => $userStreak->streak_active,
                    'streak_longest' => $userStreak->streak_longest,
                    'is_new_streak_day' => false,
                    'message' => 'Workout berhasil dicatat, namun streak sudah dihitung hari ini.',
                ];
            }

            // 3. Get or create user streak record
            $userStreak = UserStreak::firstOrCreate(
                ['user_id' => $userId],
                [
                    'streak_active' => 0,
                    'streak_longest' => 0,
                    'last_workout_date' => null,
                ]
            );

            // 4. Update streak logic
            $lastWorkoutDate = $userStreak->last_workout_date;
            $yesterday = Carbon::yesterday();

            if ($lastWorkoutDate === null) {
                // First workout ever
                $userStreak->streak_active = 1;
            } elseif ($lastWorkoutDate->eq($yesterday)) {
                // Workout yesterday, continue streak
                $userStreak->streak_active += 1;
            } elseif ($lastWorkoutDate->eq($today)) {
                // Already counted today (shouldn't happen due to check above, but safety)
                // Do nothing
            } elseif ($lastWorkoutDate->lt($yesterday)) {
                // Missed days, reset streak
                $userStreak->streak_active = 1;
            }

            // Update last workout date
            $userStreak->last_workout_date = $today;

            // Update longest streak if current is higher
            if ($userStreak->streak_active > $userStreak->streak_longest) {
                $userStreak->streak_longest = $userStreak->streak_active;
            }

            $userStreak->save();

            return [
                'streak_active' => $userStreak->streak_active,
                'streak_longest' => $userStreak->streak_longest,
                'is_new_streak_day' => true,
                'message' => 'Streak berhasil diperbarui!',
            ];
        });
    }

    /**
     * Get user streak data
     *
     * @param int $userId
     * @return UserStreak
     */
    public function getUserStreak(int $userId): UserStreak
    {
        return UserStreak::firstOrCreate(
            ['user_id' => $userId],
            [
                'streak_active' => 0,
                'streak_longest' => 0,
                'last_workout_date' => null,
            ]
        );
    }

    /**
     * Get detailed streak information with calendar
     *
     * @param int $userId
     * @param int $year
     * @param int $month
     * @return array
     */
    public function getStreakDetails(int $userId, int $year, int $month): array
    {
        $userStreak = $this->getUserStreak($userId);

        // Get total workout count
        $totalWorkouts = WorkoutLog::where('user_id', $userId)
            ->where('is_completed', true)
            ->count();

        // Get active days this month
        $startOfMonth = Carbon::createFromDate($year, $month, 1)->startOfMonth();
        $endOfMonth = Carbon::createFromDate($year, $month, 1)->endOfMonth();

        $activeDaysThisMonth = WorkoutLog::where('user_id', $userId)
            ->where('is_completed', true)
            ->whereBetween('completed_at', [$startOfMonth, $endOfMonth])
            ->distinct('completed_at')
            ->count('completed_at');

        // Generate calendar for the month
        $calendar = $this->generateCalendar($userId, $year, $month);

        return [
            'streak_active' => $userStreak->streak_active,
            'streak_longest' => $userStreak->streak_longest,
            'total_aktivitas' => $totalWorkouts,
            'hari_aktif_bulan_ini' => $activeDaysThisMonth,
            'calendar' => $calendar,
        ];
    }

    /**
     * Generate calendar with workout status
     *
     * @param int $userId
     * @param int $year
     * @param int $month
     * @return array
     */
    private function generateCalendar(int $userId, int $year, int $month): array
    {
        $startOfMonth = Carbon::createFromDate($year, $month, 1)->startOfMonth();
        $endOfMonth = Carbon::createFromDate($year, $month, 1)->endOfMonth();
        $today = Carbon::today();

        // Get all completed workout dates for this month
        $completedDates = WorkoutLog::where('user_id', $userId)
            ->where('is_completed', true)
            ->whereBetween('completed_at', [$startOfMonth, $endOfMonth])
            ->pluck('completed_at')
            ->map(fn($date) => Carbon::parse($date)->format('Y-m-d'))
            ->unique()
            ->toArray();

        $calendar = [];
        $currentDate = $startOfMonth->copy();

        while ($currentDate->lte($endOfMonth)) {
            $dateString = $currentDate->format('Y-m-d');
            
            if (in_array($dateString, $completedDates)) {
                $status = 'completed';
            } elseif ($currentDate->eq($today)) {
                $status = 'today';
            } elseif ($currentDate->gt($today)) {
                $status = 'future';
            } else {
                $status = 'missed';
            }

            $calendar[] = [
                'date' => $dateString,
                'status' => $status,
            ];

            $currentDate->addDay();
        }

        return $calendar;
    }
}
