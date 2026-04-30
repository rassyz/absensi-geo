<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Employee extends Model
{
    protected $fillable = [
        'user_id',
        'department_id',
        'full_name',
        'employee_number',
        'position',
        'phone',
        'address',
    ];

    // Relasi One-to-One dengan User
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Relasi Many-to-One dengan Department
    public function department()
    {
        return $this->belongsTo(Department::class);
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }

    public function leaves()
    {
        return $this->hasMany(Leave::class);
    }

    public function evaluations()
    {
        return $this->hasMany(EmployeeEvaluation::class);
    }

    // Relasi Many-to-Many ke Jadwal Lembur
    public function overtimes()
    {
        return $this->belongsToMany(Overtime::class, 'overtime_employees')
                    ->withPivot([
                        'id', 'status', 'check_in', 'check_in_latitude', 'check_in_longitude',
                        'check_out', 'check_out_latitude', 'check_out_longitude'
                    ])
                    ->withTimestamps();
    }

    public function overtimeEmployees()
    {
        return $this->hasMany(OvertimeEmployee::class);
    }
}
