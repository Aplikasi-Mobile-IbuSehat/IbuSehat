<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('food_logs')) {
            Schema::create('food_logs', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->unsignedBigInteger('makanan_id')->nullable(); // FK lunak ke foods
                $table->string('nama_makanan', 120);
                $table->float('weight')->default(0);        // gram
                $table->float('kcal')->default(0);
                $table->float('protein')->default(0);
                $table->float('carbs')->default(0);
                $table->float('fat')->default(0);
                $table->string('category', 100)->nullable();
                $table->string('jenis', 30)->nullable();    // halal/haram/netral
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('food_logs');
    }
};
