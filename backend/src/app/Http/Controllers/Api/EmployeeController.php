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
            return response()->json(['message' => 'Profil karyawan tidak ditemukan.'], 404);
        }

        $members = Employee::where('department_id', $userEmployee->department_id)
            ->where('id', '!=', $userEmployee->id)
            ->select('id', 'full_name', 'position', 'phone')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $members
        ]);
    }
}
