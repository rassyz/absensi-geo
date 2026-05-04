<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Employee;

class EmployeeAttendancePolicy
{
    public function viewMemberAttendances(User $user, Employee $employeeToView)
    {
        $authUserEmployee = $user->employee;

        // 1. Pastikan user memiliki profil karyawan
        if (!$authUserEmployee) {
            return false;
        }

        // 2. Karyawan selalu bisa melihat datanya sendiri
        if ($authUserEmployee->id == $employeeToView->id) { // Ubah jadi ==
            return true;
        }

        // 3. Logika RBAC yang lebih fleksibel
        // Gunakan strtolower() agar 'Head' dan 'head' dianggap sama
        $position = strtolower(trim($authUserEmployee->position));

        if ($position === 'head' &&
            $authUserEmployee->department_id == $employeeToView->department_id) {
            return true;
        }

        return false;
    }
}
