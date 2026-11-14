<?php

namespace App\Http\Controllers;

use App\Models\FoodLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class FoodLogController extends Controller
{
    /**
     * Display a listing of logged foods for the authenticated user.
     */
    public function index(Request $request)
    {
        $validated = $request->validate([
            'date'     => ['nullable', 'date'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'page'     => ['nullable', 'integer', 'min:1'],
        ]);

        $date = $validated['date'] ?? now()->toDateString();

        $query = FoodLog::query()
            ->where('user_id', Auth::id())
            ->whereDate('created_at', $date)
            ->select([
                'id', 'user_id', 'makanan_id', 'nama_makanan',
                'weight', 'kcal', 'protein', 'carbs', 'fat',
                'category', 'created_at',
            ]);

        $perPage = $validated['per_page'] ?? 30;
        $logs = $query
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->appends($request->query());

        $summary = FoodLog::where('user_id', Auth::id())
            ->whereDate('created_at', $date)
            ->selectRaw('
                COALESCE(SUM(kcal), 0)    as total_kcal,
                COALESCE(SUM(protein), 0) as total_protein,
                COALESCE(SUM(carbs), 0)   as total_carbs,
                COALESCE(SUM(fat), 0)     as total_fat
            ')
            ->first();

        return response()->json([
            'success' => true,
            'date'    => $date,
            'data'    => $logs->items(),
            'summary' => $summary,
            'meta'    => [
                'current_page' => $logs->currentPage(),
                'last_page'    => $logs->lastPage(),
                'per_page'     => $logs->perPage(),
                'total'        => $logs->total(),
            ],
        ]);
    }

    public function summary(Request $request)
    {
        $validated = $request->validate([
            'from' => ['nullable', 'date'],
            'to'   => ['nullable', 'date'],
        ]);

        $from = $validated['from'] ?? now()->startOfWeek()->toDateString();
        $to   = $validated['to']   ?? now()->toDateString();

        $summary = FoodLog::where('user_id', Auth::id())
            ->whereBetween(DB::raw('DATE(created_at)'), [$from, $to])
            ->selectRaw('
                DATE(created_at)          as date,
                COALESCE(SUM(kcal), 0)    as total_kcal,
                COALESCE(SUM(protein), 0) as total_protein,
                COALESCE(SUM(carbs), 0)   as total_carbs,
                COALESCE(SUM(fat), 0)     as total_fat,
                COUNT(*)                   as total_entries
            ')
            ->groupBy(DB::raw('DATE(created_at)'))
            ->orderBy('date')
            ->get();

        return response()->json([
            'success' => true,
            'from'    => $from,
            'to'      => $to,
            'data'    => $summary,
        ]);
    }

    /**
     * Store a newly created logged food.
     */
    public function store(Request $request)
    {
        // Batas min/max di sini sengaja disamakan dengan clamp yang dipakai
        // GeminiController (MAX_WEIGHT_G / MAX_KCAL / MAX_MACRO_G), supaya
        // entri manual dari endpoint ini (bukan lewat chatbot) tidak bisa
        // berisi nilai negatif atau ekstrem yang merusak agregasi
        // SUM(kcal)/SUM(protein) dsb di index()/summary(). Sebelumnya
        // endpoint ini TIDAK punya min:0 sama sekali (beda dengan update()),
        // jadi weight/kcal negatif bisa lolos.
        $validated = $request->validate([
            'nama_makanan' => 'required|string|max:190',
            'weight'       => 'required|numeric|min:0|max:3000',
            'kcal'         => 'required|numeric|min:0|max:3000',
            'protein'      => 'required|numeric|min:0|max:500',
            'carbs'        => 'required|numeric|min:0|max:500',
            'fat'          => 'required|numeric|min:0|max:500',
            'makanan_id'   => 'nullable|integer',
            'category'     => 'nullable|string|max:100',
        ]);

        $log = new FoodLog();
        $log->user_id      = Auth::id();
        $log->makanan_id   = $validated['makanan_id'] ?? null;
        $log->nama_makanan = trim($validated['nama_makanan']);
        $log->weight       = $validated['weight'];
        $log->kcal         = $validated['kcal'];
        $log->protein      = $validated['protein'];
        $log->carbs        = $validated['carbs'];
        $log->fat          = $validated['fat'];
        $log->category     = $validated['category'] ?? '';
        $log->save();

        return response()->json([
            'success' => true,
            'data'    => $log
        ], 201);
    }

    /**
     * Update the specified logged food.
     */
    public function update(Request $request, $id)
    {
        $log = FoodLog::where('id', $id)
            ->where('user_id', Auth::id())
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Food log not found or access denied.'
            ], 404);
        }

        // Tambahkan batas atas (max) di sini juga, konsisten dengan store() —
        // sebelumnya update() sudah punya min:0 tapi tidak ada batas atas,
        // jadi nilai ekstrem (mis. kcal 999999999) masih bisa lolos lewat PUT.
        $validated = $request->validate([
            'nama_makanan' => 'sometimes|required|string|max:190',
            'weight'       => 'sometimes|required|numeric|min:0|max:3000',
            'kcal'         => 'sometimes|required|numeric|min:0|max:3000',
            'protein'      => 'sometimes|required|numeric|min:0|max:500',
            'carbs'        => 'sometimes|required|numeric|min:0|max:500',
            'fat'          => 'sometimes|required|numeric|min:0|max:500',
            'category'     => 'sometimes|nullable|string|max:100',
        ]);

        if (isset($validated['nama_makanan'])) {
            $validated['nama_makanan'] = trim($validated['nama_makanan']);
        }

        $log->fill($validated);
        if ($request->has('makanan_id')) {
            $log->makanan_id = $request->makanan_id;
        }
        $log->save();

        return response()->json([
            'success' => true,
            'data'    => $log
        ]);
    }

    /**
     * Remove the specified logged food.
     */
    public function destroy($id)
    {
        $log = FoodLog::where('id', $id)
            ->where('user_id', Auth::id())
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Food log not found or access denied.'
            ], 404);
        }

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Food log deleted successfully.'
        ]);
    }
}