<?php

namespace App\Http\Controllers;

use App\Models\SleepLog;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SleepLogController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'sleep_time' => ['required', 'date_format:H:i'],
            'wake_time' => ['required', 'date_format:H:i'],
            'night_wakings' => ['required', 'integer', 'min:0'],
            'awake_duration' => ['required', 'integer', 'min:0'],
            'mood' => ['required', 'string', 'in:sangat_baik,baik,netral,buruk,sangat_buruk'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data tidak valid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $validated = $validator->validated();
        $nightWakings = (int) $validated['night_wakings'];

        $effectiveMinutes = $this->effectiveSleepMinutes(
            $validated['sleep_time'],
            $validated['wake_time'],
            (int) $validated['awake_duration'],
        );

        $durationScore = $this->durationScore($effectiveMinutes);
        $disruptionScore = max(0, 30 - ($nightWakings * 10));
        $moodScore = $this->moodScore($validated['mood']);
        $totalScore = min(100, max(0, $durationScore + $disruptionScore + $moodScore));

        [$category, $categoryMessage] = $this->categoryInfo($totalScore);
        $consistencyPercent = min(100, (int) round(($effectiveMinutes / (8 * 60)) * 100));
        $sleepDebtMinutes = max(0, (8 * 60) - $effectiveMinutes);

        $log = SleepLog::create([
            'user_id' => $request->user()->id,
            'sleep_time' => $validated['sleep_time'],
            'wake_time' => $validated['wake_time'],
            'night_wakings' => $nightWakings,
            'awake_duration' => $validated['awake_duration'],
            'mood' => $validated['mood'],
            'notes' => $validated['notes'] ?? null,
            'score' => $totalScore,
            'category' => $category,
            'sleep_duration_minutes' => $effectiveMinutes,
            'is_saved' => false,
        ]);

        return response()->json([
            'status' => 'success',
            'data' => $this->buildResultPayload(
                $log,
                $effectiveMinutes,
                $nightWakings,
                $consistencyPercent,
                $sleepDebtMinutes,
                $category,
                $categoryMessage,
            ),
        ]);
    }

    public function save(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'sleep_log_id' => ['required', 'integer', 'exists:sleep_logs,id'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data tidak valid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $log = SleepLog::query()
            ->where('id', $validator->validated()['sleep_log_id'])
            ->where('user_id', $request->user()->id)
            ->first();

        if ($log === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data tidur tidak ditemukan.',
            ], 404);
        }

        $log->update(['is_saved' => true]);

        return response()->json([
            'status' => 'success',
            'message' => 'Hasil berhasil disimpan',
        ]);
    }

    public function today(Request $request): JsonResponse
    {
        $log = SleepLog::query()
            ->where('user_id', $request->user()->id)
            ->whereDate('created_at', Carbon::today())
            ->orderByDesc('created_at')
            ->first();

        if ($log === null) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'has_data' => false,
                    'sleep_log_id' => null,
                    'score' => null,
                    'category' => null,
                    'category_message' => null,
                    'sleep_duration' => null,
                    'sleep_time' => null,
                    'wake_time' => null,
                ],
            ]);
        }

        [$category, $categoryMessage] = $this->categoryInfo($log->score);

        return response()->json([
            'status' => 'success',
            'data' => [
                'has_data' => true,
                'sleep_log_id' => $log->id,
                'score' => $log->score,
                'category' => $category,
                'category_message' => $categoryMessage,
                'sleep_duration' => $this->formatDurationCompact(
                    (int) $log->sleep_duration_minutes,
                ),
                'sleep_time' => $log->sleep_time,
                'wake_time' => $log->wake_time,
            ],
        ]);
    }

    public function latest(Request $request): JsonResponse
    {
        $log = SleepLog::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->first();

        if ($log === null) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'has_data' => false,
                    'score' => null,
                    'category' => null,
                    'category_message' => null,
                    'sleep_duration' => null,
                    'sleep_time' => null,
                    'wake_time' => null,
                    'logged_at' => null,
                ],
            ]);
        }

        [$category, $categoryMessage] = $this->categoryInfo($log->score);

        return response()->json([
            'status' => 'success',
            'data' => [
                'has_data' => true,
                'score' => $log->score,
                'category' => $category,
                'category_message' => $categoryMessage,
                'sleep_duration' => $this->formatDurationCompact(
                    (int) $log->sleep_duration_minutes,
                ),
                'sleep_time' => $log->sleep_time,
                'wake_time' => $log->wake_time,
                'logged_at' => $log->created_at->toDateString(),
            ],
        ]);
    }

    public function weeklySummary(Request $request): JsonResponse
    {
        $user = $request->user();
        $end = Carbon::today();
        $start = $end->copy()->subDays(6)->startOfDay();

        $logs = SleepLog::query()
            ->where('user_id', $user->id)
            ->where('created_at', '>=', $start)
            ->where('created_at', '<=', $end->copy()->endOfDay())
            ->orderBy('created_at')
            ->get();

        if ($logs->isEmpty()) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'has_data' => false,
                    'average_score' => null,
                    'average_category' => null,
                    'average_category_message' => null,
                    'average_duration' => null,
                    'total_duration' => null,
                    'average_sleep_time' => null,
                    'average_wake_time' => null,
                    'total_debt' => null,
                    'quality_label' => null,
                    'quality_color' => null,
                    'chart' => $this->emptyWeekChart($start),
                ],
            ]);
        }

        // 🔥 HITUNG TOTAL SEMUA CATATAN (BUKAN AVERAGE)
        $totalMinutes = (int) $logs->sum('sleep_duration_minutes');
        $daysWithLogs = max(1, $logs->count());
        $avgMinutes = (int) round($totalMinutes / $daysWithLogs);
        
        // Hitung average score dari semua logs
        $avgScore = (int) round($logs->avg('score'));
        [$avgCategory, $avgCategoryMessage] = $this->categoryInfo($avgScore);
        $quality = $this->weeklyQualityLabel($avgScore);

        // Build chart - group by day, sum durations per day
        $chart = [];
        $totalDebtMinutes = 0;

        for ($i = 0; $i < 7; $i++) {
            $day = $start->copy()->addDays($i);
            
            // 🔥 AMBIL SEMUA LOGS DI HARI INI (BUKAN HANYA PERTAMA)
            $dayLogs = $logs->filter(
                fn (SleepLog $l) => $l->created_at->isSameDay($day),
            );

            if ($dayLogs->isNotEmpty()) {
                // Sum durasi semua catatan di hari ini
                $dayTotalMinutes = (int) $dayLogs->sum('sleep_duration_minutes');
                $dayAvgScore = (int) round($dayLogs->avg('score'));
                
                // Hitung sleep debt untuk hari ini
                $totalDebtMinutes += max(0, (8 * 60) - $dayTotalMinutes);
                
                $chart[] = [
                    'day' => $this->dayLabelShort($day),
                    'score' => $dayAvgScore,
                    'duration_minutes' => $dayTotalMinutes,
                ];
            } else {
                $totalDebtMinutes += 8 * 60;
                
                $chart[] = [
                    'day' => $this->dayLabelShort($day),
                    'score' => null,
                    'duration_minutes' => 0,
                ];
            }
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'has_data' => true,
                'average_score' => $avgScore,
                'average_category' => $avgCategory,
                'average_category_message' => $avgCategoryMessage,
                'average_duration' => $this->formatDurationCompact($avgMinutes),
                'total_duration' => $this->formatDurationCompact($totalMinutes),
                'total_hours' => round($totalMinutes / 60, 1),
                'average_sleep_time' => $this->averageTimeFromLogs($logs, 'sleep_time'),
                'average_wake_time' => $this->averageTimeFromLogs($logs, 'wake_time'),
                'total_debt' => $totalDebtMinutes === 0
                    ? '0j 0m'
                    : $this->formatDurationCompact($totalDebtMinutes),
                'quality_label' => $quality['label'],
                'quality_color' => $quality['color'],
                'chart' => $chart,
            ],
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $log = SleepLog::query()
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if ($log === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data tidur tidak ditemukan.',
            ], 404);
        }

        $effectiveMinutes = (int) $log->sleep_duration_minutes;
        $nightWakings = (int) $log->night_wakings;
        [$category, $categoryMessage] = $this->categoryInfo((int) $log->score);
        $consistencyPercent = min(100, (int) round(($effectiveMinutes / (8 * 60)) * 100));
        $sleepDebtMinutes = max(0, (8 * 60) - $effectiveMinutes);
        $mood = $this->moodDisplay((string) $log->mood);

        $payload = $this->buildResultPayload(
            $log,
            $effectiveMinutes,
            $nightWakings,
            $consistencyPercent,
            $sleepDebtMinutes,
            $category,
            $categoryMessage,
        );

        return response()->json([
            'status' => 'success',
            'data' => array_merge($payload, [
                'mood' => $log->mood,
                'mood_label' => $mood['label'],
                'mood_emoji' => $mood['emoji'],
                'sleep_time' => $log->sleep_time,
                'wake_time' => $log->wake_time,
            ]),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $log = SleepLog::query()
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if ($log === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'Data tidur tidak ditemukan.',
            ], 404);
        }

        $log->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Riwayat tidur berhasil dihapus.',
        ]);
    }

    public function history(Request $request): JsonResponse
    {
        $period = $request->query('period', 'weekly');
        $search = trim((string) $request->query('search', ''));

        $query = SleepLog::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at');

        if ($period === 'weekly') {
            $query->where('created_at', '>=', Carbon::today()->subDays(6)->startOfDay());
        }

        $logs = $query->get();

        $items = $logs->map(function (SleepLog $log) {
            $score = (int) $log->score;
            $status = $this->historyStatusLabel($score);

            return [
                'id' => $log->id,
                'date' => $log->created_at->format('d M Y'),
                'date_iso' => $log->created_at->toDateString(),
                'sleep_duration' => $this->formatDurationCompact(
                    (int) $log->sleep_duration_minutes,
                ),
                'score' => $score,
                'status_label' => $status['label'],
                'emoji' => $status['emoji'],
            ];
        });

        if ($search !== '') {
            $needle = mb_strtolower($search);
            $items = $items->filter(function (array $item) use ($needle) {
                return str_contains(mb_strtolower($item['date']), $needle)
                    || str_contains(mb_strtolower($item['status_label']), $needle)
                    || str_contains((string) $item['score'], $needle)
                    || str_contains(mb_strtolower($item['sleep_duration']), $needle);
            })->values();
        }

        return response()->json([
            'status' => 'success',
            'data' => $items->values()->all(),
        ]);
    }

    /** @return array{label: string, emoji: string} */
    private function historyStatusLabel(int $score): array
    {
        if ($score >= 85) {
            return ['label' => 'Sangat Baik', 'emoji' => '😄'];
        }
        if ($score >= 70) {
            return ['label' => 'Baik', 'emoji' => '🙂'];
        }
        if ($score >= 55) {
            return ['label' => 'Netral', 'emoji' => '😐'];
        }

        return ['label' => 'Buruk', 'emoji' => '😡'];
    }

    /** @return array{label: string, color: string} */
    private function weeklyQualityLabel(int $avgScore): array
    {
        if ($avgScore >= 75) {
            return ['label' => 'Baik', 'color' => 'green'];
        }
        if ($avgScore >= 60) {
            return ['label' => 'Cukup', 'color' => 'orange'];
        }

        return ['label' => 'Kurang', 'color' => 'red'];
    }

    private function buildResultPayload(
        SleepLog $log,
        int $effectiveMinutes,
        int $nightWakings,
        int $consistencyPercent,
        int $sleepDebtMinutes,
        string $category,
        string $categoryMessage,
    ): array {
        return [
            'sleep_log_id' => $log->id,
            'is_saved' => (bool) $log->is_saved,
            'score' => $log->score,
            'category' => $category,
            'category_message' => $categoryMessage,
            'sleep_duration' => $this->formatDurationCompact($effectiveMinutes),
            'sleep_duration_range' => $this->sleepDurationRange($effectiveMinutes),
            'consistency_percent' => $consistencyPercent,
            'consistency_label' => $this->consistencyLabel($consistencyPercent),
            'night_wakings' => $nightWakings,
            'night_wakings_label' => $this->nightWakingsLabel($nightWakings),
            'sleep_debt' => $effectiveMinutes >= 8 * 60
                ? '0j 0m'
                : $this->formatDurationCompact($sleepDebtMinutes),
            'sleep_debt_label' => $this->sleepDebtLabel($sleepDebtMinutes),
            'analysis' => $this->generateAnalysis($log->score, $effectiveMinutes, $nightWakings),
        ];
    }

    private function effectiveSleepMinutes(string $sleepTime, string $wakeTime, int $awakeDuration): int
    {
        $sleep = Carbon::createFromFormat('H:i', $sleepTime);
        $wake = Carbon::createFromFormat('H:i', $wakeTime);

        if ($wake->lessThanOrEqualTo($sleep)) {
            $wake->addDay();
        }

        $total = $sleep->diffInMinutes($wake);

        return max(0, $total - $awakeDuration);
    }

    private function durationScore(int $effectiveMinutes): int
    {
        $idealMin = 7 * 60;
        $idealMax = 9 * 60;

        if ($effectiveMinutes >= $idealMin && $effectiveMinutes <= $idealMax) {
            return 40;
        }

        if ($effectiveMinutes < $idealMin) {
            return (int) round(($effectiveMinutes / $idealMin) * 40);
        }

        $excessHours = ($effectiveMinutes - $idealMax) / 60;

        return (int) round(max(0, 40 - ($excessHours * 8)));
    }

    /** @return array{label: string, emoji: string} */
    private function moodDisplay(string $mood): array
    {
        return match ($mood) {
            'sangat_baik' => ['label' => 'Sangat Baik', 'emoji' => '😄'],
            'baik' => ['label' => 'Baik', 'emoji' => '🙂'],
            'netral' => ['label' => 'Netral', 'emoji' => '😐'],
            'buruk' => ['label' => 'Buruk', 'emoji' => '😡'],
            'sangat_buruk' => ['label' => 'Sangat Buruk', 'emoji' => '😢'],
            default => ['label' => 'Netral', 'emoji' => '😐'],
        };
    }

    private function moodScore(string $mood): int
    {
        return match ($mood) {
            'sangat_baik' => 30,
            'baik' => 24,
            'netral' => 18,
            'buruk' => 12,
            'sangat_buruk' => 6,
            default => 0,
        };
    }

    /** @return array{0: string, 1: string} */
    private function categoryInfo(int $score): array
    {
        if ($score >= 80) {
            return ['Good Sleep', 'Kualitas tidurmu tergolong baik 🎉'];
        }
        if ($score >= 60) {
            return ['Fair Sleep', 'Tidurmu cukup, masih bisa ditingkatkan 💪'];
        }
        if ($score >= 40) {
            return ['Poor Sleep', 'Kualitas tidurmu kurang optimal 😴'];
        }

        return ['Bad Sleep', 'Tidurmu perlu perhatian lebih ⚠️'];
    }

    private function sleepDurationRange(int $minutes): string
    {
        if ($minutes >= 7 * 60 && $minutes <= 9 * 60) {
            return '7-9 jam';
        }
        if ($minutes < 7 * 60) {
            return 'Kurang';
        }

        return 'Berlebih';
    }

    private function consistencyLabel(int $percent): string
    {
        if ($percent >= 90) {
            return 'Sangat Baik';
        }
        if ($percent >= 75) {
            return 'Baik';
        }
        if ($percent >= 60) {
            return 'Cukup';
        }

        return 'Kurang';
    }

    private function nightWakingsLabel(int $count): string
    {
        return match (true) {
            $count === 0 => 'Sangat Baik',
            $count === 1 => 'Baik',
            $count === 2 => 'Cukup',
            default => 'Sering',
        };
    }

    private function sleepDebtLabel(int $debtMinutes): string
    {
        if ($debtMinutes === 0) {
            return 'Tidak Ada';
        }
        if ($debtMinutes <= 30) {
            return 'Ringan';
        }
        if ($debtMinutes <= 90) {
            return 'Sedang';
        }

        return 'Berat';
    }

    private function generateAnalysis(int $score, int $effectiveMinutes, int $nightWakings): string
    {
        if ($score >= 80) {
            if ($nightWakings === 0) {
                return 'Durasi tidurmu sudah cukup baik! Coba tidur 30 menit lebih awal untuk meningkatkan pemulihan tubuh dan energi sepanjang hari.';
            }

            return 'Skor tidurmu sangat baik! Pertahankan jadwal tidur teratur dan minimalkan gangguan di malam hari.';
        }

        if ($score >= 60) {
            if ($effectiveMinutes < 7 * 60) {
                return 'Durasi tidurmu mendekati ideal. Usahakan tidur 30–60 menit lebih awal agar tubuh lebih rileks dan segar saat bangun.';
            }

            return 'Tidurmu cukup baik, namun masih ada ruang peningkatan. Kurangi aktivitas layar sebelum tidur untuk kualitas yang lebih optimal.';
        }

        if ($score >= 40) {
            if ($nightWakings >= 2) {
                return 'Gangguan tidur malam cukup sering terjadi. Coba hindari kafein sore hari dan buat kamar tidur lebih gelap serta tenang.';
            }

            return 'Kualitas tidurmu masih di bawah optimal. Fokus pada rutinitas tidur yang konsisten dan hindari makan berat sebelum tidur.';
        }

        return 'Tidurmu perlu perhatian serius. Prioritaskan istirahat cukup, kurangi stres, dan konsultasikan jika masalah tidur berlanjut.';
    }

    private function formatDurationCompact(int $minutes): string
    {
        $hours = intdiv($minutes, 60);
        $mins = $minutes % 60;

        return "{$hours}j {$mins}m";
    }

    private function dayLabelShort(Carbon $date): string
    {
        return match ($date->dayOfWeekIso) {
            1 => 'Sen',
            2 => 'Sel',
            3 => 'Rab',
            4 => 'Kam',
            5 => 'Jum',
            6 => 'Sab',
            7 => 'Min',
            default => $date->format('D'),
        };
    }

    /** @return list<array{day: string, score: null}> */
    private function emptyWeekChart(Carbon $start): array
    {
        $chart = [];
        for ($i = 0; $i < 7; $i++) {
            $day = $start->copy()->addDays($i);
            $chart[] = [
                'day' => $this->dayLabelShort($day),
                'score' => null,
            ];
        }

        return $chart;
    }

    /**
     * @param  \Illuminate\Support\Collection<int, SleepLog>  $logs
     */
    private function averageTimeFromLogs($logs, string $column): string
    {
        $minutesList = $logs->map(function (SleepLog $log) use ($column) {
            $time = $log->{$column};
            if (! is_string($time) || $time === '') {
                return null;
            }
            $parsed = Carbon::createFromFormat('H:i', $time);

            return $parsed->hour * 60 + $parsed->minute;
        })->filter(fn ($m) => $m !== null);

        if ($minutesList->isEmpty()) {
            return '--:--';
        }

        $avg = (int) round($minutesList->avg());
        $hours = intdiv($avg, 60) % 24;
        $mins = $avg % 60;

        return sprintf('%02d:%02d', $hours, $mins);
    }
}
