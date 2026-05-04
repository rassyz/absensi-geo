<?php

namespace App\Filament\Admin\Resources\OvertimeEmployees\Pages;

use App\Filament\Admin\Resources\OvertimeEmployees\OvertimeEmployeeResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditOvertimeEmployee extends EditRecord
{
    protected static string $resource = OvertimeEmployeeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
