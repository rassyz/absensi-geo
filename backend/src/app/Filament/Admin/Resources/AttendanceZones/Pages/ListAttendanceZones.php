<?php

namespace App\Filament\Admin\Resources\AttendanceZones\Pages;

use App\Filament\Admin\Resources\AttendanceZones\AttendanceZoneResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListAttendanceZones extends ListRecords
{
    protected static string $resource = AttendanceZoneResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
