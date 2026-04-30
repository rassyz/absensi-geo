<?php

namespace App\Filament\Admin\Resources\Overtimes\Pages;

use App\Filament\Admin\Resources\Overtimes\OvertimeResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditOvertime extends EditRecord
{
    protected static string $resource = OvertimeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
