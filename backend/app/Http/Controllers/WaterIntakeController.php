<?php

namespace App\Http\Controllers;

use App\Models\WaterIntake;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Carbon;

class WaterIntakeController extends Controller
{
    private const GOAL_ML = 2000;

    private function todayTotal(): int
    {
        return WaterIntake::where('user_id', Auth::id())
            ->forDate(now()->toDateString())
            ->sum('amount_ml');
    }

    private function makeResponse(int $total): JsonResponse
    {
        return response()->json([
            'success'      => true,
            'water_intake' => (int) $total,
            'goal_intake'  => self::GOAL_ML,
            'total_ml'     => (int) $total,
        ]);
    }

    /**
     * GET /api/user/water-intake?date=YYYY-MM-DD
     */
    public function index(Request $request): JsonResponse
    {
        $date = $request->input('date', now()->toDateString());

        $total = (int) WaterIntake::where('user_id', Auth::id())
            ->forDate($date)
            ->sum('amount_ml');

        return response()->json([
            'success'      => true,
            'date'         => $date,
            'water_intake' => $total,
            'goal_intake'  => self::GOAL_ML,
            'total_ml'     => $total,
        ]);
    }

    /**
     * GET /api/user/water-intake/weekly
     * Ringkasan mingguan — data tetap tersimpan, hanya ditampilkan per hari
     */
    public function weekly(Request $request): JsonResponse
    {
        $endDate   = Carbon::today();
        $startDate = Carbon::today()->subDays(6); // 7 hari terakhir

        $rows = WaterIntake::where('user_id', Auth::id())
            ->forWeek($startDate->toDateString(), $endDate->toDateString())
            ->selectRaw('date, SUM(amount_ml) as total_ml')
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->keyBy(fn($r) => $r->date->toDateString());

        // Isi semua 7 hari, bahkan yang tidak ada datanya (0 ml)
        $days = [];
        for ($i = 6; $i >= 0; $i--) {
            $date        = Carbon::today()->subDays($i)->toDateString();
            $days[$date] = [
                'date'     => $date,
                'total_ml' => (int) ($rows[$date]->total_ml ?? 0),
                'goal_ml'  => self::GOAL_ML,
                'achieved' => (int) ($rows[$date]->total_ml ?? 0) >= self::GOAL_ML,
            ];
        }

        return response()->json([
            'success' => true,
            'data'    => array_values($days),
        ]);
    }

    /**
     * POST /api/user/water-intake/add
     */
    public function add(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['required', 'integer', 'min:1', 'max:5000'],
        ]);

        WaterIntake::create([
            'user_id'   => Auth::id(),
            'amount_ml' => $validated['amount'],
            'date'      => now()->toDateString(),
        ]);

        return $this->makeResponse($this->todayTotal());
    }

    /**
     * POST /api/user/water-intake/reduce
     */
    public function reduce(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['required', 'integer', 'min:1', 'max:5000'],
        ]);

        $toReduce = $validated['amount'];

        $logs = WaterIntake::where('user_id', Auth::id())
            ->forDate(now()->toDateString())
            ->orderByDesc('created_at')
            ->get();

        foreach ($logs as $log) {
            if ($toReduce <= 0) break;

            if ($log->amount_ml <= $toReduce) {
                $toReduce -= $log->amount_ml;
                $log->delete();
            } else {
                $log->amount_ml -= $toReduce;
                $log->save();
                $toReduce = 0;
            }
        }

        return $this->makeResponse($this->todayTotal());
    }

    /**
     * DELETE /api/water-intake/{id}
     */
    public function destroy(int $id): JsonResponse
    {
        $log = WaterIntake::where('id', $id)
            ->where('user_id', Auth::id())
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Data tidak ditemukan atau akses ditolak.',
            ], 404);
        }

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Catatan minum air berhasil dihapus.',
        ]);
    }
}