<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'google_id',
        'avatar',
        'email_verified_at',
        'is_onboarding_done',
        'water_intake',
        'water_intake_date',
        'fcm_token',
        'is_premium',
        'premium_until',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_onboarding_done' => 'boolean',
            'water_intake' => 'integer',
            'water_intake_date' => 'date',
            'is_premium' => 'boolean',
            'premium_until' => 'datetime',
        ];
    }

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
            return true; // premium tanpa batas waktu (jaga-jaga)
        }

        return $this->premium_until->isFuture();
    }
}