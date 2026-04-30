<?php

namespace App\Filament\Admin\Resources\Overtimes\Pages;

use App\Filament\Admin\Resources\Overtimes\OvertimeResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListOvertimes extends ListRecords
{
    protected static string $resource = OvertimeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
