<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $table = 'payments';

    protected $fillable = [
        'user_id',
        'order_id',
        'amount',
        'plan_type',
        'duration_days',
        'snap_token',
        'status',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}