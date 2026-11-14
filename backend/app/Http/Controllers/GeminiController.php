<?php

namespace App\Http\Controllers;

use App\Models\Food;
use App\Models\FoodLog;
use App\Models\Supplement;
use App\Models\SupplementLog;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
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
     * Batas wajar untuk nilai gizi per entri food_log, dipakai sebagai
     * sanity-clamp terhadap output Gemini sebelum disimpan ke database
     * (baik ke food_logs maupun sebagai data master baru di foods).
     * Angka ini sengaja longgar (mis. porsi besar/kalori tinggi masih wajar
     * untuk beberapa makanan), tujuannya hanya mencegah nilai yang jelas
     * tidak masuk akal (mis. hasil halusinasi AI: kcal 99999, protein -50).
     */
    private const MAX_WEIGHT_G  = 3000;
    private const MAX_KCAL      = 3000;
    private const MAX_MACRO_G   = 500; // untuk protein/carbs/fat per entri

    /**
     * Kata kunci nama makanan yang HARUS diblokir dari pencatatan walau lolos
     * threshold nilai gizi (mis. mie ayam/bakso kuah bisa punya kalori & lemak
     * "normal" karena porsi daging, padahal tinggi sodium/MSG yang tidak
     * terekam di kolom gizi kita). Pengecekan berbasis substring nama makanan,
     * case-insensitive. Ini pelengkap isLikelyUnhealthyFood(), bukan pengganti.
     */
    private const UNHEALTHY_NAME_KEYWORDS = [
        'gorengan', 'goreng tepung', 'mie instan', 'mi instan', 'mie ayam',
        'mi ayam', 'bakso', 'sosis', 'nugget', 'dendeng', 'martabak manis',
        'donat', 'fast food', 'junk food',
    ];

    /**
     * System instruction yang mengatur perilaku & format output Gemini.
     * Gemini WAJIB membalas dalam format JSON sesuai skema di bawah.
     */
    private function buildSystemInstruction(): string
{
    return <<<TEXT
    Kamu adalah asisten kesehatan untuk aplikasi Ibusehat, khusus untuk perempuan. Tugasmu
    membantu pengguna dalam berbagai topik kesehatan perempuan, termasuk:
    - Pencatatan makanan dan suplemen ke dalam log harian
    - Rekomendasi makanan sehat dan pola makan bergizi
    - Olahraga dan aktivitas fisik yang cocok untuk perempuan
    - Perawatan kulit (skincare) setelah melahirkan, stretch mark, dan perubahan tubuh pasca persalinan
    - Kesehatan reproduksi dan penyakit yang umum dialami perempuan (PCOS, anemia, osteoporosis, dll)
    - Pemulihan pasca melahirkan (ASI, nutrisi ibu menyusui, baby blues, dll)
    - Suplemen dan pengobatan yang aman untuk perempuan

    Jawab pertanyaan kesehatan dengan ramah, informatif, dan berbasis pengetahuan medis umum.
    Selalu ingatkan pengguna untuk berkonsultasi dengan dokter untuk kondisi yang serius.
    Untuk pencatatan makanan dan suplemen, ikuti ATURAN UTAMA di bawah.

    ATURAN UTAMA:
    1. Jika pengguna menyebutkan makanan/suplemen yang sudah mereka konsumsi, tanyakan apakah
    mereka ingin mencatatnya ke log (kecuali poin 4).
    2. JANGAN catat apapun ke log sebelum pengguna memberi konfirmasi eksplisit ("ya", "boleh",
    "catat", dsb) pada giliran percakapan berikutnya.
    3. Setelah pengguna konfirmasi, isi field "action" dengan data lengkap sesuai skema di bawah.
    4. Jika makanan yang disebut tergolong kurang sehat / olahan berat / junk food, JANGAN
    tawarkan pencatatan sama sekali. Cukup tanggapi secara ramah/edukatif tanpa menyinggung
    pencatatan log, dan field "action" harus null. Kategori yang TIDAK BOLEH dicatat (contoh,
    bukan daftar lengkap — gunakan penilaian umummu untuk kasus serupa yang tidak disebut di
    sini):
       - Gorengan (segala jenis, termasuk gorengan tepung tebal)
       - Minuman bersoda / minuman manis kemasan / minuman berenergi
       - Fast food / makanan cepat saji ultra-proses
       - Mie instan, mie ayam, bakso kuah dengan kaldu tinggi MSG/sodium
       - Makanan olahan tinggi natrium/pengawet (sosis, nugget, dendeng kemasan)
       - Makanan tinggi gula tambahan (kue manis, donat, martabak manis, dll)
    JIKA RAGU apakah suatu makanan tergolong sehat atau tidak, ANGGAP TIDAK SEHAT dan jangan
    tawarkan pencatatan. Lebih baik konservatif daripada salah catat makanan tidak sehat.
    5. Untuk estimasi gizi (kalori, protein, karbohidrat, lemak), gunakan data referensi yang
    diberikan dalam "context_data" jika tersedia (artinya nama makanan cocok dengan database).
    Jika tidak ada referensi yang cocok dan makanan tergolong sehat, estimasikan sendiri nilai
    gizinya secara wajar berdasarkan pengetahuanmu per porsi yang disebutkan pengguna (default
    100g jika tidak disebutkan).
    Untuk SUPLEMEN: context_data tidak wajib ada. Yang disimpan ke database untuk suplemen
    BUKAN nilai gizi/kalori, melainkan informasi produk berikut:
    - nama_suplemen : nama produk (mis. "Renovit", "Blackmores Vitamin C") — WAJIB
    - komposisi     : kandungan produk (mis. "Vitamin C 500mg, Zinc 10mg") — WAJIB, gunakan
                      pengetahuanmu tentang produk tersebut. Jika benar-benar tidak tahu,
                      JANGAN tawarkan pencatatan, tapi minta user menyebutkannya terlebih dahulu.
    - kemasan       : bentuk kemasan (mis. "Botol 30 tablet", "Strip 10 kapsul") — WAJIB,
                      gunakan pengetahuanmu. Jika tidak tahu, minta user menyebutkannya.
    - aturan_pakai  : aturan konsumsi (mis. "1x sehari setelah makan") — isi jika tahu,
                      boleh null jika tidak tahu.
    Pastikan kamu tahu komposisi dan kemasan sebelum menawarkan pencatatan suplemen.
    Set new_master_data: true jika suplemen tidak ada di context_data.
    6. Field "type" pada action: "food_log" untuk catatan makanan, "supplement_log" untuk
    suplemen.
    7. Field "new_master_data" diisi true HANYA jika data makanan/suplemen tersebut TIDAK
    ditemukan referensinya di context_data DAN kamu melakukan estimasi sendiri, sehingga
    Laravel akan menambahkannya sebagai data master baru juga. Jika referensi ditemukan di
    context_data, set false.
    8. Field "source" pada supplement_log WAJIB diisi dengan nama sumber informasi yang
    benar-benar kamu gunakan (mis. "Halodoc", "K24Klik", "BPOM", "Situs resmi [nama
    produk]"). Jika data berasal dari context_data (database internal), isi dengan
    "Database Ibusehat". Jika suplemen TIDAK ditemukan di context_data dan kamu
    mengestimasi sendiri, isi dengan sumber yang kamu gunakan sebagai referensi
    (mis. "Halodoc", "K24Klik", "BPOM", "Alodokter") — JANGAN isi "Database Ibusehat" jika
    data bukan dari context_data.
    9. Jika context_data berisi suplemen dengan nama yang BERBEDA dari yang disebutkan
    pengguna, ABAIKAN data tersebut dan gunakan pengetahuanmu sendiri. Jangan 
    pernah mencatat suplemen dengan nama yang tidak persis disebutkan pengguna.

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
        "source": "nama sumber asli, mis. 'Halodoc', 'K24Klik', 'BPOM', atau situs resmi produk",
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
            // Catatan: history.*.text sengaja dibatasi juga (bukan cuma 'prompt'),
            // supaya client tidak bisa mengirim history super panjang untuk
            // memboroskan token/biaya API Gemini di setiap request berikutnya.
            'history.*.text' => ['required_with:history', 'string', 'max:2000'],
        ]);

        // PENTING: jangan panggil env() langsung di sini. Setelah
        // `php artisan config:cache` dijalankan di production, env() di luar
        // file config/*.php akan selalu mengembalikan null. Pastikan
        // config/services.php punya entri:
        //   'gemini' => ['key' => env('GEMINI_API_KEY')],
        $apiKey = config('services.gemini.key');

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
                // UBAH v1 MENJADI v1beta DI SINI
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key={$apiKey}",
                [
                    'contents' => $contents,
                    'generationConfig' => [ // Tetap gunakan camelCase
                        'responseMimeType' => 'application/json', 
                        'temperature' => 0.2,
                    ]
                ]
            );

            if (!$response->successful()) {
                Log::error('Gemini API error', ['status' => $response->status(), 'body' => $response->body()]);

                // Jangan teruskan detail body/response Gemini mentah-mentah ke
                // client (bisa memuat info internal yang tidak perlu terekspos).
                // Simpan detailnya hanya di log server.
                return response()->json([
                    'success' => false,
                    'message' => 'Gagal mendapatkan respon dari AI.',
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

            // Guard tambahan: JANGAN PERNAH percaya Gemini soal "user sudah konfirmasi".
            // System instruction melarang mencatat tanpa konfirmasi eksplisit, tapi LLM
            // kadang tetap mengisi "action" pada giliran yang sama saat user baru
            // menyebut makanan/suplemen (belum benar-benar bilang "ya"/"catat"). Maka di
            // backend kita cek ulang: action hanya diproses jika pesan TERBARU dari user
            // (bukan reply Gemini) mengandung kata konfirmasi eksplisit DAN tidak ada
            // negasi (lihat isExplicitConfirmation()).
            if (is_array($action) && !empty($action['type']) && !$this->isExplicitConfirmation($userPrompt)) {
                Log::info('Action dari Gemini ditolak: tidak ada konfirmasi eksplisit pada giliran ini', [
                    'user_prompt' => $userPrompt,
                    'action'      => $action,
                ]);

                $action = null;
                $reply  = $this->buildPendingConfirmationReply($parsed);
            }

            // 4. Jika ada action terkonfirmasi, simpan ke database
            if (is_array($action) && !empty($action['type'])) {
                // Guard kedua khusus food_log: walau Gemini meloloskan, cek ulang
                // berdasarkan nilai gizi & nama makanan agar konsisten meski prompt
                // "kebobolan" untuk kasus makanan ambigu (mis. mie ayam, bakso, dsb).
                if ($action['type'] === 'food_log' && $this->isLikelyUnhealthyFood($action['food_log'] ?? [])) {
                    $namaMakanan = (string) ($action['food_log']['nama_makanan'] ?? 'makanan ini');

                    Log::info('Food log ditolak oleh guard gizi/kata kunci backend', [
                        'nama_makanan' => $namaMakanan,
                        'nutrisi'      => $action['food_log'] ?? [],
                    ]);

                    $action = null;
                    $reply = "Hmm, {$namaMakanan} termasuk makanan yang kurang disarankan untuk pola makan sehat, karena cenderung tinggi kalori/lemak atau rendah nutrisi penting. Yuk coba pilih menu yang lebih sehat untuk dicatat di log harian kamu \u{1F60A}";
                } else {
                    try {
                        $saved = $this->handleAction($user, $action);
                    } catch (\Exception $e) {
                        Log::error('Gagal menyimpan action AI', [
                            'error'  => $e->getMessage(),
                            'action' => $action,
                        ]);
                        $saveError = 'Gagal menyimpan catatan ke database.';
                        $reply = 'Maaf, terjadi kesalahan saat menyimpan catatan. Coba lagi ya!';
                    }
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
     * Konversi nilai menjadi string trim, atau null jika kosong/tidak ada.
     * Dipakai untuk field nullable (komposisi, kemasan, aturan_pakai) agar
     * "belum diketahui" tersimpan sebagai null, bukan string kosong.
     */
    private function nullableString(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $trimmed = trim((string) $value);

        return $trimmed === '' ? null : $trimmed;
    }

    /**
     * Sanitasi field "source": trim, batasi panjang (anti garbage/abuse dari AI),
     * dan strip karakter HTML/tag jika ada yang nyelip dari hasil grounding.
     */
    private function sanitizeSource(?string $value): ?string
    {
        $clean = $this->nullableString($value);

        if ($clean === null) {
            return null;
        }

        $clean = strip_tags($clean);
        $clean = mb_substr($clean, 0, 100); // jaga-jaga, kolom string biasanya varchar(255)

        return $clean;
    }

    /**
     * Clamp nilai numerik gizi ke rentang wajar [0, $max], dan bulatkan
     * ke 2 desimal. Dipakai sebagai sanity-check terakhir sebelum menyimpan
     * nilai dari Gemini ke database (mencegah nilai negatif atau ekstrem
     * akibat halusinasi model mencemari data master/log).
     */
    private function clampNutritionValue(mixed $value, float $max): float
    {
        $num = (float) $value;

        if (!is_finite($num) || $num < 0) {
            return 0.0;
        }

        return round(min($num, $max), 2);
    }

    /**
     * Cek apakah pesan TERBARU dari user (bukan reply Gemini) mengandung kata
     * konfirmasi eksplisit untuk mencatat ke log. Ini adalah guard backend yang
     * TIDAK bergantung pada kepatuhan Gemini terhadap system instruction —
     * walau Gemini mengisi "action", kita tetap menolaknya jika user belum
     * benar-benar bilang "ya"/"catat"/dsb pada giliran ini.
     *
     * PENTING: pengecekan negasi dilakukan LEBIH DULU dan bersifat konservatif.
     * Jika prompt mengandung kata negasi ("jangan", "tidak", dll), pesan
     * TIDAK dianggap sebagai konfirmasi eksplisit sama sekali — walau kata
     * seperti "catat" ikut muncul dalam kalimat yang sama (mis. "jangan catat
     * ya", "tidak usah dicatat"). Lebih baik minta user konfirmasi ulang
     * daripada salah menyimpan data karena regex kata tunggal.
     */
    private function isExplicitConfirmation(string $prompt): bool
    {
        $normalized = mb_strtolower(trim($prompt));

        $negationPattern = '/\b(jangan|tidak|tdk|nggak|ga|gak|enggak|engga|belum|batal|batalkan|jgn)\b/u';

        if (preg_match($negationPattern, $normalized)) {
            return false;
        }

        // Kata/frasa konfirmasi eksplisit (boleh ditambah sesuai kebutuhan produk).
        // Gunakan word-boundary agar tidak salah match substring tak terduga.
        $pattern = '/\b(ya|iya|yaa+|boleh|catat|catet|catatkan|simpan|oke|ok|okay|'
            . 'siap|gas|setuju|lanjut|silakan|silahkan|yes|sip)\b/u';

        return (bool) preg_match($pattern, $normalized);
    }

    /**
     * Bangun balasan fallback saat action dari Gemini ditolak karena belum ada
     * konfirmasi eksplisit. Pakai reply asli dari Gemini jika sepertinya memang
     * berupa pertanyaan konfirmasi (bukan klaim "sudah dicatat"), supaya tetap
     * terasa natural; kalau tidak, ganti dengan teks aman generik.
     */
    private function buildPendingConfirmationReply(array $parsed): string
    {
        $originalReply = (string) ($parsed['reply'] ?? '');

        // Jika reply asli Gemini sudah mengklaim "tersimpan/tercatat" padahal kita
        // baru saja membatalkan action-nya, JANGAN tampilkan klaim palsu itu ke user.
        $claimsSaved = (bool) preg_match('/\b(sudah (saya )?catat|tersimpan|tercatat)\b/iu', $originalReply);

        if ($originalReply !== '' && !$claimsSaved) {
            return $originalReply;
        }

        return 'Boleh saya catat ke log harian kamu? Balas "ya" atau "catat" untuk konfirmasi ya 😊';
    }

    /**
     * Cari URL gambar produk suplemen via scraping endpoint pencarian gambar
     * DuckDuckGo (bukan API resmi — DDG tidak menyediakan API gambar publik
     * gratis). CATATAN KERAPUHAN: pendekatan ini bergantung pada struktur
     * internal halaman DDG (token "vqd", endpoint i.js) yang bisa berubah
     * sewaktu-waktu tanpa pemberitahuan dan berpotensi melanggar ToS DDG.
     * Untuk produksi jangka panjang, sebaiknya diganti dengan API resmi
     * (mis. Google Custom Search JSON API, Bing Image Search, atau upload
     * gambar manual oleh admin). Fungsi ini sengaja fail-safe: gambar bukan
     * field wajib, jadi kegagalan di sini tidak boleh menggagalkan penyimpanan
     * log.
     */
    private function fetchSupplementImageUrl(string $namaSuplemen): ?string
    {
        try {
            $query = $namaSuplemen . 'suplemen';

            $init = Http::timeout(10)
                ->withHeaders(['User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'])
                ->get('https://duckduckgo.com/', ['q' => $query, 'iax' => 'images', 'ia' => 'images']);

            if (!$init->successful()) return null;

            preg_match('/vqd=([\d-]+)/', $init->body(), $matches);
            $vqd = $matches[1] ?? null;

            if (!$vqd) return null;

            $response = Http::timeout(10)
                ->withHeaders([
                    'User-Agent'      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
                    'Referer'         => 'https://duckduckgo.com/',
                    'Accept'          => 'application/json, text/javascript, */*; q=0.01',
                    'Accept-Language' => 'en-US,en;q=0.9',
                    'X-Requested-With'=> 'XMLHttpRequest',
                    'sec-ch-ua'       => '"Google Chrome";v="125", "Chromium";v="125"',
                    'sec-ch-ua-mobile'=> '?0',
                    'sec-fetch-dest'  => 'empty',
                    'sec-fetch-mode'  => 'cors',
                    'sec-fetch-site'  => 'same-origin',
                    'Cookie'          => $init->header('Set-Cookie') ?? '',
                ])
                ->get('https://duckduckgo.com/i.js', [
                    'q'   => $query,
                    'vqd' => $vqd,
                    'f'   => ',,,,,',
                    'p'   => '1',
                ]);

            if (!$response->successful()) return null;

            $results  = $response->json('results') ?? [];
            $imageUrl = $results[0]['image'] ?? null;

            if (!$imageUrl || !filter_var($imageUrl, FILTER_VALIDATE_URL)) {
                return null;
            }

            // Hanya terima http/https (bukan mis. "javascript:" atau skema aneh lain
            // yang lolos filter_var tapi tidak aman ditampilkan sebagai <img src>).
            $scheme = parse_url($imageUrl, PHP_URL_SCHEME);
            if (!in_array($scheme, ['http', 'https'], true)) {
                return null;
            }

            return $imageUrl;

        } catch (\Exception $e) {
            Log::warning('Exception saat fetch gambar suplemen (DDG)', [
                'nama_suplemen' => $namaSuplemen,
                'error'         => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Guard kedua di backend untuk menilai apakah suatu food_log "kemungkinan
     * tidak sehat", dengan dua lapis pengecekan:
     *
     * 1) Berdasarkan nama makanan vs daftar kata kunci (UNHEALTHY_NAME_KEYWORDS)
     *    — menutup celah makanan seperti mie ayam/bakso yang nilai gizinya bisa
     *    "normal" (karena ada dagingnya) padahal sebenarnya tinggi sodium/MSG
     *    yang tidak terekam di kolom gizi kita.
     * 2) Berdasarkan nilai gizi yang diestimasi Gemini, dinormalisasi per 100g
     *    agar adil terhadap porsi (weight) yang berbeda-beda.
     *
     * Ini BUKAN pengganti prompt, melainkan pengaman tambahan agar kasus yang
     * "kebobolan" dari prompt tetap tertangkap tanpa perlu mendaftar nama
     * makanan satu per satu secara lengkap.
     *
     * Threshold per 100g (boleh dikalibrasi ulang sesuai kebutuhan produk):
     * - Kalori > 280 kkal DAN lemak > 15g DAN protein < 10g -> sinyal tinggi
     *   kalori/lemak tapi rendah nilai gizi (khas gorengan/makanan berminyak).
     * - Karbohidrat > 35g DAN protein < 5g -> sinyal karbo olahan tinggi tanpa
     *   nutrisi pendukung (khas mie/kue/tepung olahan).
     */
    private function isLikelyUnhealthyFood(array $foodLog): bool
    {
        $namaMakanan = mb_strtolower((string) ($foodLog['nama_makanan'] ?? ''));

        if ($namaMakanan !== '') {
            foreach (self::UNHEALTHY_NAME_KEYWORDS as $keyword) {
                if (str_contains($namaMakanan, $keyword)) {
                    return true;
                }
            }
        }

        $weight = (float) ($foodLog['weight'] ?? 0);

        if ($weight <= 0) {
            return false; // data tidak lengkap, jangan blokir berdasarkan tebakan
        }

        $factor  = 100 / $weight; // faktor normalisasi ke per 100g
        $kcal    = (float) ($foodLog['kcal'] ?? 0) * $factor;
        $fat     = (float) ($foodLog['fat'] ?? 0) * $factor;
        $carbs   = (float) ($foodLog['carbs'] ?? 0) * $factor;
        $protein = (float) ($foodLog['protein'] ?? 0) * $factor;

        if ($kcal > 280 && $fat > 15 && $protein < 10) {
            return true;
        }

        if ($carbs > 35 && $protein < 5) {
            return true;
        }

        return false;
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
            ->filter(fn($w) => mb_strlen($w) >= 3)
            ->unique()
            ->values();

        if ($words->isEmpty()) {
            return ['foods' => [], 'supplements' => []];
        }

        $foodQuery = Food::query();
        $supplementQuery = Supplement::query();

        // Catatan: ambang mb_strlen($w) >= 4 di bawah ini dipakai untuk KEDUA
        // query (food & supplement), bukan cuma supplement — tujuannya sama:
        // menghindari kata umum pendek (mis. "plus", "food") terlalu dominan
        // sebagai kriteria pencarian LIKE.
        $foodQuery->where(function ($q) use ($words) {
            foreach ($words as $w) {
                if (mb_strlen($w) >= 4) {
                    $q->orWhere('name', 'like', '%' . $w . '%');
                }
            }
        });

        $supplementQuery->where(function ($q) use ($words) {
            foreach ($words as $w) {
                if (mb_strlen($w) >= 4) {
                    $q->orWhere('name', 'like', '%' . $w . '%');
                }
            }
        });

        $foods = $foodQuery->limit(5)->get([
            'id',
            'name',
            'category',
            'calories',
            'fat',
            'carbohydrate',
            'protein',
        ]);

        $supplements = $supplementQuery->limit(5)->get([
            'id',
            'name',
            'composition',
            'packaging',
            'usage_rule',
        ]);

        return [
            'foods' => $foods->map(fn($f) => [
                'id'           => $f->id,
                'nama_makanan' => $f->name,
                'kategori'     => $f->category,
                'kalori_kkal'  => $f->calories,
                'lemak_g'      => $f->fat,
                'karbo_g'      => $f->carbohydrate,
                'protein_g'    => $f->protein,
            ])->all(),
            'supplements' => $supplements->map(fn($s) => [
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

        // Riwayat percakapan sebelumnya (sliding window). Catatan keamanan:
        // history berasal dari client dan TIDAK dianggap tepercaya sebagai
        // fakta ("model" turn di sini hanyalah teks konteks percakapan, bukan
        // sumber kebenaran). Guard di ask() (isExplicitConfirmation,
        // isLikelyUnhealthyFood, clampNutritionValue) tetap berjalan terlepas
        // dari apa isi history, sehingga history yang dipalsukan tidak bisa
        // memaksa data tersimpan ke database tanpa lolos guard tersebut.
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
     * Bersihkan & decode JSON dari teks respons Gemini.
     *
     * Lebih toleran daripada versi sebelumnya karena saat grounding (google_search)
     * aktif, Gemini kadang menambahkan teks/markdown di luar objek JSON utama.
     * Strategi: 1) coba decode langsung, 2) kalau gagal, strip code fence,
     * 3) kalau masih gagal, ekstrak substring objek JSON terluar (dari '{' pertama
     * sampai '}' pasangannya, dihitung manual agar aman walau ada kurung kurawal
     * di dalam string/komposisi), baru decode itu.
     *
     * Mengembalikan null jika semua strategi gagal, dan selalu memastikan key
     * "reply" & "action" ada di hasil akhir (default aman) supaya kode pemanggil
     * tidak perlu null-check berlapis.
     */
    private function parseAiJson(string $rawText): ?array
    {
        $text = trim($rawText);

        // Percobaan 1: decode langsung (kasus paling umum & paling murah)
        $decoded = json_decode($text, true);

        // Percobaan 2: bersihkan markdown code fence (```json ... ``` / ``` ... ```)
        if (!is_array($decoded)) {
            $stripped = preg_replace('/^```[a-zA-Z]*\s*/', '', $text);
            $stripped = preg_replace('/```\s*$/', '', $stripped ?? $text);
            $stripped = trim($stripped ?? '');

            if ($stripped !== '') {
                $decoded = json_decode($stripped, true);
            }
        }

        // Percobaan 3: ekstrak objek JSON terluar dari dalam teks bebas
        // (mis. ada kalimat pembuka/penutup yang terselip dari hasil grounding)
        if (!is_array($decoded)) {
            $extracted = $this->extractOutermostJsonObject($text);

            if ($extracted !== null) {
                $decoded = json_decode($extracted, true);
            }
        }

        if (!is_array($decoded)) {
            Log::warning('Gagal parsing JSON dari Gemini', [
                'raw_text_preview' => mb_substr($rawText, 0, 500),
            ]);

            return null;
        }

        // Normalisasi struktur minimum supaya pemanggil tidak perlu null-check berlapis
        if (!array_key_exists('reply', $decoded)) {
            $decoded['reply'] = 'Maaf, saya tidak mendapatkan jawaban.';
        }

        if (!array_key_exists('action', $decoded)) {
            $decoded['action'] = null;
        }

        return $decoded;
    }

    /**
     * Cari substring objek JSON terluar (dari '{' pertama hingga '}' pasangannya)
     * dengan menghitung kedalaman kurung kurawal secara manual, sambil
     * memperhitungkan string literal (termasuk escape char di dalamnya) agar
     * kurung kurawal di dalam teks/komposisi tidak ikut dihitung.
     *
     * Mengembalikan null jika tidak ditemukan pasangan kurung kurawal yang valid.
     */
    private function extractOutermostJsonObject(string $text): ?string
    {
        $start = strpos($text, '{');

        if ($start === false) {
            return null;
        }

        $depth     = 0;
        $inString  = false;
        $escaped   = false;
        $length    = strlen($text);

        for ($i = $start; $i < $length; $i++) {
            $char = $text[$i];

            if ($inString) {
                if ($escaped) {
                    $escaped = false;
                } elseif ($char === '\\') {
                    $escaped = true;
                } elseif ($char === '"') {
                    $inString = false;
                }

                continue;
            }

            if ($char === '"') {
                $inString = true;
                continue;
            }

            if ($char === '{') {
                $depth++;
            } elseif ($char === '}') {
                $depth--;

                if ($depth === 0) {
                    return substr($text, $start, $i - $start + 1);
                }
            }
        }

        return null; // kurung kurawal tidak seimbang, kemungkinan respons terpotong
    }

    /**
     * Eksekusi penyimpanan ke database berdasarkan "action" dari AI.
     * Mengembalikan ringkasan data yang tersimpan.
     */
    private function handleAction(User $user, array $action): array
    {
        $type          = $action['type'] ?? null;
        $newMasterData = (bool) ($action['new_master_data'] ?? false);

        if ($type === 'food_log') {
            $data = $action['food_log'] ?? [];

            $namaMakanan = trim((string) ($data['nama_makanan'] ?? ''));
            $makananId   = $data['makanan_id'] ?? null;

            // Sanity-clamp nilai gizi dari Gemini sebelum disimpan, supaya
            // nilai negatif/ekstrem (halusinasi model) tidak mencemari
            // food_logs maupun data master baru di tabel foods.
            $weight      = $this->clampNutritionValue($data['weight'] ?? 0, self::MAX_WEIGHT_G);
            $kcal        = $this->clampNutritionValue($data['kcal'] ?? 0, self::MAX_KCAL);
            $protein     = $this->clampNutritionValue($data['protein'] ?? 0, self::MAX_MACRO_G);
            $carbs       = $this->clampNutritionValue($data['carbs'] ?? 0, self::MAX_MACRO_G);
            $fat         = $this->clampNutritionValue($data['fat'] ?? 0, self::MAX_MACRO_G);
            $category    = (string) ($data['category'] ?? '');

            if ($namaMakanan === '') {
                throw new \InvalidArgumentException('nama_makanan kosong pada action food_log');
            }

            // Tambahkan ke food_nutrition sebagai data master baru jika diminta.
            // Pakai firstOrCreate (dibungkus transaction) untuk mengurangi
            // celah race condition dibanding where()->first() + create()
            // terpisah. Perlindungan penuh idealnya juga didukung UNIQUE
            // index pada kolom foods.name di level database.
            if ($newMasterData && empty($makananId)) {
                $food = DB::transaction(function () use ($namaMakanan, $category, $kcal, $fat, $carbs, $protein) {
                    return Food::firstOrCreate(
                        ['name' => $namaMakanan],
                        [
                            'category'     => $category ?: 'Lainnya',
                            'calories'     => $kcal,
                            'fat'          => $fat,
                            'carbohydrate' => $carbs,
                            'protein'      => $protein,
                        ]
                    );
                });

                $makananId = $food->id;
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

            $namaSuplemen = trim((string) ($data['nama_suplemen'] ?? ''));
            $supplementId = $data['supplement_id'] ?? null;
            $komposisi    = $this->nullableString($data['komposisi'] ?? null);
            $kemasan      = $this->nullableString($data['kemasan'] ?? null);
            $aturanPakai  = $this->nullableString($data['aturan_pakai'] ?? null);
            $source = $this->sanitizeSource($data['source'] ?? null);
            $reminderTime = $data['reminder_time'] ?? null;
            $isTaken      = (bool) ($data['is_taken'] ?? false);

            if ($namaSuplemen === '') {
                throw new \InvalidArgumentException('nama_suplemen kosong pada action supplement_log');
            }

            $supplementImage = null;

            if (!empty($supplementId)) {
                // supplement_id sudah diketahui (mis. dari context_data) ->
                // ambil gambar yang sudah di-cache di master, jangan cari ulang.
                $supplementImage = Supplement::find($supplementId)?->image;
            } else {
                // supplement_id belum diketahui -> cari/buat master data.
                // Dibungkus transaction + firstOrCreate untuk mengurangi
                // race condition dibanding where()->first() + create() manual.
                // Pencarian gambar (fetchSupplementImageUrl) SENGAJA dilakukan
                // DI LUAR transaction karena ia melakukan HTTP call eksternal
                // (jangan menahan koneksi/transaksi DB selama menunggu network).
                $existing = Supplement::where('name', $namaSuplemen)->first();

                if ($existing) {
                    $supplementId    = $existing->id;
                    $supplementImage = $existing->image;
                } else {
                    // Cari gambar produk HANYA saat suplemen benar-benar baru,
                    // supaya tidak boros kuota/scraping untuk suplemen yang
                    // sudah pernah dicatat sebelumnya.
                    $supplementImage = $this->fetchSupplementImageUrl($namaSuplemen);

                    $newSupplement = DB::transaction(function () use ($namaSuplemen, $komposisi, $kemasan, $aturanPakai, $supplementImage) {
                        return Supplement::firstOrCreate(
                            ['name' => $namaSuplemen],
                            [
                                'composition' => $komposisi,
                                'packaging'   => $kemasan,
                                'usage_rule'  => $aturanPakai,
                                'image'       => $supplementImage,
                            ]
                        );
                    });

                    $supplementId    = $newSupplement->id;
                    $supplementImage = $newSupplement->image;
                }
            }

            // Validasi format reminder_time "H:i" jika ada. Jika tidak valid,
            // diamkan sebagai null (bukan field kritikal), tapi tetap dicatat
            // di log supaya kelihatan kalau Gemini sering mengirim format aneh.
            if ($reminderTime !== null && !preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', (string) $reminderTime)) {
                Log::info('reminder_time dari Gemini tidak valid, diabaikan', [
                    'nama_suplemen'        => $namaSuplemen,
                    'reminder_time_mentah' => $reminderTime,
                ]);
                $reminderTime = null;
            }

            $log = SupplementLog::create([
                'user_id'       => $user->id,
                'supplement_id' => $supplementId,
                'nama_suplemen' => $namaSuplemen,
                'komposisi'     => $komposisi,
                'kemasan'       => $kemasan,
                'aturan_pakai'  => $aturanPakai,
                'gambar'        => $supplementImage,
                'source'        => $source,
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