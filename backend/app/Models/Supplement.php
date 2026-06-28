<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Supplement extends Model
{
    use HasFactory;

    protected $table = 'supplements';

    protected $fillable = [
        'name',
        'composition',
        'packaging',
        'usage_rule',
        'image',
    ];
}
