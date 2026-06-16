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
        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name' => $validatedData['name'],
            'email' => $validatedData['email'],
            'password' => Hash::make($validatedData['password']),
        ]);

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

        $user = User::with('employee.department')->where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Email atau Password salah',
            ], 401);
        }

        // buat token API
        $token = $user->createToken('login-token')->plainTextToken;

        $userData = $user->toArray();
        $mobileBaseUrl = config('app.url');
        $userData['avatar_url'] = $user->avatar_url
            ? $mobileBaseUrl . '/storage/' . $user->avatar_url
            : null;

        return response()->json([
            'message' => 'Login Berhasil',
            'token' => $token,
            'user' => $userData,
        ]);
    }

    public function me(Request $request)
    {
        $user = $request->user()->load('employee.department');

        $userData = $user->toArray();

        $mobileBaseUrl = config('app.url');

        $userData['avatar_url'] = $user->avatar_url
            ? $mobileBaseUrl . '/storage/' . $user->avatar_url
            : null;

        return response()->json([
            'message' => 'User profile berhasil diambil',
            'user' => $userData,
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
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout Berhasil',
        ]);
    }
}
