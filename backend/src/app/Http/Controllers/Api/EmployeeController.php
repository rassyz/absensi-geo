<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\Request;

class EmployeeController extends Controller
{
    public function getTeamMembers(Request $request)
    {
        $userEmployee = $request->user()->employee;

        if (!$userEmployee) {
            return response()->json([
                'message' => 'Profil karyawan tidak ditemukan.',
            ], 404);
        }

        $isManager = strtolower(
            trim((string) $userEmployee->position)
        ) === 'manager';

        $query = Employee::query()
            ->with([
                'department:id,name',
            ])
            ->where('id', '!=', $userEmployee->id);

        // Selain Manager tetap dibatasi berdasarkan departemen.
        if (!$isManager) {
            $query->where(
                'department_id',
                $userEmployee->department_id
            );
        }

        $members = $query
            ->select([
                'id',
                'full_name',
                'position',
                'phone',
                'department_id',
            ])
            ->orderBy('full_name')
            ->get()
            ->map(function ($employee) {
                return [
                    'id' => $employee->id,
                    'full_name' => $employee->full_name,
                    'phone' => $employee->phone,
                    'position' => $employee->position,
                    'department_id' => $employee->department_id,

                    'department' => $employee->department
                        ? [
                            'id' => $employee->department->id,
                            'name' => $employee->department->name,
                        ]
                        : null,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $members,
        ]);
    }
}
