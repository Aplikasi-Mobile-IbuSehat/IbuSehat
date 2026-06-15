<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        /**
         * Rate limiter untuk endpoint chat AI.
         *
         * 5 request/menit dipilih sebagai batas anti-spam jangka pendek:
         * cukup longgar untuk percakapan normal (rata-rata orang tidak
         * mengetik >5 pesan dalam 1 menit), tapi mencegah bot/script
         * memukul endpoint Gemini secara berturut-turut yang bisa
         * membengkakkan biaya API.
         *
         * Limit per-menit ini terpisah dari kuota harian (chat_usages),
         * yang mengatur penggunaan wajar jangka panjang.
         */
        RateLimiter::for('chat', function ($request) {
            return Limit::perMinute(5)->by($request->user()?->id ?: $request->ip());
        });
    }
}