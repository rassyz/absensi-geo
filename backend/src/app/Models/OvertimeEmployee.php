<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot; // PERHATIKAN: Extend-nya pakai Pivot, bukan Model biasa

class OvertimeEmployee extends Pivot
{
    protected $table = 'overtime_employee';
    protected $guarded = ['id'];

    // Relasi ke Overtime
    public function overtime()
    {
        return $this->belongsTo(Overtime::class);
    }

    // Relasi ke Employee
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }
}
