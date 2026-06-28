<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Food extends Model
{
    use HasFactory;

    protected $table = 'foods';

    protected $fillable = [
        'name',
        'category',
        'calories',
        'protein',
        'carbohydrate',
        'fat',
        'image',
    ];

    protected $casts = [
        'calories'     => 'float',
        'protein'      => 'float',
        'carbohydrate' => 'float',
        'fat'          => 'float',
    ];
}
