<?php

namespace App\Filament\Admin\Resources\WorkAssignments\Pages;

use App\Filament\Admin\Resources\WorkAssignments\WorkAssignmentResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListWorkAssignments extends ListRecords
{
    protected static string $resource =
    WorkAssignmentResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label('Tambah Surat Tugas'),
        ];
    }
}
