<?php

namespace App\Services\Chat;

use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Pembungkus tipis untuk Gemini generateContent.
 *
 * API key dikirim lewat header (bukan query string) supaya tidak ikut
 * tercatat di URL/log, dan system prompt dikirim lewat field resmi
 * `systemInstruction` (bukan sebagai giliran "user" palsu).
 */
class GeminiClient
{
    public function isConfigured(): bool
    {
        return (string) config('services.gemini.key') !== '';
    }

    /**
     * @param  array<int, array{role: string, text: string}>  $turns  giliran percakapan, diakhiri giliran user
     * @return array{ok: bool, text: ?string, status: int, blocked: bool}
     */
    public function generate(
        string $systemPrompt,
        array $turns,
        bool $jsonOutput = true,
        float $temperature = 0.3,
        int $maxOutputTokens = 1200,
        int $timeoutSeconds = 30,
    ): array {
        $baseUrl = rtrim((string) config('services.gemini.base_url'), '/');
        $model   = (string) config('services.gemini.model');

        $generationConfig = [
            'temperature'     => $temperature,
            'maxOutputTokens' => $maxOutputTokens,
        ];

        if ($jsonOutput) {
            $generationConfig['responseMimeType'] = 'application/json';
        }

        $response = Http::timeout($timeoutSeconds)
            // Satu kali coba ulang untuk gangguan sementara di sisi Gemini.
            // 429 (kuota/batas laju) sengaja TIDAK dicoba ulang: percobaan
            // kedua hanya membuang kuota yang memang sudah habis.
            ->retry(
                2,
                1500,
                fn ($exception) => $exception instanceof RequestException
                    && in_array($exception->response->status(), [500, 503], true),
                throw: false,
            )
            ->withHeaders([
                'Content-Type'   => 'application/json',
                'x-goog-api-key' => (string) config('services.gemini.key'),
            ])
            ->post("{$baseUrl}/models/{$model}:generateContent", [
                'systemInstruction' => [
                    'parts' => [['text' => $systemPrompt]],
                ],
                'contents' => array_map(fn (array $turn) => [
                    'role'  => $turn['role'] === 'model' ? 'model' : 'user',
                    'parts' => [['text' => $turn['text']]],
                ], $turns),
                'generationConfig' => $generationConfig,
            ]);

        if (!$response->successful()) {
            // Detail hanya ke log server; jangan diteruskan mentah ke client.
            Log::error('Gemini API error', [
                'status' => $response->status(),
                'body'   => mb_substr($response->body(), 0, 1000),
            ]);

            return ['ok' => false, 'text' => null, 'status' => $response->status(), 'blocked' => false];
        }

        $result  = $response->json() ?? [];
        $text    = $result['candidates'][0]['content']['parts'][0]['text'] ?? null;
        $blocked = !empty($result['promptFeedback']['blockReason'])
            || in_array($result['candidates'][0]['finishReason'] ?? null, ['SAFETY', 'PROHIBITED_CONTENT', 'BLOCKLIST'], true);

        if (!is_string($text) || trim($text) === '') {
            return ['ok' => false, 'text' => null, 'status' => 200, 'blocked' => $blocked];
        }

        return ['ok' => true, 'text' => $text, 'status' => 200, 'blocked' => $blocked];
    }
}
