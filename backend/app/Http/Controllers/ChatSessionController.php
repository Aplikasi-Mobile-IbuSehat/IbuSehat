<?php

namespace App\Http\Controllers;

use App\Models\ChatMessage;
use App\Models\ChatSession;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Riwayat sesi IbuSehat AI. Semua query dibatasi ke user yang sedang login,
 * jadi sesi dan pesan pengguna lain tidak pernah bisa diakses.
 */
class ChatSessionController extends Controller
{
    /**
     * GET /api/gemini/sessions — daftar sesi milik user, terbaru dulu.
     */
    public function index(Request $request): JsonResponse
    {
        $sessions = ChatSession::where('user_id', $request->user()->id)
            ->whereNotNull('last_message_at')
            ->orderByDesc('last_message_at')
            ->orderByDesc('id')
            ->limit(30)
            ->get(['id', 'title', 'last_message_at']);

        return response()->json([
            'success' => true,
            'data'    => $sessions->map(fn (ChatSession $s) => [
                'id'              => $s->id,
                'title'           => $s->title ?: 'Percakapan',
                'last_message_at' => $s->last_message_at?->toIso8601String(),
            ]),
        ]);
    }

    /**
     * GET /api/gemini/sessions/{id}/messages — isi satu sesi (maks. 100 pesan terakhir).
     */
    public function messages(Request $request, int $id): JsonResponse
    {
        $session = ChatSession::where('user_id', $request->user()->id)->find($id);

        if ($session === null) {
            return $this->notFound();
        }

        $messages = $session->messages()
            ->orderByDesc('id')
            ->limit(100)
            ->get(['id', 'role', 'content', 'kind', 'created_at'])
            ->reverse()
            ->values();

        return response()->json([
            'success' => true,
            'data'    => [
                'session_id' => $session->id,
                'title'      => $session->title ?: 'Percakapan',
                'messages'   => $messages->map(fn (ChatMessage $m) => [
                    'id'         => $m->id,
                    'role'       => $m->role,
                    'text'       => $m->content,
                    'kind'       => $m->kind,
                    'created_at' => $m->created_at?->toIso8601String(),
                ]),
            ],
        ]);
    }

    /**
     * DELETE /api/gemini/sessions/{id} — hapus sesi beserta seluruh pesannya.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $session = ChatSession::where('user_id', $request->user()->id)->find($id);

        if ($session === null) {
            return $this->notFound();
        }

        $session->delete(); // pesan ikut terhapus (cascade)

        return response()->json([
            'success' => true,
            'message' => 'Percakapan dihapus.',
        ]);
    }

    private function notFound(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Sesi percakapan tidak ditemukan.',
            'code'    => 'SESSION_NOT_FOUND',
        ], 404);
    }
}
