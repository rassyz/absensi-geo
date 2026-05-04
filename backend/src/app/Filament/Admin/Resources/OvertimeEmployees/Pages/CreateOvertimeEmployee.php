<?php

namespace App\Filament\Admin\Resources\OvertimeEmployees\Pages;

use App\Filament\Admin\Resources\OvertimeEmployees\OvertimeEmployeeResource;
use Filament\Resources\Pages\CreateRecord;

class CreateOvertimeEmployee extends CreateRecord
{
    protected static string $resource = OvertimeEmployeeResource::class;
}
