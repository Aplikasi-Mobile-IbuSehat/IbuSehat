<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WorkoutExercise extends Model
{
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'workout_program_id',
        'name',
        'duration',
        'difficulty',
        'image_asset',
        'description',
        'instructions',
        'equipment',
        'target_muscle',
        'video_asset',
        'order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'instructions' => 'array',
        ];
    }

    public function workoutProgram(): BelongsTo
    {
        return $this->belongsTo(WorkoutProgram::class);
    }
}
