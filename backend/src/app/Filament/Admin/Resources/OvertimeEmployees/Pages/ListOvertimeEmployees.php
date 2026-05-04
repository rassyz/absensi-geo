<?php

namespace App\Filament\Admin\Resources\OvertimeEmployees\Pages;

use App\Filament\Admin\Resources\OvertimeEmployees\OvertimeEmployeeResource;
use App\Filament\Resources\OvertimeEmployeeResource\Widgets\TopOvertimeEmployeesChart;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListOvertimeEmployees extends ListRecords
{
    protected static string $resource = OvertimeEmployeeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }

    protected function getHeaderWidgets(): array
    {
        return [
            TopOvertimeEmployeesChart::class,
        ];
    }
}
