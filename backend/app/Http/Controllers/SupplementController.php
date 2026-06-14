<?php

namespace App\Http\Controllers;

use App\Models\Supplement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class SupplementController extends Controller
{
    /**
     * GET /api/supplements
     *
     * Query params:
     *  - search   : nama suplemen (prefix search, indexed)
     *  - source   : sumber suplemen
     *  - per_page : 1..100
     */
    public function index(Request $request)
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'source' => ['nullable', 'string', 'max:100'],
            'match_mode' => ['nullable', 'string', \Illuminate\Validation\Rule::in(['prefix', 'contains'])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'page' => ['nullable', 'integer', 'min:1'],
        ]);

        $query = Supplement::query()->select([
            'id',
            DB::raw('name as nama_suplemen'),
            DB::raw('composition as komposisi'),
            DB::raw('NULL as bentuk_sediaan'),
            DB::raw('packaging as kemasan'),
            DB::raw('usage_rule as aturan_pakai'),
            DB::raw("'Halodoc' as sumber"),
            DB::raw("IF(image IS NOT NULL, CONCAT('" . url('images/suplement') . "/', image), NULL) as gambar"),
        ]);

        if (!empty($validated['search'])) {
            $keyword = trim($validated['search']);
            $matchMode = $validated['match_mode'] ?? 'prefix';
            if ($matchMode === 'contains') {
                $query->where('name', 'like', '%' . $keyword . '%');
            } else {
                $query->where('name', 'like', $keyword . '%');
            }
        }

        $perPage = $validated['per_page'] ?? 20;
        $page = $validated['page'] ?? 1;

        $cacheKey = 'supplements_' . md5(json_encode($validated) . '_' . $page);

        $supplements = Cache::remember($cacheKey, 3600, function () use ($query, $perPage) {
            return $query->orderBy('name')->paginate($perPage);
        });

        $supplements->appends($request->query());

        return response()->json([
            'success' => true,
            'data' => $supplements->items(),
            'meta' => [
                'current_page' => $supplements->currentPage(),
                'last_page' => $supplements->lastPage(),
                'per_page' => $supplements->perPage(),
                'total' => $supplements->total(),
            ],
        ]);
    }

    /**
     * GET /api/supplements/sources
     */
    public function sources()
    {
        $sources = collect(['Halodoc']);

        return response()->json([
            'success' => true,
            'data' => $sources,
        ]);
    }

    /**
     * GET /api/supplements/{id}
     */
    public function show($id)
    {
        $supplement = Supplement::select([
            'id',
            DB::raw('name as nama_suplemen'),
            DB::raw('composition as komposisi'),
            DB::raw('NULL as bentuk_sediaan'),
            DB::raw('packaging as kemasan'),
            DB::raw('usage_rule as aturan_pakai'),
            DB::raw("'Halodoc' as sumber"),
            DB::raw("IF(image IS NOT NULL, CONCAT('" . url('images/suplement') . "/', image), NULL) as gambar"),
            'created_at',
        ])->find($id);

        if (!$supplement) {
            return response()->json([
                'success' => false,
                'message' => 'Suplemen tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $supplement,
        ]);
    }

    /**
     * POST /api/supplements
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama_suplemen' => ['required', 'string', 'max:120'],
            'komposisi' => ['nullable', 'string'],
            'kemasan' => ['nullable', 'string', 'max:190'],
            'aturan_pakai' => ['nullable', 'string'],
            'gambar' => ['nullable', 'string', 'max:255'],
        ]);

        $supplement = Supplement::create([
            'name' => $validated['nama_suplemen'],
            'composition' => $validated['komposisi'] ?? '',
            'packaging' => $validated['kemasan'] ?? '',
            'usage_rule' => $validated['aturan_pakai'] ?? '',
            'image' => $validated['gambar'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Suplemen berhasil ditambahkan.',
            'data' => $supplement,
        ], 201);
    }

    /**
     * PUT/PATCH /api/supplements/{id}
     */
    public function update(Request $request, $id)
    {
        $supplement = Supplement::find($id);

        if (!$supplement) {
            return response()->json([
                'success' => false,
                'message' => 'Suplemen tidak ditemukan.',
            ], 404);
        }

        $validated = $request->validate([
            'nama_suplemen' => ['sometimes', 'required', 'string', 'max:120'],
            'komposisi' => ['sometimes', 'nullable', 'string'],
            'kemasan' => ['sometimes', 'nullable', 'string', 'max:190'],
            'aturan_pakai' => ['sometimes', 'nullable', 'string'],
            'gambar' => ['sometimes', 'nullable', 'string', 'max:255'],
        ]);

        $mapped = [];
        if (array_key_exists('nama_suplemen', $validated)) $mapped['name'] = $validated['nama_suplemen'];
        if (array_key_exists('komposisi', $validated)) $mapped['composition'] = $validated['komposisi'];
        if (array_key_exists('kemasan', $validated)) $mapped['packaging'] = $validated['kemasan'];
        if (array_key_exists('aturan_pakai', $validated)) $mapped['usage_rule'] = $validated['aturan_pakai'];
        if (array_key_exists('gambar', $validated)) $mapped['image'] = $validated['gambar'];

        $supplement->fill($mapped);
        $supplement->save();

        return response()->json([
            'success' => true,
            'message' => 'Suplemen berhasil diperbarui.',
            'data' => $supplement,
        ]);
    }

    /**
     * DELETE /api/supplements/{id}
     */
    public function destroy($id)
    {
        $supplement = Supplement::find($id);

        if (!$supplement) {
            return response()->json([
                'success' => false,
                'message' => 'Suplemen tidak ditemukan.',
            ], 404);
        }

        $supplement->delete();

        return response()->json([
            'success' => true,
            'message' => 'Suplemen berhasil dihapus.',
        ]);
    }
}
