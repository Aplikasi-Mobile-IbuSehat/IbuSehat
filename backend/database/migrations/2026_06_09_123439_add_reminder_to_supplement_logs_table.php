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
        Schema::table('supplement_logs', function (Blueprint $table) {

            if (!Schema::hasColumn('supplement_logs', 'reminder_time')) {
                $table->time('reminder_time')->nullable()->after('is_taken');
            }

            if (!Schema::hasColumn('supplement_logs', 'reminder_sent_today')) {
                $table->boolean('reminder_sent_today')
                    ->default(false)
                    ->after('reminder_time');
            }
        });
    }

    public function down(): void
    {
        Schema::table('supplement_logs', function (Blueprint $table) {

            if (Schema::hasColumn('supplement_logs', 'reminder_time')) {
                $table->dropColumn('reminder_time');
            }

            if (Schema::hasColumn('supplement_logs', 'reminder_sent_today')) {
                $table->dropColumn('reminder_sent_today');
            }
        });
    }
};
