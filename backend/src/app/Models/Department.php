<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Department extends Model
{
    protected $fillable = ['name'];

    // Relasi One-to-Many dengan User
    public function employees()
    {
        return $this->hasMany(Employee::class);
    }

    // Relasi Many-to-Many dengan AttendanceZone
    public function attendanceZones()
    {
        return $this->belongsToMany(AttendanceZone::class, 'department_attendance_zone');
    }
}
