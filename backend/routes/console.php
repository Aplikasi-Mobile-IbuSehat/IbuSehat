<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Reminder suplemen setiap menit
Schedule::command('supplements:send-reminders')
    ->everyMinute();

// Reset status reminder setiap tengah malam
Schedule::command('supplement:reset-reminders')
    ->dailyAt('00:00');