<?php

namespace App\Http\Controllers;

use App\Models\WaterIntake;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class WaterIntakeController extends Controller
{
    private const GOAL_ML = 2000; // target harian default: 2 liter

    /**
     * Helper: hitung total asupan air user untuk hari ini.
     */
    private function todayTotal(): int
    {
        return WaterIntake::where('user_id', Auth::id())
            ->whereDate('date', now()->toDateString())
            ->sum('amount_ml');
    }

    /**
     * Format response konsisten dengan yang diharapkan Flutter WaterIntakeModel.
     * Model Flutter membaca: water_intake, goal_intake
     */
    private function makeResponse(int $total): \Illuminate\Http\JsonResponse
    {
        return response()->json([
            'success'      => true,
            'water_intake' => $total,
            'goal_intake'  => self::GOAL_ML,
            'total_ml'     => $total,   // backward compat
        ]);
    }

    /**
     * GET /api/user/water-intake
     * GET /api/water-intake?date=YYYY-MM-DD
     * Ambil total asupan air user untuk tanggal tertentu (default: hari ini).
     */
    public function index(Request $request)
    {
        $date = $request->input('date', now()->toDateString());

        $total = WaterIntake::where('user_id', Auth::id())
            ->whereDate('date', $date)
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
     * POST /api/user/water-intake/add
     * Tambah jumlah asupan air (amount dalam mL).
     */
    public function add(Request $request)
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
     * Kurangi jumlah asupan air (amount dalam mL).
     * Menghapus entry terbaru sebesar nilai yang diminta.
     */
    public function reduce(Request $request)
    {
        $validated = $request->validate([
            'amount' => ['required', 'integer', 'min:1', 'max:5000'],
        ]);

        $toReduce = $validated['amount'];

        // Hapus log terbaru dari hari ini sampai mencukupi pengurangan
        $logs = WaterIntake::where('user_id', Auth::id())
            ->whereDate('date', now()->toDateString())
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
     * POST /api/water-intake
     * Tambah catatan minum air (endpoint lama, tetap didukung).
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'amount_ml' => ['required', 'integer', 'min:1', 'max:5000'],
            'date'      => ['nullable', 'date'],
        ]);

        $log = WaterIntake::create([
            'user_id'   => Auth::id(),
            'amount_ml' => $validated['amount_ml'],
            'date'      => $validated['date'] ?? now()->toDateString(),
        ]);

        return response()->json([
            'success' => true,
            'data'    => $log,
        ], 201);
    }

    /**
     * DELETE /api/water-intake/{id}
     * Hapus entri catatan minum air.
     */
    public function destroy($id)
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
