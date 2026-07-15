<?php

namespace App\Filament\Admin\Resources\Attendances\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Schemas\Schema;

class AttendanceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('employee_id')
                    ->label('Nama Karyawan')
                    ->relationship('employee', 'full_name')
                    ->searchable()
                    ->required(),
                Select::make('attendance_zone_id')
                    ->label('Zona Presensi')
                    ->relationship('attendanceZone', 'name')
                    ->required(),
                DatePicker::make('date')
                    ->label('Tanggal')
                    ->required()
                    ->default(now()),
                DateTimePicker::make('check_in')
                    ->label('Check-In')
                    ->nullable()
                    ->seconds(false),
                DateTimePicker::make('check_out')
                    ->label('Check-Out')
                    ->nullable()
                    ->seconds(false),
                Select::make('source')
                    ->label('Sumber Presensi')
                    ->options([
                        'Mobile' => 'Mobile',
                        'Web Admin' => 'Web Admin',
                        'System' => 'System',
                    ])
                    ->required(),
                Select::make('status')
                    ->label('Status')
                    ->options([
                        'Hadir' => 'Hadir',
                        'Sakit' => 'Sakit',
                        'Cuti' => 'Cuti',
                        'Alpha' => 'Alpha',
                        'Telat' => 'Telat',
                        'Pulang Cepat' => 'Pulang Cepat',
                        'Libur Nasional' => 'Libur Nasional',
                    ])
                    ->required(),
                Select::make('leave_id')
                    ->label('Jenis Cuti')
                    ->relationship('leave', 'leave_type_id')
                    ->preload()
                    ->nullable(),
                FileUpload::make('check_in_photo_path')
                    ->label('Foto Check-In')
                    ->image() // Menandakan ini file gambar agar muncul preview
                    ->disk('public') // Wajib: sesuaikan dengan disk di controller
                    ->directory('attendances') // Arahkan ke folder attendances
                    ->openable(), // Agar foto bisa diklik dan terbuka di tab baru
                // ->disabled(), // Beri disabled() agar Admin tidak bisa mengubah foto absen secara manual (opsional, tapi disarankan untuk integritas data)
                FileUpload::make('check_out_photo_path')
                    ->label('Foto Check-Out')
                    ->image()
                    ->disk('public')
                    ->directory('attendances')
                    ->openable(),
                // ->disabled(),
            ]);
    }
}
