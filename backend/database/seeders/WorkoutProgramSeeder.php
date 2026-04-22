<?php

namespace Database\Seeders;

use App\Models\WorkoutProgram;
use Illuminate\Database\Seeder;

class WorkoutProgramSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $programs = [
            ['name' => 'Latihan Kalistenik', 'description' => 'Program kalistenik untuk pemulihan kebugaran ibu pasca melahirkan.', 'image_asset' => 'kalistenik.png', 'total_exercises' => 28, 'category' => 'Pemula'],
            ['name' => 'Kalistenik dengan Peralatan', 'description' => 'Latihan kalistenik dengan bantuan alat sederhana di rumah.', 'image_asset' => 'kalistenik_peralatan.png', 'total_exercises' => 28, 'category' => 'Menengah'],
            ['name' => 'Gym', 'description' => 'Program latihan gym bertahap dengan fokus kekuatan tubuh.', 'image_asset' => 'gym.png', 'total_exercises' => 28, 'category' => 'Berpengalaman'],
            ['name' => 'Program Abs', 'description' => 'Program penguatan area perut dan core secara aman.', 'image_asset' => 'program_abs.png', 'total_exercises' => 12, 'category' => 'Menengah'],
            ['name' => 'Latihan Mikro', 'description' => 'Latihan berdurasi singkat yang bisa dilakukan kapan saja.', 'image_asset' => 'latihan_mikro.png', 'total_exercises' => 28, 'category' => 'Pemula'],
            ['name' => 'Rencana Pilates Dinding', 'description' => 'Program pilates dengan bantuan dinding untuk stabilitas.', 'image_asset' => 'pilates_dinding.png', 'total_exercises' => 28, 'category' => 'Menengah'],
        ];

        foreach ($programs as $programData) {
            $program = WorkoutProgram::create([
                ...$programData,
                'is_active' => true,
            ]);

            $program->exercises()->createMany([
                [
                    'name' => 'Pemanasan Ringan',
                    'duration' => '10 mnt',
                    'difficulty' => 'Pemula',
                    'image_asset' => 'exercise_warmup.png',
                    'description' => 'Pemanasan untuk mempersiapkan otot sebelum latihan inti.',
                    'instructions' => [
                        'Berdiri tegak dan tarik napas dalam.',
                        'Lakukan peregangan leher dan bahu selama 2 menit.',
                        'Lanjutkan dengan gerakan tangan melingkar.',
                    ],
                    'equipment' => 'None / Mat (optional)',
                    'target_muscle' => 'Full Body',
                    'video_asset' => 'pemanasan_ringan.mp4',
                    'order' => 1,
                ],
                [
                    'name' => 'Squat Dasar',
                    'duration' => '15 mnt',
                    'difficulty' => 'Menengah',
                    'image_asset' => 'exercise_squat.png',
                    'description' => 'Latihan squat untuk memperkuat kaki dan bokong.',
                    'instructions' => [
                        'Buka kaki selebar bahu.',
                        'Turunkan tubuh perlahan seperti duduk.',
                        'Kembali berdiri sambil menjaga punggung tetap lurus.',
                    ],
                    'equipment' => 'None',
                    'target_muscle' => 'Kaki & Bokong',
                    'video_asset' => 'squat_dasar.mp4',
                    'order' => 2,
                ],
                [
                    'name' => 'Pendinginan',
                    'duration' => '8 mnt',
                    'difficulty' => 'Berpengalaman',
                    'image_asset' => 'exercise_cooldown.png',
                    'description' => 'Gerakan pendinginan untuk menurunkan detak jantung.',
                    'instructions' => [
                        'Lakukan peregangan hamstring selama 1 menit.',
                        'Tarik napas perlahan sambil peregangan bahu.',
                        'Akhiri dengan relaksasi pernapasan.',
                    ],
                    'equipment' => 'Mat (optional)',
                    'target_muscle' => 'Full Body',
                    'video_asset' => 'pendinginan.mp4',
                    'order' => 3,
                ],
            ]);
        }
    }
}
