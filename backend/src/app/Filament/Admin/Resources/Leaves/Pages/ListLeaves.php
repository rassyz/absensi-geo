<?php

namespace App\Filament\Admin\Resources\Leaves\Pages;

use App\Filament\Admin\Resources\Leaves\LeaveResource;
use App\Filament\Resources\LeaveResource\Widgets\LeaveStatusChart;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListLeaves extends ListRecords
{
    protected static string $resource = LeaveResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }

    protected function getHeaderWidgets(): array
    {
        return [
            LeaveStatusChart::class,
        ];
    }
}
