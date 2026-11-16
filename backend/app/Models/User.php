<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'google_id',
        'avatar',
        'email_verified_at',
        'is_onboarding_done',
        'fcm_token',
        'height',
        'weight',
        'target_weight',
        'age',
        'delivery_date',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at'  => 'datetime',
            'password'           => 'hashed',
            'is_onboarding_done' => 'boolean',
            'height'             => 'float',
            'weight'             => 'float',
            'target_weight'      => 'float',
            'age'                => 'integer',
            'delivery_date'      => 'date',
        ];
    }

    // -------------------------------------------------------------------------
    // Business logic
    // -------------------------------------------------------------------------

    /**
     * Data kesehatan dianggap lengkap jika semua field berikut terisi dan
     * berada dalam rentang validasi yang sama dengan form (lihat
     * ProfileController::update dan AuthController::updateOnboarding).
     * Ini syarat akses Chatbot AI dan program latihan.
     */
    public function hasCompleteHealthData(): bool
    {
        $inRange = fn ($value, float $min, float $max): bool =>
            $value !== null && is_numeric($value) && $value >= $min && $value <= $max;

        return $inRange($this->height, 100, 220)
            && $inRange($this->weight, 30, 200)
            && $inRange($this->target_weight, 30, 200)
            && $inRange($this->age, 12, 80)
            && $this->delivery_date !== null;
    }

    // -------------------------------------------------------------------------
    // Relationships
    // -------------------------------------------------------------------------

    public function activities(): HasMany
    {
        return $this->hasMany(Activity::class);
    }

    public function sleepLogs(): HasMany
    {
        return $this->hasMany(SleepLog::class);
    }

    public function foodLogs(): HasMany
    {
        return $this->hasMany(FoodLog::class);
    }

    public function supplementLogs(): HasMany
    {
        return $this->hasMany(SupplementLog::class);
    }

    public function waterIntakes(): HasMany
    {
        return $this->hasMany(WaterIntake::class);
    }
}
