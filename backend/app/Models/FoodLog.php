<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FoodLog extends Model
{
    use HasFactory;

    protected $table = 'food_logs';

    protected $fillable = [
        'user_id',
        'makanan_id',
        'nama_makanan',
        'weight',
        'kcal',
        'protein',
        'carbs',
        'fat',
        'category',
        'jenis',
    ];

    protected $casts = [
        'weight'     => 'float',
        'kcal'       => 'float',
        'protein'    => 'float',
        'carbs'      => 'float',
        'fat'        => 'float',
        'makanan_id' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
