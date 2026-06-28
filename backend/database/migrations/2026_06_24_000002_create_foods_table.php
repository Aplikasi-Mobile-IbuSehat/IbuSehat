<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('foods', function (Blueprint $table) {
            $table->id();
            $table->string('name', 120)->index();
            $table->string('category', 100)->nullable()->index();
            $table->float('calories')->default(0);     // kkal
            $table->float('protein')->default(0);      // gram
            $table->float('carbohydrate')->default(0); // gram
            $table->float('fat')->default(0);          // gram
            $table->string('image')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('foods');
    }
};
