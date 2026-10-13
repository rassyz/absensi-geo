<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class AttendanceCheckRequest extends FormRequest
{
    /**
     * Tentukan apakah pengguna memiliki otorisasi untuk melakukan request ini.
     */
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->employee !== null;
    }

    /**
     * Aturan validasi untuk check-in dan check-out presensi.
     *
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'latitude'  => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'photo'     => ['required', 'image', 'mimes:jpeg,png,jpg', 'max:2048'],
        ];
    }

    /**
     * Tangani kegagalan validasi sesuai format respons API mobile absensi.
     */
    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(
            response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422)
        );
    }

    /**
     * Tangani kegagalan otorisasi jika profil karyawan tidak ditemukan.
     */
    protected function failedAuthorization(): void
    {
        throw new HttpResponseException(
            response()->json([
                'success' => false,
                'message' => 'Profil karyawan tidak ditemukan.',
            ], 404)
        );
    }
}

