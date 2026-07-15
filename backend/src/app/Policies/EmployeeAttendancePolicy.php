<?php

namespace App\Policies;

use App\Models\Employee;
use App\Models\User;

class EmployeeAttendancePolicy
{
    public function viewMemberAttendances(
        User $user,
        Employee $employeeToView
    ): bool {
        $authUserEmployee = $user->employee;

        if (!$authUserEmployee) {
            return false;
        }

        // Karyawan dapat melihat presensinya sendiri.
        if ($authUserEmployee->id === $employeeToView->id) {
            return true;
        }

        $authPosition = strtolower(
            trim((string) $authUserEmployee->position)
        );

        $targetPosition = strtolower(
            trim((string) $employeeToView->position)
        );

        // Manager dapat melihat presensi seluruh karyawan.
        if ($authPosition === 'manager') {
            return true;
        }

        // Head tidak boleh melihat presensi Manager,
        // meskipun berada pada departemen yang sama.
        if (
            $authPosition === 'head' &&
            $targetPosition === 'manager'
        ) {
            return false;
        }

        // Head hanya dapat melihat anggota departemennya.
        if (
            $authPosition === 'head' &&
            $authUserEmployee->department_id ===
            $employeeToView->department_id
        ) {
            return true;
        }

        return false;
    }
}
