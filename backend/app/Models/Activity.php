<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Activity extends Model
{
    protected $fillable = [
        'user_id',
        'type',
        'title',
        'distance_km',
        'duration_seconds',
        'pace',
        'calories',
        'coordinates',
        'started_at',
        'ended_at',
    ];

    protected function casts(): array
    {
        return [
            'coordinates' => 'array',
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
            'distance_km' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
