<?php

namespace App\Http\Middleware;

use App\Models\ChatUsage;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePremiumChatQuota
{
    /**
     * Kuota chat harian untuk user premium.
     * 25 dipilih sebagai titik tengah antara batas teknis (biaya API Gemini)
     * dan kebutuhan bisnis (cukup untuk percakapan harian wajar tanpa terasa
     * dibatasi, tapi mencegah penyalahgunaan/spam otomatis).
     */
    private const DAILY_QUOTA = 25;

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || !$user->hasActivePremium()) {
            return response()->json([
                'success' => false,
                'message' => 'Fitur AI Chatbot hanya tersedia untuk pengguna Premium. Silakan upgrade untuk mengakses fitur ini.',
                'code'    => 'PREMIUM_REQUIRED',
            ], 403);
        }

        $today = now()->timezone(config('app.timezone', 'UTC'))->toDateString();

        $usage = ChatUsage::firstOrCreate(
            ['user_id' => $user->id, 'usage_date' => $today],
            ['count' => 0],
        );

        if ($usage->count >= self::DAILY_QUOTA) {
            return response()->json([
                'success' => false,
                'message' => 'Anda telah mencapai batas chat harian (' . self::DAILY_QUOTA . 'x). Silakan coba lagi besok.',
                'code'    => 'DAILY_QUOTA_EXCEEDED',
                'meta'    => [
                    'used'  => $usage->count,
                    'quota' => self::DAILY_QUOTA,
                ],
            ], 429);
        }

        // Tambah counter SEBELUM request diproses, agar konsisten meski terjadi
        // error di tengah proses (mencegah retry-spam memutar ulang kuota gratis).
        $usage->increment('count');

        // Simpan info sisa kuota di request agar bisa dibaca controller untuk
        // dikembalikan ke Flutter.
        $request->attributes->set('chat_quota_used', $usage->count);
        $request->attributes->set('chat_quota_limit', self::DAILY_QUOTA);

        return $next($request);
    }
}