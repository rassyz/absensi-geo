<?php

namespace App\Filament\Admin\Resources\EmployeeEvaluations\Pages;

use App\Filament\Admin\Resources\EmployeeEvaluations\EmployeeEvaluationResource;
use Filament\Resources\Pages\CreateRecord;

class CreateEmployeeEvaluation extends CreateRecord
{
    protected static string $resource = EmployeeEvaluationResource::class;
}
