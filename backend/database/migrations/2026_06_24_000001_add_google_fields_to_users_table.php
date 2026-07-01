<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Tambah kolom Google OAuth, profil, onboarding, dan FCM ke tabel users.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Google OAuth fields
            if (!Schema::hasColumn('users', 'google_id')) {
                $table->string('google_id')->nullable()->unique()->after('email');
            }
            if (!Schema::hasColumn('users', 'avatar')) {
                $table->string('avatar')->nullable()->after('google_id');
            }

            // Onboarding flag
            if (!Schema::hasColumn('users', 'is_onboarding_done')) {
                $table->boolean('is_onboarding_done')->default(false)->after('avatar');
            }

            // Firebase Cloud Messaging token
            if (!Schema::hasColumn('users', 'fcm_token')) {
                $table->string('fcm_token')->nullable()->after('is_onboarding_done');
            }

            // Health/profile data
            if (!Schema::hasColumn('users', 'height')) {
                $table->float('height')->nullable()->after('fcm_token');        // cm
            }
            if (!Schema::hasColumn('users', 'weight')) {
                $table->float('weight')->nullable()->after('height');           // kg
            }
            if (!Schema::hasColumn('users', 'waist')) {
                $table->float('waist')->nullable()->after('weight');            // cm
            }
            if (!Schema::hasColumn('users', 'birth_date')) {
                $table->date('birth_date')->nullable()->after('waist');
            }
            if (!Schema::hasColumn('users', 'gender')) {
                $table->string('gender', 20)->nullable()->after('birth_date');  // 'male'|'female'
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $columnsToDrop = [];
            foreach (['google_id', 'avatar', 'is_onboarding_done', 'fcm_token', 'height', 'weight', 'waist', 'birth_date', 'gender'] as $col) {
                if (Schema::hasColumn('users', $col)) {
                    $columnsToDrop[] = $col;
                }
            }
            if (!empty($columnsToDrop)) {
                $table->dropColumn($columnsToDrop);
            }
        });
    }
};
