<?php
// app/Services/FcmService.php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    private string $projectId;
    private string $credentialsPath;

    public function __construct()
    {
        $this->credentialsPath = storage_path('firebase/ibusehat-7905b-firebase-adminsdk-fbsvc-16a93ffb16.json');

        $json = json_decode(file_get_contents($this->credentialsPath), true);
        $this->projectId = $json['project_id'];
    }

    /**
     * Generate OAuth2 access token dari service account
     */
    private function getAccessToken(): string
    {
        $scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

        $credentials = new ServiceAccountCredentials($scopes, $this->credentialsPath);
        $token = $credentials->fetchAuthToken();

        return $token['access_token'];
    }

    /**
     * Kirim notifikasi ke satu device token via FCM v1 API
     */
    public function sendToDevice(
        string $token,
        string $title,
        string $body,
        array $data = []
    ): bool {
        try {
            $accessToken = $this->getAccessToken();

            $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

            // data harus semua string
            $stringData = array_map('strval', $data);

            $payload = [
                'message' => [
                    'token'        => $token,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'data'         => $stringData,
                    'android'      => [
                        'priority' => 'high',
                        'notification' => [
                            'sound'        => 'default',
                            'channel_id'   => 'supplement_reminder',
                        ],
                    ],
                    'apns' => [
                        'payload' => [
                            'aps' => [
                                'sound' => 'default',
                                'badge' => 1,
                            ],
                        ],
                    ],
                ],
            ];

            $response = Http::withToken($accessToken)
                ->post($url, $payload);

            if ($response->successful()) {
                return true;
            }

            Log::warning('FCM gagal', [
                'status'   => $response->status(),
                'response' => $response->body(),
                'token'    => substr($token, 0, 20) . '...',
            ]);

            return false;

        } catch (\Throwable $e) {
            Log::error('FCM error: ' . $e->getMessage());
            return false;
        }
    }
}