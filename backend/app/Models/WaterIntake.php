<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Builder;

class WaterIntake extends Model
{
    protected $fillable = [
        'user_id',
        'amount_ml',
        'date',
    ];

    protected $casts = [
        'date'      => 'date',
        'amount_ml' => 'integer',
    ];

    // Scope untuk query per tanggal
    public function scopeForDate(Builder $query, string $date): Builder
    {
        return $query->whereDate('date', $date);
    }

    // Scope untuk query mingguan
    public function scopeForWeek(Builder $query, string $startDate, string $endDate): Builder
    {
        return $query->whereBetween('date', [$startDate, $endDate]);
    }
}