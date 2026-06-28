<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WorkoutLog extends Model
{
    protected $fillable = [
        'user_id',
        'workout_id',
        'completed_at',
        'is_completed',
        'duration_seconds',
    ];

    protected $casts = [
        'completed_at' => 'date',
        'is_completed' => 'boolean',
        'duration_seconds' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function workout(): BelongsTo
    {
        return $this->belongsTo(WorkoutProgram::class, 'workout_id');
    }
}
