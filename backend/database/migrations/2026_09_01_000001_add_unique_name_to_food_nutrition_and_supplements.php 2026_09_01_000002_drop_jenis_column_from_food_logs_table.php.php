<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Sebelum menambah UNIQUE, bereskan dulu kemungkinan duplikat nama
        // yang sudah terlanjur ada (mis. dari race condition sebelum fix di
        // GeminiController), supaya migration tidak gagal karena constraint
        // violation saat dijalankan.
        $this->mergeDuplicateFoodNutrition();
        $this->mergeDuplicateSupplements();

        Schema::table('food_nutrition', function (Blueprint $table) {
            $table->unique('name');
        });

        Schema::table('supplements', function (Blueprint $table) {
            $table->unique('name');
        });
    }

    public function down(): void
    {
        Schema::table('food_nutrition', function (Blueprint $table) {
            $table->dropUnique(['name']);
        });

        Schema::table('supplements', function (Blueprint $table) {
            $table->dropUnique(['name']);
        });
    }

    /**
     * Gabungkan baris food_nutrition dengan nama sama: pertahankan id
     * terkecil (paling lama), arahkan ulang food_logs.makanan_id yang
     * menunjuk ke id duplikat ke id yang dipertahankan, baru hapus baris
     * duplikatnya.
     */
    private function mergeDuplicateFoodNutrition(): void
    {
        if (!Schema::hasTable('food_nutrition')) {
            return;
        }

        $duplicateNames = DB::table('food_nutrition')
            ->select('name')
            ->groupBy('name')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('name');

        foreach ($duplicateNames as $name) {
            $rows = DB::table('food_nutrition')->where('name', $name)->orderBy('id')->get();
            $keepId = $rows->first()->id;
            $dupIds = $rows->skip(1)->pluck('id');

            if ($dupIds->isEmpty()) {
                continue;
            }

            if (Schema::hasTable('food_logs')) {
                DB::table('food_logs')->whereIn('makanan_id', $dupIds)->update(['makanan_id' => $keepId]);
            }

            DB::table('food_nutrition')->whereIn('id', $dupIds)->delete();
        }
    }

    /**
     * Sama seperti mergeDuplicateFoodNutrition(), tapi untuk supplements +
     * supplement_logs.supplement_id.
     */
    private function mergeDuplicateSupplements(): void
    {
        if (!Schema::hasTable('supplements')) {
            return;
        }

        $duplicateNames = DB::table('supplements')
            ->select('name')
            ->groupBy('name')
            ->havingRaw('COUNT(*) > 1')
            ->pluck('name');

        foreach ($duplicateNames as $name) {
            $rows = DB::table('supplements')->where('name', $name)->orderBy('id')->get();
            $keepId = $rows->first()->id;
            $dupIds = $rows->skip(1)->pluck('id');

            if ($dupIds->isEmpty()) {
                continue;
            }

            if (Schema::hasTable('supplement_logs')) {
                DB::table('supplement_logs')->whereIn('supplement_id', $dupIds)->update(['supplement_id' => $keepId]);
            }

            DB::table('supplements')->whereIn('id', $dupIds)->delete();
        }
    }
};