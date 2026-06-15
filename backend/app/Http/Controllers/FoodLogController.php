<?php

namespace App\Http\Controllers;

use App\Models\FoodLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

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

        $query = FoodLog::query()
            ->where('user_id', Auth::id())
            ->select([
                'id',
                'user_id',
                'makanan_id',
                'nama_makanan',
                'weight',
                'kcal',
                'protein',
                'carbs',
                'fat',
                'category',
                'created_at',
            ]);
        
        if (!empty($validated['date'])) {
            $query->whereDate('created_at', $validated['date']);
        }

        $perPage = $validated['per_page'] ?? 30;
        $logs = $query
            ->orderByDesc('created_at')
            ->paginate($perPage)
            ->appends($request->query());

        return response()->json([
            'success' => true,
            'data'    => $logs->items(),
            'meta'    => [
                'current_page' => $logs->currentPage(),
                'last_page'    => $logs->lastPage(),
                'per_page'     => $logs->perPage(),
                'total'        => $logs->total(),
            ],
        ]);
    }

    /**
     * Store a newly created logged food.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama_makanan' => 'required|string',
            'weight'       => 'required|numeric',
            'kcal'         => 'required|numeric',
            'protein'      => 'required|numeric',
            'carbs'        => 'required|numeric',
            'fat'          => 'required|numeric',
            'makanan_id'   => 'nullable|integer',
            'category'     => 'nullable|string',
        ]);

        $log = new FoodLog();
        $log->user_id      = Auth::id();
        $log->makanan_id   = $validated['makanan_id'] ?? null;
        $log->nama_makanan = $validated['nama_makanan'];
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

        $validated = $request->validate([
            'nama_makanan' => 'sometimes|required|string',
            'weight'       => 'sometimes|required|numeric|min:0',
            'kcal'         => 'sometimes|required|numeric|min:0',
            'protein'      => 'sometimes|required|numeric|min:0',
            'carbs'        => 'sometimes|required|numeric|min:0',
            'fat'          => 'sometimes|required|numeric|min:0',
            'category'     => 'sometimes|nullable|string',
        ]);

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
