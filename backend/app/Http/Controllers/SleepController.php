<?php

namespace App\Http\Controllers;

use App\Models\SleepLog;
use App\Models\SleepSession;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class SleepController extends Controller
{
    public function dashboard(Request $request): JsonResponse
    {
        $user = $request->user();

        if (Schema::hasTable('sleep_logs')) {
            $latestLog = SleepLog::query()
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->first();

            if ($latestLog !== null) {
                return response()->json(
                    array_merge(['has_data' => true], $this->buildFromLogs($user, $latestLog)),
                );
            }
        }

        if (Schema::hasTable('sleep_sessions')) {
            $latest = SleepSession::query()
                ->where('user_id', $user->id)
                ->whereDate('wake_time', Carbon::today())
                ->orderByDesc('wake_time')
                ->first();

            if ($latest !== null) {
                return response()->json(
                    array_merge(['has_data' => true], $this->buildFromSession($user)),
                );
            }
        }

        return response()->json($this->emptyDashboard());
    }

    private function buildFromLogs($user, SleepLog $latest): array
    {
        $today = Carbon::today();
        $startWeek = $today->copy()->startOfWeek(Carbon::MONDAY);

        $logs = SleepLog::query()
            ->where('user_id', $user->id)
            ->where('created_at', '>=', $startWeek)
            ->orderBy('created_at')
            ->get();

        $weeklyScores = [];
        for ($i = 0; $i < 7; $i++) {
            $day = $startWeek->copy()->addDays($i);
            $log = $logs->first(
                fn (SleepLog $l) => $l->created_at->isSameDay($day)
            );
            $weeklyScores[] = $log?->score ?? 0;
        }

        $filledScores = array_map(
            fn ($s) => $s > 0 ? $s : 75,
            $weeklyScores
        );

        $avgMinutes = (int) round($logs->avg('sleep_duration_minutes') ?: 0);
        $totalDebt = max(0, (8 * 60 * 7) - $logs->sum('sleep_duration_minutes'));

        return [
            'sleep_score' => $latest->score,
            'sleep_category' => $this->mapCategoryEn($latest->category),
            'sleep_message' => $this->logMessage($latest->score),
            'sleep_duration' => $this->formatDuration($latest->sleep_duration_minutes),
            'sleep_time' => $latest->sleep_time,
            'wake_time' => $latest->wake_time,
            'average_sleep' => $this->formatDuration($avgMinutes),
            'sleep_debt' => $this->formatDuration($totalDebt),
            'sleep_quality' => $latest->score >= 70 ? 'Baik' : 'Cukup',
            'weekly_sleep_scores' => $filledScores,
        ];
    }

    private function mapCategoryEn(string $category): string
    {
        return match ($category) {
            'Good Sleep', 'Sangat Baik', 'Baik' => 'Good Sleep',
            'Fair Sleep', 'Cukup' => 'Fair Sleep',
            'Poor Sleep', 'Buruk' => 'Poor Sleep',
            'Bad Sleep' => 'Bad Sleep',
            default => 'Poor Sleep',
        };
    }

    private function logMessage(int $score): string
    {
        if ($score >= 80) {
            return 'Tidurmu lebih baik dari kemarin!';
        }
        if ($score >= 60) {
            return 'Tidurmu cukup baik, pertahankan!';
        }

        return 'Tidurmu perlu ditingkatkan.';
    }

    private function emptyDashboard(): array
    {
        return [
            'has_data' => false,
            'sleep_score' => 0,
            'sleep_category' => '-',
            'sleep_message' => 'Belum ada data tidur',
            'sleep_duration' => '-',
            'sleep_time' => '-',
            'wake_time' => '-',
            'average_sleep' => '-',
            'sleep_debt' => '-',
            'sleep_quality' => '-',
            'weekly_sleep_scores' => [0, 0, 0, 0, 0, 0, 0],
        ];
    }

    private function buildFromSession($user): array
    {
        $today = Carbon::today();
        $startWeek = $today->copy()->startOfWeek(Carbon::MONDAY);

        $sessions = SleepSession::query()
            ->where('user_id', $user->id)
            ->where('wake_time', '>=', $startWeek)
            ->orderBy('wake_time')
            ->get();

        $weeklyScores = [];
        for ($i = 0; $i < 7; $i++) {
            $day = $startWeek->copy()->addDays($i);
            $session = $sessions->first(
                fn (SleepSession $s) => $s->wake_time->isSameDay($day)
            );
            $weeklyScores[] = $session?->sleep_score ?? 0;
        }

        $latest = $sessions->sortByDesc('wake_time')->first();
        $avgMinutes = (int) round($sessions->avg('duration_minutes') ?: 0);
        $totalDebt = max(0, (8 * 60 * 7) - $sessions->sum('duration_minutes'));

        return [
            'sleep_score' => $latest?->sleep_score ?? 82,
            'sleep_category' => $this->scoreCategory($latest?->sleep_score ?? 82),
            'sleep_message' => 'Tidurmu lebih baik dari kemarin!',
            'sleep_duration' => $this->formatDuration($latest?->duration_minutes ?? 460),
            'sleep_time' => $latest?->sleep_time?->format('H:i') ?? '22:30',
            'wake_time' => $latest?->wake_time?->format('H:i') ?? '05:50',
            'average_sleep' => $this->formatDuration($avgMinutes),
            'sleep_debt' => $this->formatDuration($totalDebt),
            'sleep_quality' => ($latest?->sleep_score ?? 82) >= 70 ? 'Baik' : 'Cukup',
            'weekly_sleep_scores' => array_map(
                fn ($s) => $s > 0 ? $s : 75,
                $weeklyScores
            ),
        ];
    }

    private function scoreCategory(int $score): string
    {
        if ($score >= 80) {
            return 'Good Sleep';
        }
        if ($score >= 60) {
            return 'Fair Sleep';
        }

        return 'Poor Sleep';
    }

    private function formatDuration(int $minutes): string
    {
        $hours = intdiv($minutes, 60);
        $mins = $minutes % 60;

        if ($hours > 0 && $mins > 0) {
            return "{$hours}j {$mins}m";
        }
        if ($hours > 0) {
            return "{$hours}j";
        }

        return "{$mins}m";
    }
}
