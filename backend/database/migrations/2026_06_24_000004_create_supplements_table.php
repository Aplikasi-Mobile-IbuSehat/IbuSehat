<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('supplements')) {
            Schema::create('supplements', function (Blueprint $table) {
                $table->id();
                $table->string('name', 120)->index();
                $table->text('composition')->nullable();
                $table->string('packaging', 190)->nullable();
                $table->text('usage_rule')->nullable();
                $table->string('image')->nullable();
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('supplements');
    }
};
