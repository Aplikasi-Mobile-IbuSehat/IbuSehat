<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WorkoutProgram extends Model
{
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'description',
        'image_asset',
        'total_exercises',
        'category',
        'is_active',
    ];

    /**
     * @var list<string>
     */
    protected $appends = ['image_url'];

    public function exercises(): HasMany
    {
        return $this->hasMany(WorkoutExercise::class)->orderBy('order');
    }

    public function getImageUrlAttribute(): ?string
    {
        if (empty($this->image_asset)) {
            return null;
        }

        return url('/assets/images/programs/' . $this->image_asset);
    }
}
