<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('supplement_logs')) {
            Schema::create('supplement_logs', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->unsignedBigInteger('supplement_id')->nullable(); // FK lunak
                $table->string('nama_suplemen', 190);
                $table->text('komposisi')->nullable();
                $table->string('kemasan', 190)->nullable();
                $table->text('aturan_pakai')->nullable();
                $table->string('gambar')->nullable();
                $table->string('source', 100)->default('Halodoc');
                $table->time('reminder_time')->nullable();
                $table->boolean('is_taken')->default(false);
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('supplement_logs');
    }
};
