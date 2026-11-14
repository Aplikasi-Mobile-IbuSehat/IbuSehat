<?php
// database/migrations/xxxx_create_water_intakes_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('water_intakes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('amount_ml');
            $table->date('date');
            $table->timestamps();

            $table->index(['user_id', 'date']); // penting untuk query performa
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('water_intakes');
    }
};