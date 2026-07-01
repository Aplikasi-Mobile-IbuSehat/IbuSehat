<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserStreak extends Model
{
    protected $fillable = [
        'user_id',
        'streak_active',
        'streak_longest',
        'last_workout_date',
    ];

    protected $casts = [
        'last_workout_date' => 'date',
        'streak_active' => 'integer',
        'streak_longest' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
