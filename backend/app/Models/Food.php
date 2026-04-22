<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Food extends Model
{
    protected $table = 'food_nutrition';

    protected $fillable = [
        'name',
        'category',
        'calories',
        'fat',
        'carbohydrate',
        'protein',
    ];

    public $timestamps = true;
}
