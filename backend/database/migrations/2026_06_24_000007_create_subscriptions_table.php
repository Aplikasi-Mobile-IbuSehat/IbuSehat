<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('subscriptions')) {
            Schema::create('subscriptions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->string('plan', 30)->default('monthly'); // monthly | yearly
                $table->string('status', 20)->default('pending'); // pending | active | expired | cancelled
                $table->string('payment_method', 50)->nullable(); // midtrans, etc.
                $table->string('transaction_id')->nullable()->unique(); // ID dari Midtrans
                $table->decimal('amount', 10, 2)->default(0);
                $table->timestamp('starts_at')->nullable();
                $table->timestamp('expires_at')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'status']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
