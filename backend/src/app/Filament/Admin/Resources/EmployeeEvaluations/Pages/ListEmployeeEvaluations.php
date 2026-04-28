<?php

namespace App\Filament\Admin\Resources\EmployeeEvaluations\Pages;

use App\Filament\Admin\Resources\EmployeeEvaluations\EmployeeEvaluationResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListEmployeeEvaluations extends ListRecords
{
    protected static string $resource = EmployeeEvaluationResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
