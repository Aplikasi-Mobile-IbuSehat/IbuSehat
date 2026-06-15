<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatUsage extends Model
{
    protected $fillable = [
        'user_id',
        'usage_date',
        'count',
    ];

    protected $casts = [
        'usage_date' => 'date',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}