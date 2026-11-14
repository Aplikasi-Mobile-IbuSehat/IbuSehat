<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\FoodLog;
use App\Models\WaterIntake;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProgressSyncTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test adding food log via diet API and verifying it works
     */
    public function test_add_food_log_via_diet_api(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/diet/food/add', [
            'food_name' => 'Nasi Goreng',
            'calories' => 350.5,
            'weight_gram' => 200,
            'logged_at' => Carbon::now()->toDateTimeString(),
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'status' => 'success',
            ]);

        $this->assertDatabaseHas('food_logs', [
            'user_id' => $user->id,
            'nama_makanan' => 'Nasi Goreng',
            'kcal' => 350.5,
            'weight' => 200,
        ]);
    }

    /**
     * Test adding water intake via diet API and verifying it works
     */
    public function test_add_water_intake_via_diet_api(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/diet/water/add', [
            'amount_ml' => 250,
            'logged_at' => Carbon::now()->toDateString(),
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'status' => 'success',
            ]);

        $this->assertDatabaseHas('water_intakes', [
            'user_id' => $user->id,
            'amount_ml' => 250,
        ]);
    }

    /**
     * Test getting progress summary calculates targets and totals correctly
     */
    public function test_get_progress_summary(): void
    {
        $user = User::factory()->create([
            'weight' => 60,
            'height' => 165,
            'age' => 31,
        ]);
        Sanctum::actingAs($user);

        $today = Carbon::today();
        
        // Add water intakes
        WaterIntake::create([
            'user_id' => $user->id,
            'amount_ml' => 500,
            'date' => $today->toDateString(),
        ]);
        WaterIntake::create([
            'user_id' => $user->id,
            'amount_ml' => 1000,
            'date' => $today->copy()->subDays(2)->toDateString(),
        ]);

        // Add food logs using model instances to set created_at directly
        $log1 = new FoodLog([
            'user_id' => $user->id,
            'nama_makanan' => 'Nasi',
            'kcal' => 300,
            'weight' => 150,
        ]);
        $log1->created_at = $today;
        $log1->save();

        $log2 = new FoodLog([
            'user_id' => $user->id,
            'nama_makanan' => 'Ayam',
            'kcal' => 250,
            'weight' => 100,
        ]);
        $log2->created_at = $today->copy()->subDays(1);
        $log2->save();

        $response = $this->getJson('/api/progress/summary');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'data' => [
                    'weekly' => [
                        'water' => [
                            'total_ml',
                            'target_ml',
                            'percent',
                            'daily',
                            'average',
                            'today',
                            'target_daily_ml',
                        ],
                        'nutrition' => [
                            'total_kkal',
                            'target_kkal',
                            'percent',
                            'daily',
                            'average',
                            'today',
                            'target_daily_kkal',
                        ],
                    ],
                ],
            ]);

        $data = $response->json('data.weekly');

        // Check water values
        // today water is 500
        $this->assertEquals(500, $data['water']['today']);
        // total water is 1500
        $this->assertEquals(1500, $data['water']['total_ml']);
        // daily target: 60 * 35 = 2100 ml
        $this->assertEquals(2100, $data['water']['target_daily_ml']);
        // weekly target: 2100 * 7 = 14700 ml
        $this->assertEquals(14700, $data['water']['target_ml']);

        // Check nutrition values
        // today nutrition is 300
        $this->assertEquals(300, $data['nutrition']['today']);
        // total nutrition is 550
        $this->assertEquals(550, $data['nutrition']['total_kkal']);
    }
}
