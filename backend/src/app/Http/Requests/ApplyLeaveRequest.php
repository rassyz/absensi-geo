<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class ApplyLeaveRequest extends FormRequest
{
    /**
     * Menentukan apakah pengguna diizinkan membuat permintaan ini.
     */
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->employee !== null;
    }

    /**
     * Aturan validasi untuk pengajuan cuti.
     *
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'leave_type_id' => ['required', 'exists:leave_types,id'],
            'start_date'    => ['required', 'date'],
            'end_date'      => ['required', 'date', 'after_or_equal:start_date'],
            'apply_days'    => ['required', 'integer', 'min:1'],
            'reason'        => ['required', 'string'],
            'attachment'    => ['nullable', 'file', 'mimes:jpeg,png,jpg,pdf', 'max:10240'],
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
                'message' => 'Unauthorized or employee record not found',
            ], 401)
        );
    }
}

