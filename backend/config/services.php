<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'google' => [
        'client_id'         => env('GOOGLE_CLIENT_ID'),
        'client_secret'     => env('GOOGLE_CLIENT_SECRET'),
        'client_id_web'     => env('GOOGLE_CLIENT_ID_WEB'),
        'client_id_android' => env('GOOGLE_CLIENT_ID_ANDROID'),
        'client_id_ios'     => env('GOOGLE_CLIENT_ID_IOS'),
        'redirect'          => env('GOOGLE_REDIRECT_URI'),
    ],

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key'    => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel'              => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // Dipakai oleh GeminiController::ask() via config('services.gemini.key').
    // Jangan panggil env('GEMINI_API_KEY') langsung di controller — akan
    // mengembalikan null setelah `php artisan config:cache` dijalankan.
    'gemini' => [
        'key'      => env('GEMINI_API_KEY'),
        'model'    => env('GEMINI_MODEL', 'gemini-2.5-flash-lite'),
        'base_url' => env('GEMINI_BASE_URL', 'https://generativelanguage.googleapis.com/v1beta'),
    ],

    // Nomor darurat yang ditampilkan IbuSehat AI saat backend mendeteksi tanda
    // bahaya (lihat App\Services\Chat\EmergencyDetector). Sesuaikan bila perlu.
    'emergency' => [
        'ambulance' => env('EMERGENCY_NUMBER_AMBULANCE', '119'),
        'general'   => env('EMERGENCY_NUMBER_GENERAL', '112'),
    ],

    // Opsional: path file CA bundle (cacert.pem) untuk panggilan HTTPS keluar
    // (verifikasi token Google, Gemini). Perlu di Windows kalau php.ini belum
    // mengatur curl.cainfo — gejalanya "cURL error 60". Kosongkan di server.
    'http' => [
        'ca_bundle' => env('HTTP_CA_BUNDLE'),
    ],

];