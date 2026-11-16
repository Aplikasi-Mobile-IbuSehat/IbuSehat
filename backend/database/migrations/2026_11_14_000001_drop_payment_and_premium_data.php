<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Pembayaran & Premium dihapus total. Akses Chatbot AI dan program latihan
 * kini ditentukan oleh kelengkapan data kesehatan (User::hasCompleteHealthData),
 * jadi kolom premium di users serta tabel payments/subscriptions tidak dipakai.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('payments');

        $columns = array_values(array_filter(
            ['is_premium', 'premium_until'],
            fn (string $col) => Schema::hasColumn('users', $col)
        ));

        if ($columns !== []) {
            Schema::table('users', function (Blueprint $table) use ($columns) {
                $table->dropColumn($columns);
            });
        }
    }

    /**
     * Mengembalikan struktur (bukan data) yang dihapus.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'is_premium')) {
                $table->boolean('is_premium')->default(false);
            }
            if (!Schema::hasColumn('users', 'premium_until')) {
                $table->timestamp('premium_until')->nullable();
            }
        });

        if (!Schema::hasTable('payments')) {
            Schema::create('payments', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->string('order_id')->unique();
                $table->unsignedBigInteger('amount');
                $table->string('plan_type')->nullable();
                $table->unsignedInteger('duration_days')->nullable();
                $table->string('snap_token')->nullable();
                $table->string('status')->default('pending');
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('subscriptions')) {
            Schema::create('subscriptions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->string('plan', 30)->default('monthly');
                $table->string('status', 20)->default('pending');
                $table->string('payment_method', 50)->nullable();
                $table->string('transaction_id')->nullable()->unique();
                $table->decimal('amount', 10, 2)->default(0);
                $table->timestamp('starts_at')->nullable();
                $table->timestamp('expires_at')->nullable();
                $table->timestamps();
                $table->index(['user_id', 'status']);
            });
        }
    }
};
