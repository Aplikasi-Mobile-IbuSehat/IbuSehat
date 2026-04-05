<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiController extends Controller
{
    /**
     * Fungsi untuk menangani permintaan chat dari Flutter ke Gemini AI
     */
    public function ask(Request $request)
    {
        // 1. Validasi Input: Memastikan 'prompt' dikirim dan berupa teks
        $request->validate([
            'prompt' => 'required|string',
        ]);

        $userPrompt = $request->input('prompt');
        $apiKey = env('GEMINI_API_KEY');

        // Jika API Key kosong di .env, beri peringatan
        if (!$apiKey) {
            return response()->json([
                'success' => false,
                'message' => 'API Key belum dikonfigurasi di server.'
            ], 500);
        }

        try {
            // 2. HTTP Request ke Google Gemini API
            // Kita menggunakan model 'gemini-1.5-flash' karena cepat dan gratis
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])->post("https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key={$apiKey}", [
                'contents' => [
                    [
                        'parts' => [
                            ['text' => $userPrompt]
                        ]
                    ]
                ]
            ]);

            // 3. Cek Status Respon
            if ($response->successful()) {
                $result = $response->json();

                // Parsing JSON: Mengambil teks jawaban dari struktur nested milik Gemini
                $aiAnswer = $result['candidates'][0]['content']['parts'][0]['text'] ?? 'Maaf, saya tidak mendapatkan jawaban.';

                return response()->json([
                    'success' => true,
                    'data' => $aiAnswer
                ], 200);
            }

            // Jika API merespon tapi error (misal: kuota habis atau konten sensitif)
            return response()->json([
                'success' => false,
                'message' => 'Gagal mendapatkan respon dari AI.',
                'details' => $response->json()
            ], $response->status());
        } catch (\Exception $e) {
            // Log error ke storage/logs/laravel.log jika terjadi crash
            Log::error("Gemini Integration Error: " . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan koneksi pada server backend.'
            ], 500);
        }
    }
}
