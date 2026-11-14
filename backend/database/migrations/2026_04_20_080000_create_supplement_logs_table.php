<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('supplement_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->nullable();
            $table->unsignedBigInteger('supplement_id')->nullable();
            $table->string('nama_suplemen');
            $table->text('komposisi')->nullable();
            $table->string('kemasan')->nullable();
            $table->text('aturan_pakai')->nullable();
            $table->string('gambar')->nullable();
            $table->string('source')->nullable();
            $table->string('reminder_time', 5)->nullable(); // HH:mm
            $table->boolean('is_taken')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index('supplement_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('supplement_logs');
    }
};
