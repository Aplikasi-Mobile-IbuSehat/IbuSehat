<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('food_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->nullable();
            $table->string('makanan_id')->nullable();
            $table->string('nama_makanan');
            $table->decimal('weight', 8, 2);
            $table->decimal('kcal', 8, 2);
            $table->decimal('protein', 8, 2)->default(0);
            $table->decimal('carbs', 8, 2)->default(0);
            $table->decimal('fat', 8, 2)->default(0);
            $table->string('category')->nullable();
            $table->string('jenis')->nullable();
            $table->timestamps();

            // ✅ Index SETELAH kolom didefinisikan
            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('food_logs');
    }
};