<?php

namespace App\Http\Controllers;

use App\Models\SupplementLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class SupplementLogController extends Controller
{
    /**
     * Display a listing of logged supplements for the authenticated user.
     */
    public function index(Request $request)
    {
        $validated = $request->validate([
            'date' => ['nullable', 'date'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'page' => ['nullable', 'integer', 'min:1'],
        ]);

        $query = SupplementLog::query()
            ->where('user_id', Auth::id())
            ->select([
                'id',
                'user_id',
                'supplement_id',
                'nama_suplemen',
                'komposisi',
                'kemasan',
                'aturan_pakai',
                'gambar',
                'source',
                'reminder_time',
                'is_taken',
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
            'data' => $logs->items(),
            'meta' => [
                'current_page' => $logs->currentPage(),
                'last_page' => $logs->lastPage(),
                'per_page' => $logs->perPage(),
                'total' => $logs->total(),
            ],
        ]);
    }

    /**
     * Store a newly created supplement log.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'supplement_id' => ['nullable', 'integer', 'min:1'],
            'nama_suplemen' => ['required', 'string', 'max:190'],
            'komposisi' => ['nullable', 'string'],
            'kemasan' => ['nullable', 'string', 'max:190'],
            'aturan_pakai' => ['nullable', 'string'],
            // Ditambahkan validasi 'url': sebelumnya field ini cuma dicek
            // sebagai string bebas apa pun sampai 255 karakter.
            'gambar' => ['nullable', 'string', 'max:255', 'url'],
            'source' => ['nullable', 'string', 'max:100'],
            'reminder_time' => ['nullable', 'date_format:H:i'],
            'is_taken' => ['nullable', 'boolean'],
        ]);

        $log = SupplementLog::create([
            'user_id' => Auth::id(),
            'supplement_id' => $validated['supplement_id'] ?? null,
            'nama_suplemen' => trim($validated['nama_suplemen']),
            // Field kosong disimpan sebagai null (bukan string kosong ''),
            // supaya konsisten dengan entri yang dibuat lewat GeminiController
            // (yang pakai nullableString()). Kalau disimpan sebagai '', kode
            // lain yang mengecek is_null() untuk "data belum lengkap" tidak
            // akan mengenali entri dari jalur manual ini.
            'komposisi' => $validated['komposisi'] ?? null,
            'kemasan' => $validated['kemasan'] ?? null,
            'aturan_pakai' => $validated['aturan_pakai'] ?? null,
            'gambar' => $validated['gambar'] ?? null,
            // Sebelumnya default ke 'Halodoc' walau user tidak pernah bilang
            // datanya dari Halodoc — itu atribusi palsu. Default sekarang
            // netral dan jujur bahwa ini input manual dari pengguna sendiri.
            'source' => $validated['source'] ?? 'Dicatat manual oleh pengguna',
            'reminder_time' => $validated['reminder_time'] ?? null,
            'is_taken' => $validated['is_taken'] ?? false,
        ]);

        return response()->json([
            'success' => true,
            'data' => $log,
        ], 201);
    }

    /**
     * Update the specified supplement log.
     */
    public function update(Request $request, $id)
    {
        $log = SupplementLog::where('id', $id)
            ->where('user_id', Auth::id())
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Supplement log not found or access denied.',
            ], 404);
        }

        $validated = $request->validate([
            'supplement_id' => ['sometimes', 'nullable', 'integer', 'min:1'],
            'nama_suplemen' => ['sometimes', 'required', 'string', 'max:190'],
            'komposisi' => ['sometimes', 'nullable', 'string'],
            'kemasan' => ['sometimes', 'nullable', 'string', 'max:190'],
            'aturan_pakai' => ['sometimes', 'nullable', 'string'],
            'gambar' => ['sometimes', 'nullable', 'string', 'max:255', 'url'],
            'source' => ['sometimes', 'nullable', 'string', 'max:100'],
            'reminder_time' => ['sometimes', 'nullable', 'date_format:H:i'],
            'is_taken' => ['sometimes', 'boolean'],
        ]);

        if (isset($validated['nama_suplemen'])) {
            $validated['nama_suplemen'] = trim($validated['nama_suplemen']);
        }

        $log->fill($validated);
        $log->save();

        return response()->json([
            'success' => true,
            'data' => $log,
        ]);
    }

    /**
     * Remove the specified supplement log.
     */
    public function destroy($id)
    {
        $log = SupplementLog::where('id', $id)
            ->where('user_id', Auth::id())
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Supplement log not found or access denied.',
            ], 404);
        }

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Supplement log deleted successfully.',
        ]);
    }
}