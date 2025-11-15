<?php

namespace App\Filament\Admin\Resources\AttendanceZones\Schemas;

use Filament\Schemas\Schema;
use App\Forms\Components\LeafletDrawField;
use Filament\Forms\Components\TextInput;

class AttendanceZoneForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label('Nama Zona Absensi')
                    ->required()
                    ->columnSpanFull(),

                LeafletDrawField::make('area')
                    ->label('Area Zona Absensi')
                    ->required()
                    ->columnSpanFull(),
            ]);
    }
}
