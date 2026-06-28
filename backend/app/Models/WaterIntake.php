<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WaterIntake extends Model
{
    use HasFactory;

    protected $table = 'water_intakes';

    protected $fillable = [
        'user_id',
        'amount_ml',
        'date',
    ];

    protected $casts = [
        'amount_ml' => 'integer',
        'date'      => 'date',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
