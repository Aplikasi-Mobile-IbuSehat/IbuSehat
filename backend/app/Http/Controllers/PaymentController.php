<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Midtrans\Config;
use Midtrans\Snap;
use App\Models\Payment;
use App\Models\User;

class PaymentController extends Controller
{
    /**
     * Daftar paket premium yang valid.
     * key dipakai sebagai prefix order_id (mis. PREMIUM-1M-xxxx, PREMIUM-11M-xxxx)
     * agar mudah ditelusuri (audit trail) tanpa perlu request tambahan ke client
     * saat verifikasi notifikasi pembayaran.
     */
    private const PLANS = [
        '1M' => [
            'amount'        => 39000,
            'duration_days' => 30,
            'label'         => '1 Bulan',
        ],
        '11M' => [
            'amount'        => 349000,
            'duration_days' => 330, // 11 x 30 hari
            'label'         => '11 Bulan',
        ],
    ];

    public function __construct()
    {
        Config::$serverKey    = config('midtrans.server_key');
        Config::$isProduction = config('midtrans.is_production');
        Config::$isSanitized  = config('midtrans.is_sanitized');
        Config::$is3ds        = config('midtrans.is_3ds');
    }

    public function createTransaction(Request $request)
    {
        $request->validate([
            'plan_type' => 'required|string|in:1M,11M',
        ]);

        $user = $request->user();
        $plan = self::PLANS[$request->plan_type];

        $orderId = 'PREMIUM-' . $request->plan_type . '-' . $user->id . '-' . now()->format('YmdHis');

        $params = [
            'transaction_details' => [
                'order_id'     => $orderId,
                'gross_amount' => $plan['amount'],
            ],
            'customer_details' => [
                'first_name' => $user->name,
                'email'      => $user->email,
            ],
        ];

        try {
            $snapToken = Snap::getSnapToken($params);

            Payment::updateOrCreate(
                ['order_id' => $orderId],
                [
                    'user_id'       => $user->id,
                    'amount'        => $plan['amount'],
                    'plan_type'     => $request->plan_type,
                    'duration_days' => $plan['duration_days'],
                    'snap_token'    => $snapToken,
                    'status'        => 'pending',
                ]
            );

            return response()->json([
                'success'    => true,
                'order_id'   => $orderId,
                'snap_token' => $snapToken,
                'client_key' => config('midtrans.client_key'),
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    public function handleNotification(Request $request)
    {
        $serverKey = config('midtrans.server_key');
        $orderId   = $request->order_id;
        $statusCode     = $request->status_code;
        $grossAmount    = $request->gross_amount;
        $signatureKey   = $request->signature_key;

        $expectedSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);

        if ($signatureKey !== $expectedSignature) {
            return response()->json(['message' => 'Invalid signature'], 403);
        }

        // Ambil status dari request (lebih reliable dari Notification object)
        $transactionStatus = $request->transaction_status;
        $fraudStatus       = $request->fraud_status;

        $payment = Payment::where('order_id', $orderId)->first();
        if (!$payment) {
            return response()->json(['message' => 'Payment not found'], 404);
        }

        $previousStatus = $payment->status;

        if ($transactionStatus == 'capture') {
            $payment->status = ($fraudStatus == 'accept') ? 'success' : 'fraud';
        } elseif ($transactionStatus == 'settlement') {
            $payment->status = 'success';
        } elseif (in_array($transactionStatus, ['cancel', 'deny', 'expire'])) {
            $payment->status = 'failed';
        } elseif ($transactionStatus == 'pending') {
            $payment->status = 'pending';
        }

        $payment->save();

        // Aktifkan/perpanjang premium hanya saat status BERUBAH menjadi 'success'
        // (mencegah duplikasi perpanjangan jika notifikasi Midtrans dikirim ulang).
        if ($payment->status === 'success' && $previousStatus !== 'success') {
            $this->activatePremium($payment);
        }

        return response()->json(['message' => 'OK']);
    }

    /**
     * Aktifkan atau perpanjang masa premium user berdasarkan data pembayaran.
     * Jika user masih memiliki sisa masa premium aktif, durasi baru
     * ditambahkan dari tanggal kadaluarsa saat ini (bukan dari "sekarang"),
     * supaya pengguna yang upgrade sebelum masa aktifnya habis tidak
     * dirugikan.
     */
    private function activatePremium(Payment $payment): void
    {
        $user = $payment->user;

        if (!$user) {
            return;
        }

        $durationDays = $payment->duration_days
            ?? (self::PLANS[$payment->plan_type]['duration_days'] ?? 30);

        $base = ($user->premium_until && $user->premium_until->isFuture())
            ? $user->premium_until
            : now();

        $user->is_premium     = true;
        $user->premium_until  = $base->copy()->addDays($durationDays);
        $user->save();
    }
}