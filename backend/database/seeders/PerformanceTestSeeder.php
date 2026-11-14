<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Food;
use App\Models\Supplement;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\File;

class PerformanceTestSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $this->command->info('Starting Performance Test Seeding...');

        // 1. Ensure we have some Foods and Supplements to search for
        if (Food::count() < 100) {
            $this->command->info('Creating dummy foods...');
            Food::factory()->count(200)->create();
        }

        if (Supplement::count() < 50) {
            $this->command->info('Creating dummy supplements...');
            Supplement::factory()->count(100)->create();
        }

        // 2. Create Test Users and Tokens
        $userCount = 50;
        $tokens = [];

        $this->command->info("Creating $userCount test users...");

        for ($i = 1; $i <= $userCount; $i++) {
            $user = User::updateOrCreate(
                ['email' => "testuser{$i}@example.com"],
                [
                    'name' => "Test User {$i}",
                    'password' => Hash::make('password'),
                    'is_onboarding_done' => true,
                ]
            );

            // Create Sanctum Token
            $token = $user->createToken('performance-test-token')->plainTextToken;
            $tokens[] = [
                'id' => $user->id,
                'email' => $user->email,
                'token' => $token
            ];
        }

        // 3. Save tokens to a JSON file for k6 to use
        $filePath = base_path('../tokens.json');
        File::put($filePath, json_encode($tokens, JSON_PRETTY_PRINT));

        $this->command->info("Seeding complete! Tokens saved to: $filePath");
    }
}
