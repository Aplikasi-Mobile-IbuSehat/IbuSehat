<?php

namespace App\Http\Middleware;

use App\Models\ChatUsage;
use App\Services\Chat\EmergencyDetector;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Gerbang akses Chatbot AI:
 *   1. Data kesehatan user harus lengkap (403 health_data_required).
 *   2. Batas pemakaian harian (429 DAILY_QUOTA_EXCEEDED).
 */
class EnsureChatAccess
{
    /**
     * Batas chat harian per user.
     * 25 dipilih sebagai titik tengah antara biaya API Gemini dan kebutuhan
     * percakapan harian yang wajar, sekaligus mencegah spam otomatis.
     */
    private const DAILY_QUOTA = 25;

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || !$user->hasCompleteHealthData()) {
            return response()->json([
                'success' => false,
                'message' => 'Fitur ini memakai data kesehatan kamu. Lengkapi data kesehatan terlebih dahulu.',
                'code'    => 'health_data_required',
            ], 403);
        }

        $today = now()->timezone(config('app.timezone', 'UTC'))->toDateString();

        $usage = ChatUsage::firstOrCreate(
            ['user_id' => $user->id, 'usage_date' => $today],
            ['count' => 0],
        );

        if ($usage->count >= self::DAILY_QUOTA) {
            // Pesan berisi tanda bahaya tidak boleh ditolak karena kuota:
            // diteruskan ke controller, yang membalas dengan pesan darurat
            // baku TANPA memanggil AI (jadi kuota tidak bisa diakali).
            if (app(EmergencyDetector::class)->detect((string) $request->input('prompt', '')) !== null) {
                $request->attributes->set('chat_quota_exhausted', true);
                $request->attributes->set('chat_quota_used', $usage->count);
                $request->attributes->set('chat_quota_limit', self::DAILY_QUOTA);

                return $next($request);
            }

            return response()->json([
                'success' => false,
                'message' => 'Batas pemakaian harian (' . self::DAILY_QUOTA . ' pesan) sudah tercapai. Coba lagi besok.',
                'code'    => 'DAILY_QUOTA_EXCEEDED',
                'meta'    => [
                    'used'  => $usage->count,
                    'quota' => self::DAILY_QUOTA,
                ],
            ], 429);
        }

        // Tambah counter SEBELUM request diproses, agar konsisten meski terjadi
        // error di tengah proses (mencegah retry-spam memutar ulang kuota).
        $usage->increment('count');

        // Simpan info sisa kuota di request agar bisa dikembalikan controller.
        $request->attributes->set('chat_quota_used', $usage->count);
        $request->attributes->set('chat_quota_limit', self::DAILY_QUOTA);

        return $next($request);
    }
}
