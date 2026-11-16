<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Memori percakapan IbuSehat AI, disimpan di server:
 * - chat_sessions : satu baris per sesi chat milik satu user, beserta
 *                   ringkasan bergulir dari pesan-pesan lama.
 * - chat_messages : isi percakapan per sesi (giliran user & model).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('chat_sessions')) {
            Schema::create('chat_sessions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->string('title', 80)->nullable();
                // Ringkasan pesan lama (id <= summarized_until_id) agar AI tetap
                // paham konteks tanpa mengirim seluruh riwayat.
                $table->text('summary')->nullable();
                $table->unsignedBigInteger('summarized_until_id')->nullable();
                $table->timestamp('last_message_at')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'last_message_at']);
            });
        }

        if (!Schema::hasTable('chat_messages')) {
            Schema::create('chat_messages', function (Blueprint $table) {
                $table->id();
                $table->foreignId('chat_session_id')->constrained()->cascadeOnDelete();
                $table->string('role', 10);                 // user | model
                $table->text('content');
                $table->string('kind', 20)->default('chat'); // chat | emergency
                $table->timestamp('created_at')->nullable();

                $table->index(['chat_session_id', 'id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_messages');
        Schema::dropIfExists('chat_sessions');
    }
};
