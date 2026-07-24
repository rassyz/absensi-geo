<?php

namespace App\Filament\Admin\Resources\Departments\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class DepartmentForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label('Nama Departemen')
                    ->required(),
                Select::make('attendanceZones')
                    ->options(\App\Models\AttendanceZone::pluck('name', 'id'))
                    ->label('Zona Presensi')
                    ->multiple()
                    ->relationship('attendanceZones', 'name')
                    ->preload()
                    ->placeholder('Pilih Zona Presensi')
                    ->required(),
            ]);
    }
}
