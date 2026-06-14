<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sleep_logs', function (Blueprint $table) {
            $table->boolean('is_saved')->default(false)->after('sleep_duration_minutes');
        });
    }

    public function down(): void
    {
        Schema::table('sleep_logs', function (Blueprint $table) {
            $table->dropColumn('is_saved');
        });
    }
};
