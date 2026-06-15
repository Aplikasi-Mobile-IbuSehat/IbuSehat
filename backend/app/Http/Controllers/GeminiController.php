<?php

namespace App\Http\Controllers;

use App\Models\Food;
use App\Models\FoodLog;
use App\Models\Supplement;
use App\Models\SupplementLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class GeminiController extends Controller
{
    /**
     * Jumlah pasangan (user+model) percakapan terakhir yang dikirim ke Gemini
     * sebagai konteks (sliding window). 3-4 pasangan dianggap cukup untuk
     * menjaga konteks alur "sudah makan apa -> tawaran catat -> konfirmasi"
     * tanpa membuat prompt terlalu panjang/boros token.
     */
    private const HISTORY_WINDOW_PAIRS = 4;

    /**
     * System instruction yang mengatur perilaku & format output Gemini.
     * Gemini WAJIB membalas dalam format JSON sesuai skema di bawah.
     */
    private function buildSystemInstruction(): string
    {
        return <<<TEXT
Kamu adalah asisten nutrisi untuk aplikasi Ibusehat. Tugasmu membantu pengguna mencatat
makanan dan suplemen yang mereka konsumsi ke dalam log harian.

ATURAN UTAMA:
1. Jika pengguna menyebutkan makanan/suplemen yang sudah mereka konsumsi, tanyakan apakah
   mereka ingin mencatatnya ke log (kecuali poin 4).
2. JANGAN catat apapun ke log sebelum pengguna memberi konfirmasi eksplisit ("ya", "boleh",
   "catat", dsb) pada giliran percakapan berikutnya.
3. Setelah pengguna konfirmasi, isi field "action" dengan data lengkap sesuai skema di bawah.
4. Jika makanan yang disebut tergolong MAKANAN OLAHAN BERAT / junk food / tidak sehat
   (contoh: gorengan tepung tebal, minuman bersoda, makanan cepat saji ultra-proses,
   makanan tinggi gula/pengawet berlebihan), JANGAN tawarkan pencatatan sama sekali.
   Cukup tanggapi secara ramah/edukatif tanpa menyinggung pencatatan log, dan field
   "action" harus null.
5. Untuk estimasi gizi (kalori, protein, karbohidrat, lemak), gunakan data referensi yang
   diberikan dalam "context_data" jika tersedia (artinya nama makanan/suplemen cocok dengan
   database). Jika tidak ada referensi yang cocok dan makanan tergolong sehat, estimasikan
   sendiri nilai gizinya secara wajar berdasarkan pengetahuanmu per porsi yang disebutkan
   pengguna (default 100g jika tidak disebutkan).
6. Field "type" pada action: "food_log" untuk catatan makanan, "supplement_log" untuk
   suplemen.
7. Field "new_master_data" diisi true HANYA jika data makanan/suplemen tersebut TIDAK
   ditemukan referensinya di context_data DAN kamu melakukan estimasi sendiri, sehingga
   Laravel akan menambahkannya sebagai data master baru juga. Jika referensi ditemukan di
   context_data, set false.

FORMAT RESPONS — WAJIB JSON VALID, TANPA markdown code fence, dengan struktur tepat:
{
  "reply": "teks balasan untuk pengguna dalam Bahasa Indonesia yang ramah",
  "action": null
}

ATAU jika pengguna sudah konfirmasi pencatatan:
{
  "reply": "teks konfirmasi ke pengguna, mis. 'Sudah saya catat ya!'",
  "action": {
    "type": "food_log",
    "new_master_data": false,
    "food_log": {
      "makanan_id": null,
      "nama_makanan": "Ayam Goreng",
      "weight": 100,
      "kcal": 250,
      "protein": 27,
      "carbs": 0,
      "fat": 15,
      "category": "Lauk"
    }
  }
}

ATAU untuk suplemen:
{
  "reply": "teks konfirmasi ke pengguna",
  "action": {
    "type": "supplement_log",
    "new_master_data": false,
    "supplement_log": {
      "supplement_id": null,
      "nama_suplemen": "Vitamin D3",
      "komposisi": "Cholecalciferol 1000 IU",
      "kemasan": "Botol 30 kapsul",
      "aturan_pakai": "1x sehari setelah makan",
      "source": "Halodoc",
      "reminder_time": null,
      "is_taken": true
    }
  }
}

PENTING: Balas HANYA dengan objek JSON di atas, tanpa teks lain, tanpa ```json, tanpa
penjelasan tambahan di luar JSON.
TEXT;
    }

    /**
     * POST /api/gemini/chat
     *
     * Body:
     *   - prompt  : string (wajib) - pesan terbaru dari user
     *   - history : array (opsional) - riwayat percakapan sebelumnya
     *               format: [{ "role": "user"|"model", "text": "..." }, ...]
     *               Hanya N pasangan terakhir (sliding window) yang akan
     *               benar-benar dikirim ke Gemini, sisanya diabaikan.
     *
     * Route ini dilindungi middleware:
     *   - auth:sanctum            -> wajib login
     *   - throttle:chat           -> anti-spam per menit (lihat RouteServiceProvider)
     *   - premium.chat-quota      -> wajib premium aktif + kuota harian
     */
    public function ask(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'prompt'         => ['required', 'string', 'max:1000'],
            'history'        => ['nullable', 'array', 'max:40'],
            'history.*.role' => ['required_with:history', 'string', Rule::in(['user', 'model'])],
            'history.*.text' => ['required_with:history', 'string'],
        ]);

        $apiKey = env('GEMINI_API_KEY');

        if (!$apiKey) {
            return response()->json([
                'success' => false,
                'message' => 'API Key belum dikonfigurasi di server.',
            ], 500);
        }

        $user = $request->user();
        $userPrompt = $validated['prompt'];

        // 1. Cari referensi data gizi/suplemen berdasarkan kata kunci di prompt
        $contextData = $this->buildContextData($userPrompt);

        try {
            // 2. Susun contents untuk Gemini: system instruction + sliding window history + prompt baru
            $slidingHistory = $this->applySlidingWindow($validated['history'] ?? []);
            $contents = $this->buildContents($slidingHistory, $userPrompt, $contextData);

            $response = Http::timeout(30)->withHeaders([
                'Content-Type' => 'application/json',
            ])->post(
                "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key={$apiKey}",
                [
                    'contents' => $contents,
                    
                ]
            );

            if (!$response->successful()) {
                Log::error('Gemini API error', ['status' => $response->status(), 'body' => $response->body()]);

                return response()->json([
                    'success' => false,
                    'message' => 'Gagal mendapatkan respon dari AI.',
                    'details' => $response->json(),
                ], $response->status());
            }

            $result = $response->json();
            $rawText = $result['candidates'][0]['content']['parts'][0]['text'] ?? null;

            if (!$rawText) {
                return response()->json([
                    'success' => false,
                    'message' => 'AI tidak memberikan jawaban.',
                ], 500);
            }

            // 3. Parsing JSON dari Gemini (bersihkan kemungkinan markdown fence)
            $parsed = $this->parseAiJson($rawText);

            $quotaMeta = [
                'used'  => $request->attributes->get('chat_quota_used'),
                'limit' => $request->attributes->get('chat_quota_limit'),
            ];

            if ($parsed === null) {
                // Gagal parsing -> tampilkan teks mentah sebagai fallback, tanpa action
                return response()->json([
                    'success' => true,
                    'data' => [
                        'reply'      => $rawText,
                        'saved'      => null,
                        'save_error' => null,
                    ],
                    'meta' => ['quota' => $quotaMeta],
                ]);
            }

            $reply  = $parsed['reply'] ?? 'Maaf, saya tidak mendapatkan jawaban.';
            $action = $parsed['action'] ?? null;

            $saved     = null;
            $saveError = null;

            // 4. Jika ada action terkonfirmasi, simpan ke database
            if (is_array($action) && !empty($action['type'])) {
                try {
                    $saved = $this->handleAction($user, $action);
                } catch (\Exception $e) {
                    Log::error('Gagal menyimpan action AI', [
                        'error'  => $e->getMessage(),
                        'action' => $action,
                    ]);
                    $saveError = 'Gagal menyimpan catatan ke database.';
                }
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'reply'      => $reply,
                    'saved'      => $saved,
                    'save_error' => $saveError,
                ],
                'meta' => ['quota' => $quotaMeta],
            ]);
        } catch (\Exception $e) {
            Log::error('Gemini Integration Error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan koneksi pada server backend.',
            ], 500);
        }
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /**
     * Ambil hanya N pasangan (user+model) terakhir dari history untuk dikirim
     * ke Gemini (sliding window), agar prompt tidak terus membesar dan biaya
     * token tetap terkendali, sambil tetap menjaga konteks percakapan yang
     * relevan untuk alur konfirmasi pencatatan.
     */
    private function applySlidingWindow(array $history): array
    {
        $maxMessages = self::HISTORY_WINDOW_PAIRS * 2; // tiap pasangan = 1 user + 1 model

        if (count($history) <= $maxMessages) {
            return $history;
        }

        return array_slice($history, -$maxMessages);
    }

    /**
     * Cari data referensi makanan & suplemen berdasarkan keyword sederhana
     * yang muncul dalam prompt pengguna. Hasil ini disuntikkan ke prompt
     * Gemini sebagai "context_data" agar AI memakai data DB jika cocok.
     */
    private function buildContextData(string $prompt): array
    {
        // Ambil kata-kata signifikan dari prompt (panjang >= 3 huruf)
        $words = collect(preg_split('/\s+/', mb_strtolower($prompt)))
            ->filter(fn ($w) => mb_strlen($w) >= 3)
            ->unique()
            ->values();

        if ($words->isEmpty()) {
            return ['foods' => [], 'supplements' => []];
        }

        $foodQuery = Food::query();
        $supplementQuery = Supplement::query();

        $foodQuery->where(function ($q) use ($words) {
            foreach ($words as $w) {
                $q->orWhere('name', 'like', '%' . $w . '%');
            }
        });

        $supplementQuery->where(function ($q) use ($words) {
            foreach ($words as $w) {
                $q->orWhere('name', 'like', '%' . $w . '%');
            }
        });

        $foods = $foodQuery->limit(5)->get([
            'id', 'name', 'category', 'calories', 'fat', 'carbohydrate', 'protein',
        ]);

        $supplements = $supplementQuery->limit(5)->get([
            'id', 'name', 'composition', 'packaging', 'usage_rule',
        ]);

        return [
            'foods' => $foods->map(fn ($f) => [
                'id'           => $f->id,
                'nama_makanan' => $f->name,
                'kategori'     => $f->category,
                'kalori_kkal'  => $f->calories,
                'lemak_g'      => $f->fat,
                'karbo_g'      => $f->carbohydrate,
                'protein_g'    => $f->protein,
            ])->all(),
            'supplements' => $supplements->map(fn ($s) => [
                'id'            => $s->id,
                'nama_suplemen' => $s->name,
                'komposisi'     => $s->composition,
                'kemasan'       => $s->packaging,
                'aturan_pakai'  => $s->usage_rule,
            ])->all(),
        ];
    }

    /**
     * Susun array "contents" untuk request Gemini, menyertakan system
     * instruction sebagai turn pertama, lalu riwayat percakapan (sudah
     * dipangkas oleh sliding window), lalu prompt baru beserta context_data.
     */
    private function buildContents(array $history, string $userPrompt, array $contextData): array
    {
        $contents = [];

        // System instruction dikirim sebagai turn pertama "user" + balasan
        // pendek dari "model" agar Gemini mematuhinya sebagai konteks.
        $contents[] = [
            'role'  => 'user',
            'parts' => [['text' => $this->buildSystemInstruction()]],
        ];
        $contents[] = [
            'role'  => 'model',
            'parts' => [['text' => json_encode(['reply' => 'Siap, saya akan mengikuti instruksi tersebut.', 'action' => null])]],
        ];

        // Riwayat percakapan sebelumnya (sliding window)
        foreach ($history as $h) {
            $role = $h['role'] === 'model' ? 'model' : 'user';
            $contents[] = [
                'role'  => $role,
                'parts' => [['text' => $h['text']]],
            ];
        }

        // Prompt terbaru + context_data referensi DB
        $userMessage = $userPrompt;
        if (!empty($contextData['foods']) || !empty($contextData['supplements'])) {
            $userMessage .= "\n\ncontext_data: " . json_encode($contextData, JSON_UNESCAPED_UNICODE);
        } else {
            $userMessage .= "\n\ncontext_data: {\"foods\": [], \"supplements\": []}";
        }

        $contents[] = [
            'role'  => 'user',
            'parts' => [['text' => $userMessage]],
        ];

        return $contents;
    }

    /**
     * Bersihkan & decode JSON dari teks respons Gemini. Mengembalikan null
     * jika gagal parsing.
     */
    private function parseAiJson(string $rawText): ?array
    {
        $text = trim($rawText);

        // Hapus markdown code fence jika ada (```json ... ``` atau ``` ... ```)
        if (str_starts_with($text, '```')) {
            $text = preg_replace('/^```[a-zA-Z]*\s*/', '', $text);
            $text = preg_replace('/```\s*$/', '', $text);
            $text = trim($text);
        }

        $decoded = json_decode($text, true);

        return is_array($decoded) ? $decoded : null;
    }

    /**
     * Eksekusi penyimpanan ke database berdasarkan "action" dari AI.
     * Mengembalikan ringkasan data yang tersimpan.
     */
    private function handleAction($user, array $action): array
    {
        $type          = $action['type'] ?? null;
        $newMasterData = (bool) ($action['new_master_data'] ?? false);

        if ($type === 'food_log') {
            $data = $action['food_log'] ?? [];

            $namaMakanan = (string) ($data['nama_makanan'] ?? '');
            $makananId   = $data['makanan_id'] ?? null;
            $weight      = (float) ($data['weight'] ?? 0);
            $kcal        = (float) ($data['kcal'] ?? 0);
            $protein     = (float) ($data['protein'] ?? 0);
            $carbs       = (float) ($data['carbs'] ?? 0);
            $fat         = (float) ($data['fat'] ?? 0);
            $category    = (string) ($data['category'] ?? '');

            if ($namaMakanan === '') {
                throw new \InvalidArgumentException('nama_makanan kosong pada action food_log');
            }

            // Tambahkan ke food_nutrition sebagai data master baru jika diminta
            if ($newMasterData && empty($makananId)) {
                $existing = Food::where('name', $namaMakanan)->first();

                if ($existing) {
                    $makananId = $existing->id;
                } else {
                    $newFood = Food::create([
                        'name'         => $namaMakanan,
                        'category'     => $category ?: 'Lainnya',
                        'calories'     => $kcal,
                        'fat'          => $fat,
                        'carbohydrate' => $carbs,
                        'protein'      => $protein,
                    ]);
                    $makananId = $newFood->id;
                }
            }

            $log = FoodLog::create([
                'user_id'      => $user->id,
                'makanan_id'   => $makananId,
                'nama_makanan' => $namaMakanan,
                'weight'       => $weight,
                'kcal'         => $kcal,
                'protein'      => $protein,
                'carbs'        => $carbs,
                'fat'          => $fat,
                'category'     => $category,
            ]);

            return [
                'type' => 'food_log',
                'data' => $log,
            ];
        }

        if ($type === 'supplement_log') {
            $data = $action['supplement_log'] ?? [];

            $namaSuplemen = (string) ($data['nama_suplemen'] ?? '');
            $supplementId = $data['supplement_id'] ?? null;
            $komposisi    = (string) ($data['komposisi'] ?? '');
            $kemasan      = (string) ($data['kemasan'] ?? '');
            $aturanPakai  = (string) ($data['aturan_pakai'] ?? '');
            $source       = (string) ($data['source'] ?? 'Halodoc');
            $reminderTime = $data['reminder_time'] ?? null;
            $isTaken      = (bool) ($data['is_taken'] ?? false);

            if ($namaSuplemen === '') {
                throw new \InvalidArgumentException('nama_suplemen kosong pada action supplement_log');
            }

            // Tambahkan ke supplements sebagai data master baru jika diminta
            if ($newMasterData && empty($supplementId)) {
                $existing = Supplement::where('name', $namaSuplemen)->first();

                if ($existing) {
                    $supplementId = $existing->id;
                } else {
                    $newSupplement = Supplement::create([
                        'name'        => $namaSuplemen,
                        'composition' => $komposisi,
                        'packaging'   => $kemasan,
                        'usage_rule'  => $aturanPakai,
                        'image'       => null,
                    ]);
                    $supplementId = $newSupplement->id;
                }
            }

            // Validasi format reminder_time "H:i" jika ada
            if ($reminderTime !== null && !preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', (string) $reminderTime)) {
                $reminderTime = null;
            }

            $log = SupplementLog::create([
                'user_id'       => $user->id,
                'supplement_id' => $supplementId,
                'nama_suplemen' => $namaSuplemen,
                'komposisi'     => $komposisi,
                'kemasan'       => $kemasan,
                'aturan_pakai'  => $aturanPakai,
                'gambar'        => null,
                'source'        => $source ?: 'Halodoc',
                'reminder_time' => $reminderTime,
                'is_taken'      => $isTaken,
            ]);

            return [
                'type' => 'supplement_log',
                'data' => $log,
            ];
        }

        throw new \InvalidArgumentException("Tipe action tidak dikenali: {$type}");
    }
}