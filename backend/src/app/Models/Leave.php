<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Leave extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'employee_id',
        'leave_type',
        'start_date',
        'end_date',
        'apply_days',
        'reason',
        'attachment',
        'status',
        'approved_by',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    /**
     * Get the employee that owns the leave request.
     */
    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    /**
     * Get the user (Head/Manager) who approved or rejected the leave.
     */
    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}
