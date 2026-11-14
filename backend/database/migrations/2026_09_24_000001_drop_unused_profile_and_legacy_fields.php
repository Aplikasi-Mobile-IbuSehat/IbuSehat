<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $columns = array_values(array_filter(
                ['gender', 'birth_date', 'waist'],
                fn (string $col) => Schema::hasColumn('users', $col)
            ));
            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });

        if (Schema::hasTable('supplement_logs') && Schema::hasColumn('supplement_logs', 'reminder_sent_today')) {
            Schema::table('supplement_logs', function (Blueprint $table) {
                $table->dropColumn('reminder_sent_today');
            });
        }

        if (Schema::hasTable('workout_exercises') && Schema::hasColumn('workout_exercises', 'image_url')) {
            Schema::table('workout_exercises', function (Blueprint $table) {
                $table->dropColumn('image_url');
            });
        }

        foreach (['foods', 'food_nutrition'] as $foodTable) {
            if (Schema::hasTable($foodTable) && Schema::hasColumn($foodTable, 'image')) {
                Schema::table($foodTable, function (Blueprint $table) {
                    $table->dropColumn('image');
                });
            }
        }

        Schema::dropIfExists('sleep_sessions');
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'waist')) {
                $table->float('waist')->nullable();
            }
            if (!Schema::hasColumn('users', 'birth_date')) {
                $table->date('birth_date')->nullable();
            }
            if (!Schema::hasColumn('users', 'gender')) {
                $table->string('gender', 20)->nullable();
            }
        });

        if (Schema::hasTable('supplement_logs') && !Schema::hasColumn('supplement_logs', 'reminder_sent_today')) {
            Schema::table('supplement_logs', function (Blueprint $table) {
                $table->boolean('reminder_sent_today')->default(false);
            });
        }

        if (Schema::hasTable('workout_exercises') && !Schema::hasColumn('workout_exercises', 'image_url')) {
            Schema::table('workout_exercises', function (Blueprint $table) {
                $table->string('image_url')->nullable();
            });
        }

        foreach (['foods', 'food_nutrition'] as $foodTable) {
            if (Schema::hasTable($foodTable) && !Schema::hasColumn($foodTable, 'image')) {
                Schema::table($foodTable, function (Blueprint $table) {
                    $table->string('image')->nullable();
                });
            }
        }

        if (!Schema::hasTable('sleep_sessions')) {
            Schema::create('sleep_sessions', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->dateTime('sleep_time');
                $table->dateTime('wake_time');
                $table->unsignedInteger('duration_minutes');
                $table->unsignedTinyInteger('sleep_score')->default(0);
                $table->timestamps();
            });
        }
    }
};
