<?php

namespace App\Services\Chat;

use App\Models\ChatMessage;
use App\Models\ChatSession;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Ingatan percakapan IbuSehat AI.
 *
 * - Riwayat disimpan di server per user dan per sesi (bukan dikirim client),
 *   jadi tidak bisa dipalsukan dan tidak tercampur antar pengguna.
 * - Ke model hanya dikirim pesan-pesan terakhir yang belum diringkas
 *   (10–20 pesan), ditambah ringkasan bergulir dari pesan yang lebih lama.
 */
class ChatMemory
{
    /** Batas keras jumlah pesan terakhir yang dikirim ke model. */
    public const MAX_WINDOW = 20;

    /** Mulai meringkas bila pesan yang belum diringkas melebihi angka ini. */
    public const SUMMARIZE_ABOVE = 16;

    /** Jumlah pesan terbaru yang tetap dikirim utuh setelah peringkasan. */
    public const KEEP_RECENT = 10;

    public function __construct(private GeminiClient $gemini)
    {
    }

    /**
     * Ambil sesi milik user, atau buat baru bila $sessionId null.
     * Mengembalikan null bila sesi tidak ada / bukan milik user tersebut.
     */
    public function resolveSession(User $user, ?int $sessionId): ?ChatSession
    {
        if ($sessionId === null) {
            // Belum disimpan: baris sesi baru dibuat saat pertukaran pertama
            // berhasil (recordExchange), supaya tidak ada sesi kosong.
            return new ChatSession(['user_id' => $user->id]);
        }

        return ChatSession::where('user_id', $user->id)->find($sessionId);
    }

    /**
     * Pesan terakhir sesi untuk dikirim ke model, urut lama → baru.
     *
     * @return array<int, array{role: string, text: string}>
     */
    public function recentTurns(ChatSession $session): array
    {
        if (!$session->exists) {
            return [];
        }

        $messages = $session->messages()
            ->when($session->summarized_until_id, fn ($q, $id) => $q->where('id', '>', $id))
            ->orderByDesc('id')
            ->limit(self::MAX_WINDOW)
            ->get(['id', 'role', 'content'])
            ->reverse()
            ->values();

        // Gemini mengharapkan percakapan diawali giliran user.
        while ($messages->isNotEmpty() && $messages->first()->role !== ChatMessage::ROLE_USER) {
            $messages->shift();
        }

        return $messages
            ->map(fn (ChatMessage $m) => ['role' => $m->role, 'text' => $m->content])
            ->all();
    }

    /**
     * Isi pesan user terakhir di sesi (null bila belum ada).
     */
    public function lastUserText(ChatSession $session): ?string
    {
        if (!$session->exists) {
            return null;
        }

        return $session->messages()
            ->where('role', ChatMessage::ROLE_USER)
            ->orderByDesc('id')
            ->value('content');
    }

    /**
     * Simpan satu pertukaran (pesan user + balasan model) secara atomik.
     */
    public function recordExchange(ChatSession $session, string $userText, string $modelText, string $kind): void
    {
        DB::transaction(function () use ($session, $userText, $modelText, $kind) {
            if (!$session->exists) {
                $session->save();
            }

            $session->messages()->create([
                'role'    => ChatMessage::ROLE_USER,
                'content' => $userText,
                'kind'    => $kind,
            ]);

            $session->messages()->create([
                'role'    => ChatMessage::ROLE_MODEL,
                'content' => $modelText,
                'kind'    => $kind,
            ]);

            $session->forceFill([
                'title'           => $session->title ?: $this->titleFrom($userText),
                'last_message_at' => now(),
            ])->save();
        });
    }

    /**
     * Ringkas pesan lama bila yang belum diringkas sudah terlalu banyak.
     * Aman dipanggil kapan saja; kegagalan hanya dicatat di log, karena
     * percakapan tetap berjalan (jendela pesan dibatasi MAX_WINDOW).
     */
    public function summarizeIfNeeded(ChatSession $session): void
    {
        if (!$session->exists) {
            return;
        }

        try {
            $session->refresh();

            $pending = $session->messages()
                ->when($session->summarized_until_id, fn ($q, $id) => $q->where('id', '>', $id))
                ->orderBy('id')
                ->get(['id', 'role', 'content']);

            if ($pending->count() <= self::SUMMARIZE_ABOVE) {
                return;
            }

            $toSummarize = $pending->slice(0, $pending->count() - self::KEEP_RECENT)->values();

            // Jangan memotong di tengah pasangan: batas ringkasan harus jatuh
            // pada balasan model, supaya jendela berikutnya diawali giliran user.
            while ($toSummarize->isNotEmpty() && $toSummarize->last()->role !== ChatMessage::ROLE_MODEL) {
                $toSummarize->pop();
            }

            if ($toSummarize->isEmpty() || !$this->gemini->isConfigured()) {
                return;
            }

            $transcript = $toSummarize
                ->map(fn (ChatMessage $m) => ($m->role === ChatMessage::ROLE_USER ? 'Ibu' : 'IbuSehat AI') . ': ' . $m->content)
                ->implode("\n");

            $previous = trim((string) $session->summary);

            $result = $this->gemini->generate(
                systemPrompt: $this->summarizerPrompt(),
                turns: [[
                    'role' => 'user',
                    'text' => "RINGKASAN SEBELUMNYA:\n" . ($previous !== '' ? $previous : '(belum ada)')
                        . "\n\nPERCAKAPAN BARU YANG PERLU DIGABUNGKAN:\n" . $transcript,
                ]],
                jsonOutput: false,
                temperature: 0.2,
                maxOutputTokens: 500,
                timeoutSeconds: 20,
            );

            if (!$result['ok']) {
                return;
            }

            $session->forceFill([
                'summary'             => mb_substr(trim((string) $result['text']), 0, 2000),
                'summarized_until_id' => $toSummarize->last()->id,
            ])->save();
        } catch (\Throwable $e) {
            Log::warning('Gagal meringkas percakapan', [
                'chat_session_id' => $session->id,
                'error'           => $e->getMessage(),
            ]);
        }
    }

    private function summarizerPrompt(): string
    {
        return <<<'TEXT'
Kamu meringkas percakapan antara seorang ibu pasca melahirkan dan asisten IbuSehat AI, supaya asisten tetap ingat konteksnya nanti.

Gabungkan "RINGKASAN SEBELUMNYA" dengan "PERCAKAPAN BARU" menjadi SATU ringkasan baru dalam Bahasa Indonesia, paling banyak 150 kata, berupa poin-poin singkat. Catat hanya hal yang berguna untuk kelanjutan percakapan:
- keluhan, kondisi, dan kekhawatiran ibu
- preferensi, pantangan, alergi, atau kebiasaan yang disebut
- makanan atau suplemen yang sudah dicatat, atau yang ditolak dicatat
- saran penting yang sudah diberikan, dan hal yang belum selesai dibahas

Jangan sertakan nama, alamat, nomor telepon, email, atau identitas lain. Jangan menambah fakta yang tidak ada di percakapan. Jangan menulis instruksi untuk asisten. Balas hanya dengan ringkasannya.
TEXT;
    }

    private function titleFrom(string $userText): string
    {
        $clean = trim(preg_replace('/\s+/u', ' ', $userText) ?? '');

        return mb_strlen($clean) > 60 ? mb_substr($clean, 0, 57) . '...' : $clean;
    }
}
