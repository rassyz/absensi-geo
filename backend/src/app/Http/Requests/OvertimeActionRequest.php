<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class OvertimeActionRequest extends FormRequest
{
    /**
     * Tentukan apakah pengguna diizinkan melakukan request ini.
     */
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->employee !== null;
    }

    /**
     * Aturan validasi untuk clock-in dan clock-out lembur.
     *
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'overtime_id' => ['required', 'exists:overtimes,id'],
            'latitude'    => ['required', 'numeric', 'between:-90,90'],
            'longitude'   => ['required', 'numeric', 'between:-180,180'],
        ];
    }

    /**
     * Tangani kegagalan validasi sesuai format respons API mobile.
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
                'message' => 'Data karyawan tidak ditemukan.',
            ], 404)
        );
    }
}

