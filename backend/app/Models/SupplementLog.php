<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

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
        'is_taken'      => 'boolean',
        'reminder_time' => 'string', // format "HH:MM"
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
