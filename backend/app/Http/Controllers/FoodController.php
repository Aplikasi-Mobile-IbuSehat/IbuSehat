<?php

namespace App\Http\Controllers;

use App\Models\Food;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class FoodController extends Controller
{
    /**
     * GET /api/foods
     *
     * Query params:
     *   - search   : string  ΓÇô filter by nama_makanan (LIKE)
     *   - kategori : string  ΓÇô filter by exact kategori
     */
    public function index(Request $request)
    {
        $validated = $request->validate([
            'search'   => ['nullable', 'string', 'max:120'],
            'kategori' => ['nullable', 'string', 'max:100'],
            'jenis'    => ['nullable', 'string', Rule::in(['halal', 'haram', 'netral'])],
            'match_mode' => ['nullable', 'string', Rule::in(['prefix', 'contains'])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'page'     => ['nullable', 'integer', 'min:1'],
        ]);

        $query = Food::query()->select([
            'id',
            DB::raw('name as nama_makanan'),
            DB::raw('category as kategori'),
            DB::raw('calories as kalori_kkal'),
            DB::raw('fat as lemak_g'),
            DB::raw('carbohydrate as karbo_g'),
            DB::raw('protein as protein_g'),
            DB::raw('NULL as jenis'),
        ]);

        // Filter by category
        if (!empty($validated['kategori'])) {
            $query->where('category', $validated['kategori']);
        }

        // Full-text substring search on food name
        if (!empty($validated['search'])) {
            $keyword = trim($validated['search']);
            $matchMode = $validated['match_mode'] ?? 'prefix';

            if ($matchMode === 'contains') {
                // Lebih fleksibel, tapi bisa lebih berat saat data besar.
                $query->where('name', 'like', '%' . $keyword . '%');
            } else {
                // Default prefix search agar index B-Tree tetap efektif.
                $query->where('name', 'like', $keyword . '%');
            }
        }

        $perPage = $validated['per_page'] ?? 20;
        $page = $validated['page'] ?? 1;

        // Generate dynamic cache key based on query parameters
        $cacheKey = 'foods_' . md5(json_encode($validated) . '_' . $page);

        // Cache for 60 minutes (3600 seconds)
        $foods = Cache::remember($cacheKey, 3600, function () use ($query, $perPage) {
            return $query->orderBy('name')->paginate($perPage);
        });

        // Add appends outside of cache so pagination links correctly include current query
        $foods->appends($request->query());

        return response()->json([
            'success' => true,
            'data'    => $foods->items(),
            'meta'    => [
                'current_page' => $foods->currentPage(),
                'last_page'    => $foods->lastPage(),
                'per_page'     => $foods->perPage(),
                'total'        => $foods->total(),
            ],
        ]);
    }

    /**
     * GET /api/foods/categories
     *
     * Returns all distinct categories.
     */
    public function categories()
    {
        $categories = Food::distinct()
            ->whereNotNull('category')
            ->orderBy('category')
            ->pluck('category');

        return response()->json([
            'success' => true,
            'data'    => $categories,
        ]);
    }

    /**
     * GET /api/foods/{id}
     *
     * Returns a single food item by ID.
     */
    public function show($id)
    {
        $food = Food::select([
            'id',
            DB::raw('name as nama_makanan'),
            DB::raw('category as kategori'),
            DB::raw('calories as kalori_kkal'),
            DB::raw('fat as lemak_g'),
            DB::raw('carbohydrate as karbo_g'),
            DB::raw('protein as protein_g'),
            DB::raw('NULL as jenis'),
            'created_at',
        ])->find($id);

        if (!$food) {
            return response()->json([
                'success' => false,
                'message' => 'Makanan tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $food,
        ]);
    }

    /**
     * POST /api/foods
     *
     * Creates a new food item.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama_makanan' => ['required', 'string', 'max:120'],
            'kategori'     => ['required', 'string', 'max:100'],
            'kalori_kkal'  => ['required', 'numeric', 'min:0'],
            'lemak_g'      => ['nullable', 'numeric', 'min:0'],
            'karbo_g'      => ['nullable', 'numeric', 'min:0'],
            'protein_g'    => ['nullable', 'numeric', 'min:0'],
            'jenis'        => ['nullable', 'string', Rule::in(['halal', 'haram', 'netral'])],
        ]);

        $food = Food::create([
            'name'         => $validated['nama_makanan'],
            'category'     => $validated['kategori'],
            'calories'     => $validated['kalori_kkal'],
            'fat'          => $validated['lemak_g'] ?? 0,
            'carbohydrate' => $validated['karbo_g'] ?? 0,
            'protein'      => $validated['protein_g'] ?? 0,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Makanan berhasil ditambahkan.',
            'data'    => $food,
        ], 201);
    }

    /**
     * PUT/PATCH /api/foods/{id}
     *
     * Updates an existing food item.
     */
    public function update(Request $request, $id)
    {
        $food = Food::find($id);

        if (!$food) {
            return response()->json([
                'success' => false,
                'message' => 'Makanan tidak ditemukan.',
            ], 404);
        }

        $validated = $request->validate([
            'nama_makanan' => ['sometimes', 'required', 'string', 'max:120'],
            'kategori'     => ['sometimes', 'required', 'string', 'max:100'],
            'kalori_kkal'  => ['sometimes', 'required', 'numeric', 'min:0'],
            'lemak_g'      => ['sometimes', 'required', 'numeric', 'min:0'],
            'karbo_g'      => ['sometimes', 'required', 'numeric', 'min:0'],
            'protein_g'    => ['sometimes', 'required', 'numeric', 'min:0'],
            'jenis'        => ['sometimes', 'nullable', 'string', Rule::in(['halal', 'haram', 'netral'])],
        ]);

        $mapped = [];
        if (array_key_exists('nama_makanan', $validated)) $mapped['name'] = $validated['nama_makanan'];
        if (array_key_exists('kategori', $validated)) $mapped['category'] = $validated['kategori'];
        if (array_key_exists('kalori_kkal', $validated)) $mapped['calories'] = $validated['kalori_kkal'];
        if (array_key_exists('lemak_g', $validated)) $mapped['fat'] = $validated['lemak_g'];
        if (array_key_exists('karbo_g', $validated)) $mapped['carbohydrate'] = $validated['karbo_g'];
        if (array_key_exists('protein_g', $validated)) $mapped['protein'] = $validated['protein_g'];

        $food->fill($mapped);
        $food->save();

        return response()->json([
            'success' => true,
            'message' => 'Makanan berhasil diperbarui.',
            'data'    => $food,
        ]);
    }

    /**
     * DELETE /api/foods/{id}
     *
     * Deletes a food item.
     */
    public function destroy($id)
    {
        $food = Food::find($id);

        if (!$food) {
            return response()->json([
                'success' => false,
                'message' => 'Makanan tidak ditemukan.',
            ], 404);
        }

        $food->delete();

        return response()->json([
            'success' => true,
            'message' => 'Makanan berhasil dihapus.',
        ]);
    }
}
