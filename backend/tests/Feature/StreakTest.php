<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserStreak;
use App\Models\WorkoutLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StreakTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test completing first workout creates streak
     */
    public function test_complete_first_workout_creates_streak(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/workout/complete', [
            'workout_id' => null,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'streak_active' => 1,
                    'streak_longest' => 1,
                    'is_new_streak_day' => true,
                ],
            ]);

        $this->assertDatabaseHas('user_streaks', [
            'user_id' => $user->id,
            'streak_active' => 1,
            'streak_longest' => 1,
        ]);

        $this->assertDatabaseHas('workout_logs', [
            'user_id' => $user->id,
            'is_completed' => true,
        ]);
    }

    /**
     * Test completing second workout same day doesn't increase streak
     */
    public function test_complete_second_workout_same_day_does_not_increase_streak(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // First workout
        $this->postJson('/api/workout/complete');

        // Second workout same day
        $response = $this->postJson('/api/workout/complete');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'streak_active' => 1,
                    'is_new_streak_day' => false,
                ],
            ]);
    }

    /**
     * Test get streak returns correct data
     */
    public function test_get_streak_returns_correct_data(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        // Create a workout log
        $this->postJson('/api/workout/complete');

        $response = $this->getJson('/api/streak');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'streak_active',
                    'streak_longest',
                    'total_aktivitas',
                    'hari_aktif_bulan_ini',
                    'calendar',
                ],
            ]);
    }

    /**
     * Test unauthenticated request fails
     */
    public function test_unauthenticated_request_fails(): void
    {
        $response = $this->postJson('/api/workout/complete');
        $response->assertStatus(401);

        $response = $this->getJson('/api/streak');
        $response->assertStatus(401);
    }

    /**
     * Test invalid workout_id validation
     */
    public function test_invalid_workout_id_fails_validation(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/workout/complete', [
            'workout_id' => 99999, // Non-existent workout
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['workout_id']);
    }
}
