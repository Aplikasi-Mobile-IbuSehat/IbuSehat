<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoodLog extends Model
{
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
    ];
}