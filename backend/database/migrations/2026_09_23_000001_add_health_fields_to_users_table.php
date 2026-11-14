<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'target_weight')) {
                $table->float('target_weight')->nullable()->after('weight');
            }
            if (!Schema::hasColumn('users', 'age')) {
                $table->unsignedTinyInteger('age')->nullable()->after('target_weight');
            }
            if (!Schema::hasColumn('users', 'delivery_date')) {
                $table->date('delivery_date')->nullable()->after('birth_date');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $columns = array_values(array_filter(
                ['target_weight', 'age', 'delivery_date'],
                fn (string $col) => Schema::hasColumn('users', $col)
            ));
            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });
    }
};
