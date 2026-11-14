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
        if (Schema::hasTable('makanan_nutrisi')) {
            Schema::table('makanan_nutrisi', function (Blueprint $table) {
                $table->index('nama_makanan', 'makanan_nutrisi_nama_idx');
                $table->index('kategori', 'makanan_nutrisi_kategori_idx');
                $table->index('jenis', 'makanan_nutrisi_jenis_idx');
            });
        }

        if (Schema::hasTable('food_logs')) {
            Schema::table('food_logs', function (Blueprint $table) {
                $table->index('created_at', 'food_logs_created_at_idx');
                $table->index(['user_id', 'created_at'], 'food_logs_user_created_idx');
                $table->index('nama_makanan', 'food_logs_nama_makanan_idx');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('makanan_nutrisi')) {
            Schema::table('makanan_nutrisi', function (Blueprint $table) {
                $table->dropIndex('makanan_nutrisi_nama_idx');
                $table->dropIndex('makanan_nutrisi_kategori_idx');
                $table->dropIndex('makanan_nutrisi_jenis_idx');
            });
        }

        if (Schema::hasTable('food_logs')) {
            Schema::table('food_logs', function (Blueprint $table) {
                $table->dropIndex('food_logs_created_at_idx');
                $table->dropIndex('food_logs_user_created_idx');
                $table->dropIndex('food_logs_nama_makanan_idx');
            });
        }
    }
};
