<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\Request;

class EmployeeController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
    }

    public function getTeamMembers(Request $request)
    {
        // Ambil profil karyawan dari user yang sedang login
        $userEmployee = $request->user()->employee;

        if (!$userEmployee) {
            return response()->json(['message' => 'Profil karyawan tidak ditemukan.'], 404);
        }

        // Ambil semua karyawan di departemen yang sama
        $members = Employee::where('department_id', $userEmployee->department_id)
            ->where('id', '!=', $userEmployee->id) // Opsional: kecualikan dirinya sendiri dari daftar
            ->select('id', 'full_name', 'position', 'phone') // Ambil kolom yang perlu saja
            ->get();

        return response()->json([
            'success' => true,
            'data' => $members
        ]);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
