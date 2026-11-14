<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
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
        'is_premium',
        'premium_until',
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
            'is_premium'         => 'boolean',
            'premium_until'      => 'datetime',
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
     * Cek apakah user memiliki akses premium yang masih berlaku.
     * Mempertimbangkan flag is_premium DAN tanggal kadaluarsa premium_until.
     */
    public function hasActivePremium(): bool
    {
        if (!$this->is_premium) {
            return false;
        }

        if ($this->premium_until === null) {
            return true; // premium tanpa batas waktu
        }

        return $this->premium_until->isFuture();
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

    public function activeSubscription(): HasOne
    {
        return $this->hasOne(Subscription::class)
            ->where('status', 'active')
            ->where(function ($q) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->latestOfMany();
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }
}