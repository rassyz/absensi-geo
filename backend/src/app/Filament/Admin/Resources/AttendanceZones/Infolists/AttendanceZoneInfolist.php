<?php

namespace App\Filament\Admin\Resources\AttendanceZones\Infolists;

use Filament\Schemas\Schema;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Infolists\Components\ViewEntry;

class AttendanceZoneInfolist
{
    public static function configure(Schema $infolist): Schema
    {
        return $infolist
            ->schema([
                Section::make('Informasi Zona')
                    ->schema([
                        TextEntry::make('name')
                            ->label('Nama Zona'),

                        // 👇 Entry kustom untuk menampilkan peta
                        ViewEntry::make('area')
                            ->label('Visualisasi Geofencing (Toleransi 10m)')
                            ->view('filament.pages.attendance-zone-map-view')
                            ->columnSpanFull(),
                    ])
                    ->columnSpanFull(),
            ])
            ->columns(1);
    }
}
