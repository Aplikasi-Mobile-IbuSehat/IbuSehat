<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupplementLog extends Model
{
    protected $fillable = [
        'user_id',
        'supplement_id',
        'nama_suplemen',
        'komposisi',
        'kemasan',
        'aturan_pakai',
        'gambar',
        'source',
        'reminder_time',
        'is_taken',
    ];

    protected $casts = [
        'is_taken' => 'boolean',
    ];
}
