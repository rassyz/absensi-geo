<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class ProcessLeaveRequest extends FormRequest
{
    /**
     * Menentukan apakah pengguna diizinkan membuat permintaan ini.
     */
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->employee !== null;
    }

    /**
     * Aturan validasi untuk pemrosesan cuti.
     *
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'status' => ['required', 'in:Approved,Rejected'],
        ];
    }

    /**
     * Tangani kegagalan otorisasi jika profil karyawan tidak ditemukan.
     */
    protected function failedAuthorization(): void
    {
        throw new HttpResponseException(
            response()->json([
                'success' => false,
                'message' => 'Unauthorized to process this leave',
            ], 403)
        );
    }
}

