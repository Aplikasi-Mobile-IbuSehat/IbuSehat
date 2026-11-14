<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\GeminiController;
use App\Http\Controllers\FoodController;
use App\Http\Controllers\FoodLogController;
use App\Http\Controllers\SupplementController;
use App\Http\Controllers\SupplementLogController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\FcmTokenController;
use App\Http\Controllers\SleepController;
use App\Http\Controllers\SleepLogController;
use App\Http\Controllers\ActivityController;
use App\Http\Controllers\WorkoutProgramController;
use App\Http\Controllers\StreakController;
use App\Http\Controllers\ProgressController;
use App\Http\Controllers\WaterIntakeController;
use App\Http\Controllers\ProfileController;

// ─────────────────────────────────────────────
// Sanity-check route
// ─────────────────────────────────────────────
Route::get('/test', function () {
    return response()->json(['status' => 'OK']);
});

// ─────────────────────────────────────────────
// Auth routes (public)
// ─────────────────────────────────────────────
Route::post('/auth/google', [AuthController::class, 'googleLogin']);

// ─────────────────────────────────────────────
// Payment routes (public — webhook dari Midtrans)
// ─────────────────────────────────────────────
Route::post('/payment/notification', [PaymentController::class, 'handleNotification']);

// ─────────────────────────────────────────────
// Workout programs (public)
// ─────────────────────────────────────────────
Route::get('/workout-programs', [WorkoutProgramController::class, 'index']);
Route::get('/workout-programs/{id}', [WorkoutProgramController::class, 'show']);

// ─────────────────────────────────────────────
// Foods catalog (public read)
// ─────────────────────────────────────────────
Route::prefix('foods')->group(function () {
    Route::get('/', [FoodController::class, 'index']);
    Route::get('/categories', [FoodController::class, 'categories']);
    Route::get('/{id}', [FoodController::class, 'show']);
});

// ─────────────────────────────────────────────
// Supplements catalog (public read)
// ─────────────────────────────────────────────
Route::prefix('supplements')->group(function () {
    Route::get('/', [SupplementController::class, 'index']);
    Route::get('/sources', [SupplementController::class, 'sources']);
    Route::get('/{id}', [SupplementController::class, 'show']);
});

