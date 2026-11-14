<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class ProfileController extends Controller
{
    /**
     * GET /api/profile
     * Mengembalikan data lengkap profil user yang sedang login.
     */
    public function show(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'id'                 => $user->id,
                'name'               => $user->name,
                'email'              => $user->email,
                'avatar'             => $user->avatar,
                'google_id'          => $user->google_id,
                'is_onboarding_done' => (bool) $user->is_onboarding_done,
                'height'             => $user->height,
                'weight'             => $user->weight,
                'target_weight'      => $user->target_weight,
                'age'                => $user->age,
                'delivery_date'      => $user->delivery_date?->toDateString(),
                'is_premium'         => $user->hasActivePremium(),
                'created_at'         => $user->created_at,
            ],
        ]);
    }

    /**
     * PUT /api/profile
     * Update data profil / data kesehatan user.
     */
    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name'           => ['sometimes', 'required', 'string', 'max:100'],
            'height'         => ['sometimes', 'nullable', 'numeric', 'min:50', 'max:300'],
            'weight'         => ['sometimes', 'nullable', 'numeric', 'min:10', 'max:500'],
            'target_weight'  => ['sometimes', 'nullable', 'numeric', 'min:10', 'max:500'],
            'age'            => ['sometimes', 'nullable', 'integer', 'min:12', 'max:80'],
            'delivery_date'  => ['sometimes', 'nullable', 'date'],
            'avatar'         => ['sometimes', 'nullable', 'string', 'max:500'],
        ]);

        $user->fill($validated)->save();

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui.',
            'data' => [
                'id'                 => $user->id,
                'name'               => $user->name,
                'email'              => $user->email,
                'avatar'             => $user->avatar,
                'is_onboarding_done' => (bool) $user->is_onboarding_done,
                'height'             => $user->height,
                'weight'             => $user->weight,
                'target_weight'      => $user->target_weight,
                'age'                => $user->age,
                'delivery_date'      => $user->delivery_date?->toDateString(),
                'is_premium'         => $user->hasActivePremium(),
            ],
        ]);
    }

    /**
     * PUT /api/profile/fcm-token
     * Update FCM token untuk push notification.
     */
    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => ['required', 'string'],
        ]);

        $request->user()->update(['fcm_token' => $request->fcm_token]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token berhasil diperbarui.',
        ]);
    }
}
