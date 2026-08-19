<?php

namespace App\Filament\Admin\Resources\WorkAssignments;

use App\Filament\Admin\Resources\WorkAssignments\Pages\CreateWorkAssignment;
use App\Filament\Admin\Resources\WorkAssignments\Pages\EditWorkAssignment;
use App\Filament\Admin\Resources\WorkAssignments\Pages\ListWorkAssignments;
use App\Filament\Admin\Resources\WorkAssignments\Schemas\WorkAssignmentForm;
use App\Filament\Admin\Resources\WorkAssignments\Tables\WorkAssignmentsTable;
use App\Models\WorkAssignment;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class WorkAssignmentResource extends Resource
{
    protected static ?string $model = WorkAssignment::class;

    protected static string|BackedEnum|null $navigationIcon =
    Heroicon::OutlinedDocumentText;

    protected static string|\UnitEnum|null $navigationGroup =
    'Attendance Management';

    // protected static ?string $navigationLabel =
    // 'Surat Tugas Luar';

    // protected static ?string $modelLabel =
    // 'Surat Tugas';

    // protected static ?string $pluralModelLabel =
    // 'Surat Tugas Luar';

    protected static ?string $recordTitleAttribute =
    'assignment_number';

    public static function form(Schema $schema): Schema
    {
        return WorkAssignmentForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return WorkAssignmentsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListWorkAssignments::route('/'),
            'create' => CreateWorkAssignment::route('/create'),
            'edit' => EditWorkAssignment::route('/{record}/edit'),
        ];
    }
}
