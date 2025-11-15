<?php

namespace App\Filament\Admin\Resources\AttendanceZones\Pages;

use App\Filament\Admin\Resources\AttendanceZones\AttendanceZoneResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditAttendanceZone extends EditRecord
{
    protected static string $resource = AttendanceZoneResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
