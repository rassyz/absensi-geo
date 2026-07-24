<?php

namespace App\Filament\Admin\Resources\Leaves\Pages;

use App\Filament\Admin\Resources\Leaves\LeaveResource;
use App\Filament\Admin\Resources\Leaves\Widgets\LeaveStatusChart;
use Filament\Actions\CreateAction;
use Filament\Pages\Concerns\ExposesTableToWidgets;
use Filament\Resources\Pages\ListRecords;

class ListLeaves extends ListRecords
{
    use ExposesTableToWidgets;

    protected static string $resource = LeaveResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label('Tambah Data Cuti'),
        ];
    }

    protected function getHeaderWidgets(): array
    {
        return [
            LeaveStatusChart::class,
        ];
    }

    public function getHeaderWidgetsColumns(): int | array
    {
        return 1;
    }
}