// ─────────────────────────────────────────────
// Protected routes (requires Sanctum token)
// ─────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // ── Auth / Session ─────────────────────────
    Route::get('/user', [AuthController::class, 'getUser']);

    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/user/onboarding', [AuthController::class, 'updateOnboarding']);

    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);

    // ── Water Intake ───────────────────────────
    Route::get('/user/water-intake', [WaterIntakeController::class, 'index']);
    Route::get('/user/water-intake/weekly', [WaterIntakeController::class, 'weekly']);
    Route::post('/user/water-intake/add', [WaterIntakeController::class, 'add']);
    Route::post('/user/water-intake/reduce', [WaterIntakeController::class, 'reduce']);

    // ── FCM Token ──────────────────────────────
    Route::post('/fcm-token', [FcmTokenController::class, 'store']);

    // ── Chatbot AI (Gemini) — Premium Only ─────
    // Ini SATU-SATUNYA jalur user-facing untuk menambah data master baru ke
    // foods/supplements. Ditangani lewat GeminiController::handleAction(),
    // yang punya guard: clamp nilai gizi, blokir makanan tidak sehat, dan
    // wajib konfirmasi eksplisit dari user sebelum data disimpan.
    Route::middleware(['throttle:chat', 'premium.chat-quota'])->group(function () {
        Route::post('/gemini/chat', [GeminiController::class, 'ask']);
    });

    // ── Payment ────────────────────────────────
    Route::post('/payment/create', [PaymentController::class, 'createTransaction']);

    // ── Activities ─────────────────────────────
    Route::get('/activities/summary', [ActivityController::class, 'summary']);
    Route::get('/activities', [ActivityController::class, 'index']);
    Route::post('/activities', [ActivityController::class, 'store']);
    Route::get('/activities/{activity}', [ActivityController::class, 'show']);

    // ── Sleep ──────────────────────────────────
    Route::get('/sleep/dashboard', [SleepController::class, 'dashboard']);

    Route::get('/sleep/log/latest', [SleepLogController::class, 'latest']);
    Route::get('/sleep/log/today', [SleepLogController::class, 'today']);
    Route::get('/sleep/log/history', [SleepLogController::class, 'history']);
    Route::get('/sleep/log/weekly-summary', [SleepLogController::class, 'weeklySummary']);
    Route::get('/sleep/log/detail/{id}', [SleepLogController::class, 'show'])->whereNumber('id');
    Route::get('/sleep/log/{id}', [SleepLogController::class, 'show'])->whereNumber('id');
    Route::post('/sleep/log', [SleepLogController::class, 'store']);
    Route::post('/sleep/log/save', [SleepLogController::class, 'save']);
    Route::delete('/sleep/log/{id}', [SleepLogController::class, 'destroy'])->whereNumber('id');

    // ── Diet: Food Logs ────────────────────────
    Route::prefix('food-logs')->group(function () {
        Route::get('/summary', [FoodLogController::class, 'summary']);
        Route::get('/', [FoodLogController::class, 'index']);
        Route::post('/', [FoodLogController::class, 'store']);
        Route::put('/{id}', [FoodLogController::class, 'update'])->whereNumber('id');
        Route::patch('/{id}', [FoodLogController::class, 'update'])->whereNumber('id');
        Route::delete('/{id}', [FoodLogController::class, 'destroy'])->whereNumber('id');
    });

    // ── Diet: Supplement Logs ──────────────────
    Route::prefix('supplement-logs')->group(function () {
        Route::get('/', [SupplementLogController::class, 'index']);
        Route::post('/', [SupplementLogController::class, 'store']);
        Route::put('/{id}', [SupplementLogController::class, 'update'])->whereNumber('id');
        Route::patch('/{id}', [SupplementLogController::class, 'update'])->whereNumber('id');
        Route::delete('/{id}', [SupplementLogController::class, 'destroy'])->whereNumber('id');
    });

    // NOTE (dihapus dari sini secara sengaja):
    // Endpoint CRUD manual "Admin: Foods CRUD" dan "Admin: Supplements CRUD"
    // (POST/PUT/DELETE ke /foods dan /supplements) SUDAH DIHAPUS dari API
    // user-facing ini. Aplikasi ini tidak punya sistem role admin.
    //
    // PENTING dibedakan dari food-logs/supplement-logs di atas: food-logs dan
    // supplement-logs itu PRIVAT per user (selalu difilter where user_id di
    // controller) — aman, tidak disentuh perubahan ini.
    //
    // Yang dihapus adalah akses tulis ke food_nutrition/supplements, yaitu
    // tabel KATALOG yang:
    //   1. Dibaca lewat GET /foods & GET /supplements TANPA login sama sekali
    //      (lihat grup route publik di atas) — kalau isinya dirusak, semua
    //      orang (termasuk yang belum pernah pakai app) langsung melihatnya.
    //   2. Disuntikkan sebagai "context_data" ke Gemini di
    //      GeminiController::buildContextData() sebagai sumber kebenaran gizi
    //      yang WAJIB dipercaya AI kalau namanya cocok — kalau isinya salah,
    //      jawaban chatbot ke SEMUA user lain ikut salah.
    // Endpoint tanpa guard/validasi apa pun ke tabel ini (berbeda dengan
    // jalur chatbot yang sudah ada guard) berisiko merusak dua hal itu.
    //
    // Jalur resmi untuk MENAMBAH data master baru adalah lewat chatbot AI
    // (POST /gemini/chat di atas), yang sudah punya guard (clamp nilai gizi,
    // blokir makanan tidak sehat, wajib konfirmasi eksplisit).
    //
    // Kalau suatu saat perlu koreksi/kurasi manual data katalog (mis. admin
    // internal membetulkan komposisi suplemen), sebaiknya lewat jalur yang
    // TIDAK memakai token Sanctum user biasa, misalnya:
    //   - php artisan tinker / seeder khusus, atau
    //   - panel admin terpisah dengan auth guard sendiri (mis. session-based,
    //     bukan API token milik user aplikasi mobile), atau
    //   - endpoint terpisah yang dikunci middleware API-key internal
    //     (bukan auth:sanctum biasa).

    // ── Streak & Workout Tracking ──
    Route::post('/workout/complete', [StreakController::class, 'completeWorkout']);
    Route::get('/streak', [StreakController::class, 'getStreak']);

    // ── Progress Tracking ───
    Route::get('/progress/summary', [ProgressController::class, 'summary']);
    Route::post('/diet/food/add', [ProgressController::class, 'addFood']);
    Route::post('/diet/water/add', [ProgressController::class, 'addWater']);
});