<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmployeeEvaluation extends Model
{
    use HasFactory;

    protected $fillable = [
        'employee_id',
        'month',
        'year',
        'attendance_percentage',
        'total_attendance',
        'late_count',
        'early_leave_count',
        'absent_count',
        'final_score',
        'status',
    ];

    /**
     * Relasi ke Employee
     */
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    /**
     * Accessor: format periode (contoh: Januari 2026)
     */
    public function getPeriodAttribute()
    {
        return \Carbon\Carbon::create()
            ->month($this->month)
            ->translatedFormat('F') . ' ' . $this->year;
    }

    /**
     * Scope: filter berdasarkan periode
     */
    public function scopeByPeriod($query, $month, $year)
    {
        return $query->where('month', $month)
                     ->where('year', $year);
    }

    /**
     * Scope: ranking (urut berdasarkan skor tertinggi)
     */
    public function scopeRanking($query)
    {
        return $query->orderByDesc('final_score');
    }

    /**
     * Accessor: badge status (untuk UI)
     */
    public function getStatusBadgeAttribute()
    {
        return match ($this->status) {
            'sangat disiplin' => 'success',   // hijau
            'cukup' => 'warning',             // kuning
            'pembinaan' => 'danger',          // merah
            default => 'secondary',
        };
    }
}
