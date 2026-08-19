<?php

namespace App\Filament\Admin\Resources\WorkAssignments\Pages;

use App\Filament\Admin\Resources\WorkAssignments\WorkAssignmentResource;
use Filament\Resources\Pages\CreateRecord;

class CreateWorkAssignment extends CreateRecord
{
    protected static string $resource =
    WorkAssignmentResource::class;
}
