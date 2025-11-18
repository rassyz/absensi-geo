<?php

namespace App\Filament\Admin\Resources\Attendances\Schemas;

use Dom\Text;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\DateTimePicker;
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
                    ->label('Zona Absensi')
                    ->relationship('attendanceZone', 'name')
                    ->required(),
                DateTimePicker::make('check_in')
                    ->label('Check-In')
                    ->required()
                    ->seconds(false),
                DateTimePicker::make('check_out')
                    ->label('Check-Out')
                    ->nullable()
                    ->seconds(false),
                Select::make('status')
                    ->label('Status')
                    ->options([
                        'hadir' => 'Hadir',
                        'sakit' => 'Sakit',
                        'cuti' => 'Cuti',
                    ])
                    ->required(),
            ]);
    }
}
