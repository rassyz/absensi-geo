<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceTokenController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => [
                'required',
                'string',
                'max:1024',
            ],
            'platform' => [
                'nullable',
                'string',
                'max:30',
            ],
            'device_name' => [
                'nullable',
                'string',
                'max:255',
            ],
        ]);

        $deviceToken = DeviceToken::updateOrCreate(
            [
                'token' => $validated['token'],
            ],
            [
                'user_id' => $request->user()->id,
                'platform' =>
                $validated['platform'] ?? null,
                'device_name' =>
                $validated['device_name'] ?? null,
            ]
        );

        return response()->json([
            'success' => true,
            'message' =>
            'Token notifikasi berhasil disimpan.',
            'data' => $deviceToken,
        ]);
    }

    public function destroy(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token' => [
                'required',
                'string',
                'max:1024',
            ],
        ]);

        DeviceToken::query()
            ->where('user_id', $request->user()->id)
            ->where('token', $validated['token'])
            ->delete();

        return response()->json([
            'success' => true,
            'message' =>
            'Token notifikasi berhasil dihapus.',
        ]);
    }
}
