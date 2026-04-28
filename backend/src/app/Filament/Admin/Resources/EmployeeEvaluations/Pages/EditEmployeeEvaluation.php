<?php

namespace App\Filament\Admin\Resources\EmployeeEvaluations\Pages;

use App\Filament\Admin\Resources\EmployeeEvaluations\EmployeeEvaluationResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditEmployeeEvaluation extends EditRecord
{
    protected static string $resource = EmployeeEvaluationResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
