<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sleep_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('sleep_time', 5);
            $table->string('wake_time', 5);
            $table->unsignedTinyInteger('night_wakings')->default(0);
            $table->unsignedSmallInteger('awake_duration')->default(0);
            $table->string('mood', 32);
            $table->text('notes')->nullable();
            $table->unsignedTinyInteger('score')->default(0);
            $table->string('category', 32);
            $table->unsignedSmallInteger('sleep_duration_minutes')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sleep_logs');
    }
};
