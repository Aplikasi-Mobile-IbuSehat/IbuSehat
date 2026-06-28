<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SupplementLog extends Model
{
    use HasFactory;

    protected $table = 'supplement_logs';

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
        'supplement_id' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
