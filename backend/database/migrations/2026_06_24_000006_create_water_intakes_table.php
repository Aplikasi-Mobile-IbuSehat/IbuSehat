<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('water_intakes')) {
            Schema::create('water_intakes', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->integer('amount_ml');         // jumlah air dalam mL
                $table->date('date');                  // tanggal pencatatan
                $table->timestamps();

                // Pastikan unique per user per hari (upsert-friendly)
                $table->index(['user_id', 'date']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('water_intakes');
    }
};
