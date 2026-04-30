<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Overtime extends Model
{
    use HasFactory;

    protected $guarded = ['id'];

    // Relasi ke pembuat jadwal (Admin)
    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    // Relasi Many-to-Many ke Employee beserta data ekstra di tabel pivot
    public function employees()
    {
        return $this->belongsToMany(Employee::class, 'overtime_employees')
                    ->withPivot([
                        'id', 'status', 'check_in', 'check_in_latitude', 'check_in_longitude',
                        'check_out', 'check_out_latitude', 'check_out_longitude'
                    ])
                    ->withTimestamps();
    }
}
