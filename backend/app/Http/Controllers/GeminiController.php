<?php

namespace App\Http\Controllers;

use App\Models\ChatMessage;
use App\Models\ChatSession;
use App\Models\Food;
use App\Models\FoodLog;
use App\Models\Supplement;
use App\Models\SupplementLog;
use App\Models\User;
use App\Services\Chat\ChatMemory;
use App\Services\Chat\ChatSystemPrompt;
use App\Services\Chat\EmergencyDetector;
use App\Services\Chat\GeminiClient;
use App\Services\Chat\HealthContextBuilder;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

use function Illuminate\Support\defer;

class GeminiController extends Controller
{
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

    /** Batas panjang balasan AI yang diteruskan ke client. */
    private const MAX_REPLY_CHARS = 4000;

    /**
     * Kata kunci nama makanan/minuman yang HARUS diblokir dari pencatatan walau
     * lolos threshold nilai gizi (mis. mie ayam/bakso kuah bisa punya kalori &
     * lemak "normal" karena porsi daging, padahal tinggi sodium/MSG yang tidak
     * terekam di kolom gizi kita). Dicocokkan sebagai kata utuh pada nama
     * makanan, case-insensitive. Ini pelengkap isLikelyUnhealthyFood(), bukan
     * pengganti, dan tidak bergantung pada kepatuhan AI terhadap system prompt.
     */
    private const UNHEALTHY_NAME_KEYWORDS = [
        // gorengan & makanan bertepung digoreng
        'gorengan', 'goreng tepung', 'bakwan', 'cireng', 'kentang goreng',
        'french fries', 'fried chicken', 'ayam geprek',
        // mi & kuah tinggi natrium
        'mie instan', 'mi instan', 'indomie', 'mie ayam', 'mi ayam', 'bakso', 'seblak',
        // olahan tinggi natrium/pengawet
        'sosis', 'nugget', 'dendeng', 'kornet',
        // fast food
        'fast food', 'junk food', 'burger', 'pizza', 'hot dog', 'kebab',
        // tinggi gula tambahan
        'martabak manis', 'donat', 'es krim', 'ice cream', 'permen', 'brownies',
        'kue tart', 'kental manis',
        // minuman manis/bersoda/berenergi
        'soda', 'bersoda', 'cola', 'minuman berenergi', 'minuman energi',
        'minuman manis', 'boba', 'bubble tea', 'sirup',
        // camilan kemasan asin
        'keripik', 'kerupuk', 'chiki',
        // alkohol
        'alkohol', 'bir', 'wine', 'minuman keras',
    ];

    public function __construct(
        private GeminiClient $gemini,
        private ChatMemory $memory,
        private ChatSystemPrompt $systemPrompt,
        private HealthContextBuilder $healthContext,
        private EmergencyDetector $emergency,
    ) {
    }

