<?php
// app/Http/Controllers/FcmTokenController.php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FcmTokenController extends Controller
{
    /**
     * Timpa FCM token lama dengan yang baru.
     * Otomatis hanya perangkat terakhir yang aktif.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'fcm_token' => 'required|string|max:255',
        ]);

        // update() langsung timpa token lama — tidak perlu cek apapun
        $request->user()->update([
            'fcm_token' => $request->fcm_token,
        ]);

        return response()->json([
            'message' => 'FCM token diperbarui.',
        ]);
    }
}