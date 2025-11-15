<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        // validasi input
        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        // buat user baru
        $user = User::create([
            'name' => $validatedData['name'],
            'email' => $validatedData['email'],
            'password' => Hash::make($validatedData['password']),
        ]);

        // respons
        return response()->json([
            'message' => 'Registrasi Berhasil',
            'user' => $user,
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        // cari user berdasarkan email
        $user = User::where('email', $request->email)->first();

        // periksa password
        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Email atau Password salah',
            ], 401);
        }

        // buat token API
        $token = $user->createToken('login-token')->plainTextToken;

        return response()->json([
            'message' => 'Login Berhasil',
            'token' => $token,
            'user' => $user,
        ]);
    }

    // logout paksa
    // public function logout($userId)
    // {
    //     // cari user berdasarkan id token
    //     $user = User::find($userId);

    //     // jika user tidak ditemukan
    //     if (!$user) {
    //         return response()->json([
    //             'message' => 'User dengan ID ' . $userId . ' tidak ditemukan.',
    //         ], 404);
    //     }

    //     // hapus semua token untuk user ini
    //     $user->tokens()->delete();

    //     return response()->json([
    //         'message' => 'Logout Berhasil, user: ' . $user->name,
    //     ]);
    // }

    public function logout(Request $request)
    {
        // hapus token yang digunakan untuk autentikasi saat ini
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout Berhasil',
        ]);
    }
}
