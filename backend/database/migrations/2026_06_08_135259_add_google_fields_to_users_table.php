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
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'google_id')) {
                $table->string('google_id')->nullable()->after('email');
            }
            if (!Schema::hasColumn('users', 'avatar')) {
                $table->string('avatar')->nullable()->after('google_id');
            }
            if (!Schema::hasColumn('users', 'is_onboarding_done')) {
                $table->boolean('is_onboarding_done')->default(false)->after('avatar');
            }
            if (!Schema::hasColumn('users', 'water_intake')) {
                $table->integer('water_intake')->default(0)->after('is_onboarding_done');
            }
            if (!Schema::hasColumn('users', 'water_intake_date')) {
                $table->date('water_intake_date')->nullable()->after('water_intake');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'google_id',
                'avatar',
                'is_onboarding_done',
                'water_intake',
                'water_intake_date',
            ]);
        });
    }
};
