<?php

// app/Http/Controllers/AuthController.php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    private const GOAL_INTAKE = 2500;
    private const MAX_INTAKE_PER_UPDATE = 5000;

    private const GOOGLE_VALID_ISSUERS = [
        'accounts.google.com',
        'https://accounts.google.com',
    ];

    // -------------------------------------------------------------------------
    // Public endpoints
    // -------------------------------------------------------------------------

    public function googleLogin(Request $request): JsonResponse
    {
        $request->validate([
            'id_token' => 'required|string',
        ]);

        try {
            $googleUser = $this->verifyGoogleToken($request->id_token);

            if (!$googleUser) {
                return response()->json(['message' => 'Token tidak valid'], 401);
            }

            $user = $this->findOrCreateUser($googleUser);

            $user->tokens()->delete();

            $token = $user->createToken('google-auth')->plainTextToken;

            return response()->json([
                'token' => $token,
                'user'  => $this->formatUser($user),
            ]);
        } catch (\Exception $e) {
            Log::error('Google login failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json(['message' => 'Login gagal, coba lagi nanti'], 500);
        }
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Berhasil keluar']);
    }

    public function updateOnboarding(Request $request): JsonResponse
    {
        $user = $request->user();

        if (!$user->is_onboarding_done) {
            $user->is_onboarding_done = true;
            $user->save();
        }

        return response()->json([
            'message'            => 'Onboarding status updated',
            'is_onboarding_done' => true,
        ]);
    }

    public function getUser(Request $request): JsonResponse
    {
        return response()->json($this->formatUser($request->user()));
    }

    // -------------------------------------------------------------------------
    // Water Intake endpoints
    // -------------------------------------------------------------------------

    public function getWaterIntake(Request $request): JsonResponse
    {
        $user = $request->user();

        $wasReset = $this->resetWaterIntakeIfNewDay($user);

        if ($wasReset) {
            $user->save();
        }

        return response()->json([
            'water_intake' => $user->water_intake,
            'goal_intake'  => self::GOAL_INTAKE,
        ]);
    }

    public function updateWaterIntake(Request $request): JsonResponse
    {
        $request->validate([
            'amount' => 'required|integer|min:1|max:' . self::MAX_INTAKE_PER_UPDATE,
        ]);

        $user = $request->user();

        $this->resetWaterIntakeIfNewDay($user);
        $user->water_intake += $request->integer('amount');
        $user->save();

        return response()->json([
            'message'      => 'Water intake updated',
            'water_intake' => $user->water_intake,
            'goal_intake'  => self::GOAL_INTAKE,
        ]);
    }

    public function reduceWaterIntake(Request $request): JsonResponse
    {
        $request->validate([
            'amount' => 'required|integer|min:1|max:' . self::MAX_INTAKE_PER_UPDATE,
        ]);

        $user = $request->user();

        $this->resetWaterIntakeIfNewDay($user);
        $user->water_intake = max(0, $user->water_intake - $request->integer('amount'));
        $user->save();

        return response()->json([
            'message'      => 'Water intake reduced',
            'water_intake' => $user->water_intake,
            'goal_intake'  => self::GOAL_INTAKE,
        ]);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function findOrCreateUser(array $googleUser): User
    {
        $email = $googleUser['email'];

        $fallbackName = Str::of($email)
            ->before('@')
            ->replace(['.', '_', '-'], ' ')
            ->title()
            ->toString();

        $name = !empty($googleUser['name']) ? $googleUser['name'] : ($fallbackName ?: 'User');

        $user = User::firstOrCreate(
            ['email' => $email],
            [
                'name'              => $name,
                'password'          => Str::random(32),
                'avatar'            => $googleUser['picture'] ?? null,
                'google_id'         => $googleUser['sub'],
                'email_verified_at' => now(),
            ]
        );

        // Sync data terbaru jika user sudah pernah terdaftar sebelumnya
        if (!$user->wasRecentlyCreated) {
            $user->name              = $name;
            $user->avatar            = $googleUser['picture'] ?? null;
            $user->google_id         = $googleUser['sub'];
            $user->email_verified_at = now();
        }

        $this->resetWaterIntakeIfNewDay($user);

        $user->save();

        return $user;
    }

    private function resetWaterIntakeIfNewDay(User $user): bool
    {
        $tz    = config('app.timezone', 'UTC');
        $today = now()->timezone($tz)->toDateString();

        $lastDate = $user->water_intake_date
            ? $user->water_intake_date->timezone($tz)->toDateString()
            : null;

        if ($lastDate === $today) {
            return false;
        }

        $user->water_intake      = 0;
        $user->water_intake_date = now();

        return true;
    }

    private function verifyGoogleToken(string $idToken): ?array
    {
        $response = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if (!$response->successful()) {
            Log::warning('Google tokeninfo request failed', [
                'status' => $response->status(),
                'body'   => $response->body(),
            ]);

            return null;
        }

        $data = $response->json();

        if (empty($data['email']) || empty($data['sub']) || empty($data['aud'])) {
            Log::warning('Google token missing required fields', ['data' => $data]);

            return null;
        }

        if (isset($data['email_verified']) && $data['email_verified'] !== 'true') {
            Log::warning('Google token email not verified', ['email' => $data['email']]);

            return null;
        }

        if (!isset($data['iss']) || !in_array($data['iss'], self::GOOGLE_VALID_ISSUERS, true)) {
            Log::warning('Google token invalid issuer', ['iss' => $data['iss'] ?? null]);

            return null;
        }

        if (!empty($data['exp']) && (int) $data['exp'] < time()) {
            Log::warning('Google token expired', ['exp' => $data['exp']]);

            return null;
        }

        $tokenAudiences = is_array($data['aud']) ? $data['aud'] : [$data['aud']];

        $validClientIds = array_values(array_unique(array_filter([
            config('services.google.client_id'),
            config('services.google.client_id_web'),
            config('services.google.client_id_android'),
            config('services.google.client_id_ios'),
        ])));

        if (empty($validClientIds)) {
            Log::error('Google OAuth: tidak ada client ID yang dikonfigurasi');

            return null;
        }

        $hasValidAudience = !empty(array_intersect($tokenAudiences, $validClientIds));

        if (!$hasValidAudience) {
            Log::warning('Google token audience mismatch', [
                'token_aud'        => $tokenAudiences,
                'valid_client_ids' => $validClientIds,
            ]);

            return null;
        }

        return $data;
    }

    private function formatUser(User $user): array
    {
        return [
            'id'                 => $user->id,
            'name'               => $user->name,
            'email'              => $user->email,
            'avatar'             => $user->avatar,
            'is_onboarding_done' => (bool) $user->is_onboarding_done,
            'is_premium'         => $user->hasActivePremium(),
            'premium_until'      => $user->premium_until?->toIso8601String(),
            'water_intake'       => $user->water_intake,
            'goal_intake'        => self::GOAL_INTAKE,
        ];
    }
}