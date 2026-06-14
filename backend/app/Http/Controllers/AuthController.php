<?php
// app/Http/Controllers/AuthController.php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function googleLogin(Request $request)
    {
        $request->validate([
            'id_token' => 'required|string',
        ]);

        try {
            // 1. Verifikasi idToken ke Google
            $googleUser = $this->verifyGoogleToken($request->id_token);

            if (!$googleUser) {
                return response()->json(['message' => 'Token tidak valid'], 401);
            }

            $email = $googleUser['email'];
            // tokeninfo tidak selalu mengembalikan name/picture, jadi fallback dari email
            $fallbackName = Str::of($email)->before('@')->replace(['.', '_', '-'], ' ')->title()->toString();
            $name = $googleUser['name'] ?? ($fallbackName !== '' ? $fallbackName : 'User');

            // 2. Cari atau buat user (WAJIB isi `name` saat create, karena kolom NOT NULL)
            $user = User::firstOrCreate(
                ['email' => $email],
                [
                    'name'     => $name,
                    'password' => Str::random(32),
                ]
            );

            // Update field Google setiap login
            $user->fill([
                'name'              => $name,
                'avatar'            => $googleUser['picture'] ?? null,
                'google_id'         => $googleUser['sub'],
                'email_verified_at' => now(),
            ])->save();
            

            // 3. Buat API token (Sanctum)
            $token = $user->createToken('google-auth')->plainTextToken;

            return response()->json([
                'token' => $token,
                'user'  => [
                    'id'     => $user->id,
                    'name'   => $user->name,
                    'email'  => $user->email,
                    'avatar' => $user->avatar,
                    'is_onboarding_done' => (bool) $user->is_onboarding_done,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Login gagal: ' . $e->getMessage()], 500);
        }
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Berhasil keluar']);
    }

    public function updateOnboarding(Request $request)
    {
        $user = $request->user();
        $user->is_onboarding_done = true;
        $user->save();

        return response()->json([
            'message' => 'Onboarding status updated',
            'is_onboarding_done' => true
        ]);
    }

    private function verifyGoogleToken(string $idToken): ?array
{
    $response = Http::get('https://oauth2.googleapis.com/tokeninfo', [
        'id_token' => $idToken,
    ]);

    if (!$response->successful()) {
        return null;
    }

    $data = $response->json();

    if (empty($data['email']) || empty($data['sub']) || empty($data['aud'])) {
        return null;
    }

    // email_verified kadang tidak ada; kalau ada dan false ΓåÆ tolak
    if (array_key_exists('email_verified', $data) && ($data['email_verified'] ?? '') !== 'true') {
        return null;
    }

    // `aud` biasanya Web Client ID (client_type 3) saat mobile mengirim id_token.
    $validClientIds = array_values(array_unique(array_filter([
        env('GOOGLE_CLIENT_ID_WEB'),
        env('GOOGLE_CLIENT_ID_ANDROID'),
        env('GOOGLE_CLIENT_ID_IOS'),
        // fallback sesuai project (google-services.json)
        '502499232288-nla05vkd7ub40ll14ii567dugogmp9kb.apps.googleusercontent.com',
        '502499232288-a2moaita2quj4jgvn9ve9e0jvbe3o1vn.apps.googleusercontent.com',
    ])));

    if ($validClientIds !== [] && ! in_array($data['aud'], $validClientIds, true)) {
        return null;
    }

    return $data;
}


}