    /**
     * POST /api/gemini/chat
     *
     * Body:
     *   - prompt     : string (wajib) - pesan terbaru dari user
     *   - session_id : int (opsional) - sesi chat yang dilanjutkan. Kosong =
     *                  mulai sesi baru; id sesi dikembalikan di data.session_id.
     *
     * Riwayat percakapan TIDAK lagi dikirim client: backend menyimpannya per
     * user dan per sesi (ChatMemory), lalu mengirim ke model hanya 10–20 pesan
     * terakhir + ringkasan pesan lama + konteks Data Kesehatan (tanpa identitas).
     *
     * Route ini dilindungi middleware:
     *   - auth:sanctum            -> wajib login
     *   - throttle:chat           -> anti-spam per menit (lihat AppServiceProvider)
     *   - chat.access             -> wajib data kesehatan lengkap + batas harian
     */
    public function ask(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'prompt'     => ['required', 'string', 'max:1000'],
            'session_id' => ['nullable', 'integer', 'min:1'],
            // Diterima agar klien lama tidak error, tetapi diabaikan: riwayat
            // dari client tidak dipercaya dan tidak dipakai lagi.
            'history'    => ['nullable', 'array'],
        ]);

        $user       = $request->user();
        $userPrompt = trim($validated['prompt']);

        $session = $this->memory->resolveSession($user, $validated['session_id'] ?? null);

        if ($session === null) {
            return response()->json([
                'success' => false,
                'message' => 'Sesi percakapan tidak ditemukan.',
                'code'    => 'SESSION_NOT_FOUND',
            ], 404);
        }

        $quotaMeta = [
            'used'  => $request->attributes->get('chat_quota_used'),
            'limit' => $request->attributes->get('chat_quota_limit'),
        ];

        // Pengaman darurat di BACKEND: tidak bergantung pada AI. Bila pesan
        // memuat tanda bahaya, pesan darurat baku selalu ada di awal balasan.
        $emergencyCategory = $this->emergency->detect($userPrompt);
        $emergencyMessage  = $emergencyCategory !== null
            ? $this->emergency->message($emergencyCategory)
            : null;

        // Kuota habis atau AI belum dikonfigurasi: pesan darurat tetap sampai.
        $aiUnavailable = !$this->gemini->isConfigured()
            || (bool) $request->attributes->get('chat_quota_exhausted', false);

        if ($emergencyMessage !== null && $aiUnavailable) {
            return $this->respond($session, $userPrompt, $emergencyMessage, null, null, $emergencyCategory, $quotaMeta);
        }

        if (!$this->gemini->isConfigured()) {
            return response()->json([
                'success' => false,
                'message' => 'API Key belum dikonfigurasi di server.',
            ], 500);
        }

        try {
            // 1. Referensi gizi/suplemen dari database berdasarkan kata di prompt.
            //    Pada giliran konfirmasi ("ya, catat") nama makanan/suplemennya
            //    ada di pesan pengguna SEBELUMNYA, jadi pesan itu ikut dipakai
            //    supaya AI tetap menerima data katalognya saat mencatat.
            $lookupText = $userPrompt;

            if ($this->isExplicitConfirmation($userPrompt)) {
                $lookupText .= ' ' . (string) $this->memory->lastUserText($session);
            }

            $contextData = $this->buildContextData($lookupText);

            // 2. Ingatan: pesan terakhir sesi ini (dari server) + pesan baru.
            $turns   = $this->memory->recentTurns($session);
            $turns[] = [
                'role' => 'user',
                'text' => $userPrompt . "\n\ncontext_data: " . json_encode($contextData, JSON_UNESCAPED_UNICODE),
            ];

            // 3. System prompt + Data Kesehatan (tanpa identitas) + ringkasan.
            $system = $this->systemPrompt->build(
                $this->healthContext->lines($user),
                $session->summary,
                $emergencyCategory,
            );

            $result = $this->gemini->generate($system, $turns);

            if (!$result['ok']) {
                if ($emergencyMessage !== null) {
                    return $this->respond($session, $userPrompt, $emergencyMessage, null, null, $emergencyCategory, $quotaMeta);
                }

                if ($result['blocked']) {
                    return $this->respond(
                        $session,
                        $userPrompt,
                        'Maaf, aku tidak bisa menanggapi pesan itu. Coba tanyakan dengan cara lain, atau tanyakan hal lain seputar kesehatan ibu pasca melahirkan ya.',
                        null,
                        null,
                        null,
                        $quotaMeta,
                    );
                }

                // Kegagalan di sisi penyedia AI (termasuk batas laju Gemini)
                // selalu dilaporkan sebagai 503, supaya aplikasi tidak
                // mengiranya batas harian milik pengguna (429).
                return response()->json([
                    'success' => false,
                    'message' => 'IbuSehat AI sedang sibuk. Coba lagi sebentar lagi ya.',
                    'code'    => 'AI_UNAVAILABLE',
                ], 503);
            }

            // 4. Parsing JSON dari Gemini (bersihkan kemungkinan markdown fence)
            $parsed = $this->parseAiJson($result['text']);

            if ($parsed === null) {
                // Gagal parsing -> tampilkan teks mentah sebagai fallback, tanpa action
                $parsed = ['reply' => $result['text'], 'action' => null];
            }

            $reply  = is_string($parsed['reply'] ?? null) && trim($parsed['reply']) !== ''
                ? $parsed['reply']
                : 'Maaf, saya tidak mendapatkan jawaban.';
            $action = $parsed['action'] ?? null;

            $saved     = null;
            $saveError = null;

            // Saat darurat tidak ada pencatatan apa pun, apa pun kata model.
            if ($emergencyCategory !== null) {
                $action = null;
            }

            // Guard tambahan: JANGAN PERNAH percaya Gemini soal "user sudah konfirmasi".
            // System prompt melarang mencatat tanpa konfirmasi eksplisit, tapi LLM
            // kadang tetap mengisi "action" pada giliran yang sama saat user baru
            // menyebut makanan/suplemen (belum benar-benar bilang "ya"/"catat"). Maka di
            // backend kita cek ulang: action hanya diproses jika pesan TERBARU dari user
            // (bukan reply Gemini) mengandung kata konfirmasi eksplisit DAN tidak ada
            // negasi (lihat isExplicitConfirmation()).
            if (is_array($action) && !empty($action['type']) && !$this->isExplicitConfirmation($userPrompt)) {
                Log::info('Action dari Gemini ditolak: tidak ada konfirmasi eksplisit pada giliran ini', [
                    'action_type' => $action['type'],
                ]);

                $action = null;
                $reply  = $this->buildPendingConfirmationReply($parsed);
            }

            // 5. Jika ada action terkonfirmasi, simpan ke database
            if (is_array($action) && !empty($action['type'])) {
                // Guard kedua khusus food_log: walau Gemini meloloskan, cek ulang
                // berdasarkan nilai gizi & nama makanan agar konsisten meski prompt
                // "kebobolan" untuk kasus makanan ambigu (mis. mie ayam, bakso, dsb).
                if ($action['type'] === 'food_log' && $this->isLikelyUnhealthyFood($action['food_log'] ?? [])) {
                    $namaMakanan = $this->cleanName($action['food_log']['nama_makanan'] ?? '', 120) ?: 'makanan ini';

                    Log::info('Food log ditolak oleh guard gizi/kata kunci backend', [
                        'nama_makanan' => $namaMakanan,
                    ]);

                    $action = null;
                    $reply = "Hmm, {$namaMakanan} termasuk makanan yang kurang disarankan untuk pola makan sehat, karena cenderung tinggi kalori/lemak atau rendah nutrisi penting. Yuk coba pilih menu yang lebih sehat untuk dicatat di log harian kamu \u{1F60A}";
                } else {
                    try {
                        $saved = $this->handleAction($user, $action);
                    } catch (\DomainException $e) {
                        // Data belum cukup untuk dicatat (bukan error sistem):
                        // pesannya adalah permintaan ke pengguna.
                        $reply = $e->getMessage();
                    } catch (\Exception $e) {
                        Log::error('Gagal menyimpan action AI', [
                            'error'       => $e->getMessage(),
                            'action_type' => $action['type'],
                        ]);
                        $saveError = 'Gagal menyimpan catatan ke database.';
                        $reply = 'Maaf, terjadi kesalahan saat menyimpan catatan. Coba lagi ya!';
                    }
                }
            }

            $reply = $this->finalizeReply($reply, $saved !== null, $saveError !== null);

            if ($emergencyMessage !== null) {
                $reply = $emergencyMessage . "\n\n" . $reply;
            }

            return $this->respond($session, $userPrompt, $reply, $saved, $saveError, $emergencyCategory, $quotaMeta);
        } catch (\Throwable $e) {
            Log::error('Gemini Integration Error: ' . $e->getMessage());

            if ($emergencyMessage !== null) {
                return $this->respond($session, $userPrompt, $emergencyMessage, null, null, $emergencyCategory, $quotaMeta);
            }

            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan koneksi pada server backend.',
            ], 500);
        }
    }

    /**
     * Simpan pertukaran ke ingatan sesi, jadwalkan peringkasan, lalu balas.
     */
    private function respond(
        ChatSession $session,
        string $userPrompt,
        string $reply,
        ?array $saved,
        ?string $saveError,
        ?string $emergencyCategory,
        array $quotaMeta,
    ): JsonResponse {
        try {
            $this->memory->recordExchange(
                $session,
                $userPrompt,
                $reply,
                $emergencyCategory !== null ? ChatMessage::KIND_EMERGENCY : ChatMessage::KIND_CHAT,
            );

            // Peringkasan pesan lama dijalankan setelah respons terkirim,
            // supaya tidak menambah waktu tunggu pengguna.
            $memory = $this->memory;
            defer(fn () => $memory->summarizeIfNeeded($session));
        } catch (\Throwable $e) {
            // Gagal menyimpan ingatan tidak boleh menghilangkan balasan
            // (terutama pesan darurat) dari pengguna.
            Log::error('Gagal menyimpan riwayat chat', ['error' => $e->getMessage()]);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'reply'      => $reply,
                'saved'      => $saved,
                'save_error' => $saveError,
                'session_id' => $session->exists ? $session->id : null,
                'safety'     => $emergencyCategory !== null
                    ? ['level' => 'emergency', 'category' => $emergencyCategory]
                    : null,
            ],
            'meta' => ['quota' => $quotaMeta],
        ]);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /**
     * Rapikan balasan AI sebelum dikirim: batasi panjang, dan jangan biarkan
     * klaim "sudah dicatat" lolos bila backend sebenarnya tidak menyimpan apa pun.
     */
    private function finalizeReply(string $reply, bool $wasSaved, bool $hadSaveError): string
    {
        $reply = trim($reply);

        if (mb_strlen($reply) > self::MAX_REPLY_CHARS) {
            $reply = mb_substr($reply, 0, self::MAX_REPLY_CHARS) . '…';
        }

        if ($this->claimsSaved($reply) && !$wasSaved && !$hadSaveError) {
            // Balasan pendek yang isinya hanya klaim palsu diganti seluruhnya;
            // balasan panjang (ada isi lain yang berguna) cukup diberi catatan.
            if (mb_strlen($reply) <= 120) {
                return 'Belum aku catat ya. Mau aku simpan ke log harian kamu? '
                    . 'Balas "ya" atau "catat" untuk konfirmasi 😊';
            }

            $reply .= "\n\n_Catatan dari aplikasi: belum ada yang tersimpan ke log harian. "
                . 'Balas "catat" kalau kamu ingin aku menyimpannya._';
        }

        return $reply;
    }

    /**
     * Bersihkan nama dari AI sebelum disimpan/ditampilkan: buang tag HTML,
     * rapikan spasi, dan batasi panjang sesuai kolom database.
     */
    private function cleanName(mixed $value, int $maxLength): string
    {
        $clean = trim(preg_replace('/\s+/u', ' ', strip_tags((string) $value)) ?? '');

        return mb_substr($clean, 0, $maxLength);
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
     * True bila balasan AI mengklaim, sebagai dirinya sendiri, bahwa sesuatu
     * sudah dicatat/disimpan ("sudah aku catat", "berhasil disimpan").
     * Sengaja sempit supaya kalimat informatif biasa tidak ikut tertangkap.
     */
    private function claimsSaved(string $reply): bool
    {
        return (bool) preg_match(
            '/\b((sudah|telah)\s+(saya|aku|ku)\s*(catat|simpan)(kan)?|berhasil\s+(di|ku|aku\s+|saya\s+)?(catat|simpan)(kan)?)\b/iu',
            $reply,
        );
    }

    /**
     * Bangun balasan saat action dari Gemini ditolak karena belum ada
     * konfirmasi eksplisit. Bila balasan asli memang berupa tawaran, dipakai
     * apa adanya. Bila ia sudah mengklaim "tercatat" padahal action-nya baru
     * saja dibatalkan, klaim palsu itu diganti tawaran yang menyebut apa yang
     * akan dicatat, supaya pengguna tinggal membalas "ya".
     */
    private function buildPendingConfirmationReply(array $parsed): string
    {
        $originalReply = trim((string) ($parsed['reply'] ?? ''));

        if ($originalReply !== '' && !$this->claimsSaved($originalReply)) {
            return $originalReply;
        }

        $action = is_array($parsed['action'] ?? null) ? $parsed['action'] : [];
        $item   = '';

        if (($action['type'] ?? null) === 'food_log') {
            $item   = $this->cleanName($action['food_log']['nama_makanan'] ?? '', 120);
            $weight = (float) ($action['food_log']['weight'] ?? 0);

            if ($item !== '' && $weight > 0) {
                $item .= ' ' . rtrim(rtrim(number_format($weight, 1, ',', ''), '0'), ',') . ' gram';
            }
        } elseif (($action['type'] ?? null) === 'supplement_log') {
            $item = $this->cleanName($action['supplement_log']['nama_suplemen'] ?? '', 120);
        }

        return $item !== ''
            ? "Mau aku catat {$item} ke log harian kamu? Balas \"ya\" atau \"catat\" untuk konfirmasi ya 😊"
            : 'Mau aku catat ke log harian kamu? Balas "ya" atau "catat" untuk konfirmasi ya 😊';
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
            // Kata utuh (bukan substring), supaya mis. "bir" tidak cocok
            // dengan "biru" dan "soda" tidak cocok dengan kata lain.
            $keywords = array_map(fn (string $k) => preg_quote($k, '/'), self::UNHEALTHY_NAME_KEYWORDS);
            $pattern  = '/(?<![\p{L}\p{N}])(' . implode('|', $keywords) . ')(?![\p{L}\p{N}])/u';

            if (preg_match($pattern, $namaMakanan)) {
                return true;
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
     * Kata yang terlalu umum untuk dijadikan kunci pencarian katalog: muncul
     * di hampir semua kalimat pengguna atau di hampir semua nama produk
     * (mis. "kapsul"), sehingga hanya mengaburkan hasil.
     */
    private const LOOKUP_STOPWORDS = [
        'saya', 'kamu', 'tadi', 'tadinya', 'pagi', 'siang', 'sore', 'malam', 'hari',
        'sudah', 'udah', 'barusan', 'baru', 'makan', 'minum', 'mengonsumsi', 'konsumsi',
        'catat', 'catatkan', 'tolong', 'boleh', 'dong', 'yang', 'dengan', 'sama',
        'untuk', 'dari', 'kira', 'kira-kira', 'sekitar', 'gram', 'porsi', 'gelas',
        'mangkuk', 'piring', 'buah', 'butir', 'potong', 'sendok',
        'kapsul', 'tablet', 'kaplet', 'botol', 'strip', 'sachet', 'suplemen', 'vitamin',
    ];

    /**
     * Cari data referensi makanan & suplemen dari database berdasarkan kata
     * yang muncul di pesan pengguna. Hasilnya disuntikkan ke giliran user
     * sebagai "context_data" agar AI memakai data katalog bila cocok.
     *
     * Kandidat diurutkan menurut BANYAKNYA kata yang cocok dengan namanya,
     * supaya produk yang paling sesuai (mis. tiga kata cocok) tidak tergeser
     * oleh produk lain yang hanya cocok satu kata umum.
     */
    private function buildContextData(string $prompt): array
    {
        $words = collect(preg_split('/[^\p{L}\p{N}]+/u', mb_strtolower($prompt)) ?: [])
            ->filter(fn ($w) => mb_strlen($w) >= 4 && !in_array($w, self::LOOKUP_STOPWORDS, true))
            ->unique()
            ->take(12)
            ->values();

        if ($words->isEmpty()) {
            return ['foods' => [], 'supplements' => []];
        }

        $matchAnyWord = function ($q) use ($words) {
            foreach ($words as $w) {
                $q->orWhere('name', 'like', '%' . $w . '%');
            }
        };

        $rank = fn ($rows) => $rows
            ->sortByDesc(fn ($row) => $words->filter(fn ($w) => str_contains(mb_strtolower($row->name), $w))->count())
            ->take(5)
            ->values();

        $foods = $rank(Food::query()->where($matchAnyWord)->limit(60)->get([
            'id',
            'name',
            'category',
            'calories',
            'fat',
            'carbohydrate',
            'protein',
        ]));

        $supplements = $rank(Supplement::query()->where($matchAnyWord)->limit(60)->get([
            'id',
            'name',
            'composition',
            'packaging',
            'usage_rule',
        ]));

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

            $namaMakanan = $this->cleanName($data['nama_makanan'] ?? '', 120);
            // ID dari AI tidak dipercaya begitu saja: harus benar-benar ada di katalog.
            $makananId   = $data['makanan_id'] ?? null;
            if ($makananId !== null && !(is_numeric($makananId) && Food::whereKey((int) $makananId)->exists())) {
                $makananId = null;
            }

            // Sanity-clamp nilai gizi dari Gemini sebelum disimpan, supaya
            // nilai negatif/ekstrem (halusinasi model) tidak mencemari
            // food_logs maupun data master baru di tabel foods.
            $weight      = $this->clampNutritionValue($data['weight'] ?? 0, self::MAX_WEIGHT_G);
            $kcal        = $this->clampNutritionValue($data['kcal'] ?? 0, self::MAX_KCAL);
            $protein     = $this->clampNutritionValue($data['protein'] ?? 0, self::MAX_MACRO_G);
            $carbs       = $this->clampNutritionValue($data['carbs'] ?? 0, self::MAX_MACRO_G);
            $fat         = $this->clampNutritionValue($data['fat'] ?? 0, self::MAX_MACRO_G);
            $category    = $this->cleanName($data['category'] ?? '', 100);

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

            $namaSuplemen = $this->cleanName($data['nama_suplemen'] ?? '', 120);
            $supplementId = $data['supplement_id'] ?? null;
            if ($supplementId !== null && !(is_numeric($supplementId) && Supplement::whereKey((int) $supplementId)->exists())) {
                $supplementId = null;
            }
            $komposisi    = $this->nullableString($data['komposisi'] ?? null);
            $kemasan      = $this->nullableString($data['kemasan'] ?? null);
            $kemasan      = $kemasan !== null ? mb_substr($kemasan, 0, 190) : null;
            $aturanPakai  = $this->nullableString($data['aturan_pakai'] ?? null);
            $source = $this->sanitizeSource($data['source'] ?? null);
            $reminderTime = $data['reminder_time'] ?? null;
            $isTaken      = (bool) ($data['is_taken'] ?? false);

            if ($namaSuplemen === '') {
                throw new \InvalidArgumentException('nama_suplemen kosong pada action supplement_log');
            }

            $supplementImage = null;

            // Katalog adalah sumber kebenaran: bila suplemen sudah ada di master
            // (lewat id dari context_data, atau nama yang sama persis), data
            // produknya diambil dari sana — bukan dari tebakan AI.
            $master = !empty($supplementId)
                ? Supplement::find($supplementId)
                : Supplement::where('name', $namaSuplemen)->first();

            if ($master) {
                $supplementId    = $master->id;
                $supplementImage = $master->image;
                $komposisi       = $this->nullableString($master->composition) ?? $komposisi;
                $kemasan         = $this->nullableString($master->packaging) ?? $kemasan;
                $aturanPakai     = $this->nullableString($master->usage_rule) ?? $aturanPakai;
                $source          = 'Database Ibusehat';
            } else {
                // Suplemen baru: komposisi & kemasan wajib ada (system prompt
                // sudah memintanya, tetapi tetap diperiksa di sini). Tanpa itu
                // katalog tidak boleh diisi data kosong; minta ke pengguna.
                if ($komposisi === null || $kemasan === null) {
                    throw new \DomainException(
                        "Aku belum punya info lengkap tentang {$namaSuplemen}. Boleh sebutkan komposisi dan "
                        . 'kemasannya (biasanya ada di label)? Setelah itu aku catat ya.'
                    );
                }

                // Pencarian gambar (fetchSupplementImageUrl) SENGAJA dilakukan
                // DI LUAR transaction karena ia melakukan HTTP call eksternal
                // (jangan menahan koneksi/transaksi DB selama menunggu network),
                // dan hanya untuk suplemen yang benar-benar baru.
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

            // Kolom source wajib diisi. Bila AI tidak menyebut sumbernya,
            // tandai apa adanya sebagai perkiraan AI.
            $source ??= 'Perkiraan AI';

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