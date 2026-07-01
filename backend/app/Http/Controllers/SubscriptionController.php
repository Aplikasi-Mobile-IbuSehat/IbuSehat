<?php

namespace App\Http\Controllers;

use App\Models\Subscription;
use Illuminate\Http\Request;

class SubscriptionController extends Controller
{
    /**
     * GET /api/premium/status
     * Cek status premium user saat ini.
     */
    public function status(Request $request)
    {
        $user = $request->user();
        $subscription = $user->activeSubscription;

        return response()->json([
            'success'      => true,
            'is_premium'   => $user->isPremium(),
            'subscription' => $subscription ? [
                'id'             => $subscription->id,
                'plan'           => $subscription->plan,
                'status'         => $subscription->status,
                'starts_at'      => $subscription->starts_at,
                'expires_at'     => $subscription->expires_at,
                'payment_method' => $subscription->payment_method,
            ] : null,
        ]);
    }

    /**
     * POST /api/premium/subscribe
     * Buat atau perpanjang langganan premium.
     * Payload dari Midtrans callback atau manual purchase.
     */
    public function subscribe(Request $request)
    {
        $validated = $request->validate([
            'plan'           => ['required', 'string', 'in:monthly,yearly'],
            'payment_method' => ['nullable', 'string', 'max:50'],
            'transaction_id' => ['nullable', 'string', 'max:255'],
            'amount'         => ['nullable', 'numeric', 'min:0'],
        ]);

        $user = $request->user();

        // Tentukan durasi berdasarkan plan
        $months   = $validated['plan'] === 'yearly' ? 12 : 1;
        $startsAt = now();
        $expiresAt = now()->addMonths($months);

        $subscription = Subscription::create([
            'user_id'        => $user->id,
            'plan'           => $validated['plan'],
            'status'         => 'active',
            'payment_method' => $validated['payment_method'] ?? null,
            'transaction_id' => $validated['transaction_id'] ?? null,
            'amount'         => $validated['amount'] ?? 0,
            'starts_at'      => $startsAt,
            'expires_at'     => $expiresAt,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Langganan premium berhasil diaktifkan.',
            'data'    => [
                'id'         => $subscription->id,
                'plan'       => $subscription->plan,
                'status'     => $subscription->status,
                'starts_at'  => $subscription->starts_at,
                'expires_at' => $subscription->expires_at,
            ],
        ], 201);
    }

    /**
     * POST /api/premium/cancel
     * Batalkan langganan aktif.
     */
    public function cancel(Request $request)
    {
        $user = $request->user();
        $subscription = $user->activeSubscription;

        if (!$subscription) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada langganan aktif yang dapat dibatalkan.',
            ], 404);
        }

        $subscription->update(['status' => 'cancelled']);

        return response()->json([
            'success' => true,
            'message' => 'Langganan berhasil dibatalkan.',
        ]);
    }
}
