<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SleepLog extends Model
{
    protected $fillable = [
        'user_id',
        'sleep_time',
        'wake_time',
        'night_wakings',
        'awake_duration',
        'mood',
        'notes',
        'score',
        'category',
        'sleep_duration_minutes',
        'is_saved',
    ];

    protected $casts = [
        'is_saved' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
