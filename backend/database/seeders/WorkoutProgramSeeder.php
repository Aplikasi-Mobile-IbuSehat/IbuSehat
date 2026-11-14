<?php

namespace Database\Seeders;

use App\Models\WorkoutExercise;
use App\Models\WorkoutProgram;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class WorkoutProgramSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        WorkoutExercise::query()->delete();
        WorkoutProgram::query()->delete();

        /** @var array<string, list<array<string, mixed>>> $catalog */
        $catalog = require database_path('data/workout_exercise_catalog.php');

        $programs = [
            [
                'name' => 'Latihan Kalistenik',
                'description' => 'Program kalistenik untuk pemulihan kebugaran ibu pasca melahirkan.',
                'image_asset' => 'kalistenik.png',
                'total_exercises' => 36,
                'category' => 'Pemula',
            ],
            [
                'name' => 'Kalistenik dengan Peralatan',
                'description' => 'Latihan kalistenik dengan bantuan alat sederhana di rumah.',
                'image_asset' => 'kalistenik_peralatan.png',
                'total_exercises' => 36,
                'category' => 'Menengah',
            ],
            [
                'name' => 'Gym',
                'description' => 'Program latihan gym bertahap dengan fokus kekuatan tubuh.',
                'image_asset' => 'gym.png',
                'total_exercises' => 36,
                'category' => 'Berpengalaman',
            ],
            [
                'name' => 'Program Abs',
                'description' => 'Program penguatan area perut dan core secara aman.',
                'image_asset' => 'program_abs.png',
                'total_exercises' => 36,
                'category' => 'Menengah',
            ],
            [
                'name' => 'Latihan Mikro',
                'description' => 'Latihan berdurasi singkat yang bisa dilakukan kapan saja.',
                'image_asset' => 'latihan_mikro.png',
                'total_exercises' => 36,
                'category' => 'Pemula',
            ],
            [
                'name' => 'Rencana Pilates Dinding',
                'description' => 'Program pilates dengan bantuan dinding untuk stabilitas.',
                'image_asset' => 'pilates_dinding.png',
                'total_exercises' => 36,
                'category' => 'Menengah',
            ],
        ];

        foreach ($programs as $programData) {
            $program = WorkoutProgram::create([
                ...$programData,
                'is_active' => true,
            ]);

            $exercises = [];
            $order = 1;

            foreach ($catalog as $difficulty => $items) {
                foreach ($items as $item) {
                    $slug = Str::slug($item['name']);
                    $exercises[] = [
                        'name' => $item['name'],
                        'duration' => $item['duration'],
                        'difficulty' => $difficulty,
                        'image_asset' => $item['image_asset'],
                        'description' => $item['description'],
                        'instructions' => $item['instructions'],
                        'equipment' => $item['equipment'],
                        'target_muscle' => $item['target_muscle'],
                        'video_asset' => $slug . '.mp4',
                        'order' => $order++,
                    ];
                }
            }

            $program->exercises()->createMany($exercises);
        }
    }
}
