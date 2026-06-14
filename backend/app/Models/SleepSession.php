<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SleepSession extends Model
{
    protected $fillable = [
        'user_id',
        'sleep_time',
        'wake_time',
        'duration_minutes',
        'sleep_score',
    ];

    protected function casts(): array
    {
        return [
            'sleep_time' => 'datetime',
            'wake_time' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
