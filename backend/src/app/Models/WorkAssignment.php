<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

class WorkAssignment extends Model
{
    use HasFactory;

    protected $fillable = [
        'assignment_number',
        'start_date',
        'end_date',
        'destination',
        'purpose',
        'attachment',
        'is_active',
        'created_by',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'is_active' => 'boolean',
    ];

    public function employees()
    {
        return $this->belongsToMany(
            Employee::class,
            'work_assignment_employees'
        )->withTimestamps();
    }

    public function createdBy()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }

    public function scopeActiveOn(
        Builder $query,
        Carbon|string|null $date = null
    ): Builder {
        $date = $date
            ? Carbon::parse($date)->toDateString()
            : Carbon::today()->toDateString();

        return $query
            ->where('is_active', true)
            ->whereDate('start_date', '<=', $date)
            ->whereDate('end_date', '>=', $date);
    }
}
