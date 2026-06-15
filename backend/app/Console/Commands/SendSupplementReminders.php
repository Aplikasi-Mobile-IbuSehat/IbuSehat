<?php

namespace App\Console\Commands;

use App\Models\SupplementLog;
use App\Services\FcmService;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class SendSupplementReminders extends Command
{
    protected $signature   = 'supplements:send-reminders';
    protected $description = 'Kirim notifikasi pengingat suplemen ke user yang waktunya sudah tiba';

    public function handle(FcmService $fcm): int
    {
        // Ambil waktu sekarang dalam format HH:MM (timezone sesuai config app)
        $now = Carbon::now()->format('H:i');

        // Cari semua log suplemen yang:
        // 1. reminder_time-nya sama dengan waktu sekarang
        // 2. belum diminum (is_taken = false)
        // 3. user memiliki fcm_token
        $logs = SupplementLog::with('user')
            ->where('reminder_time', $now)
            ->where('is_taken', false)
            ->whereHas('user', fn ($q) => $q->whereNotNull('fcm_token'))
            ->get();

        if ($logs->isEmpty()) {
            $this->info("[$now] Tidak ada pengingat yang perlu dikirim.");
            return self::SUCCESS;
        }

        $sent   = 0;
        $failed = 0;

        foreach ($logs as $log) {
            $token = $log->user->fcm_token;

            $success = $fcm->sendToDevice(
                token: $token,
                title: 'Waktunya Minum Suplemen!',
                body:  "Jangan lupa minum {$log->nama_suplemen} sekarang.",
                data:  [
                    'type'            => 'supplement_reminder',
                    'supplement_log_id' => (string) $log->id,
                    'supplement_name' => $log->nama_suplemen,
                ]
            );

            $success ? $sent++ : $failed++;
        }

        $this->info("[$now] Pengingat dikirim: $sent berhasil, $failed gagal.");

        return self::SUCCESS;
    }
}