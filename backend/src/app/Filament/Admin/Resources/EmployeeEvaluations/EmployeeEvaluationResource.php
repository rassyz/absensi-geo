<?php

namespace App\Filament\Admin\Resources\EmployeeEvaluations;

use App\Filament\Admin\Resources\EmployeeEvaluations\Pages\CreateEmployeeEvaluation;
use App\Filament\Admin\Resources\EmployeeEvaluations\Pages\EditEmployeeEvaluation;
use App\Filament\Admin\Resources\EmployeeEvaluations\Pages\ListEmployeeEvaluations;
use App\Filament\Admin\Resources\EmployeeEvaluations\Schemas\EmployeeEvaluationForm;
use App\Filament\Admin\Resources\EmployeeEvaluations\Tables\EmployeeEvaluationsTable;
use App\Models\EmployeeEvaluation;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class EmployeeEvaluationResource extends Resource
{
    protected static ?string $model = EmployeeEvaluation::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUsers;

    protected static ?string $recordTitleAttribute = 'EmployeeEvaluation';

    protected static string|\UnitEnum|null $navigationGroup = 'HR Management';

    public static function form(Schema $schema): Schema
    {
        return EmployeeEvaluationForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return EmployeeEvaluationsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListEmployeeEvaluations::route('/'),
            'create' => CreateEmployeeEvaluation::route('/create'),
            'edit' => EditEmployeeEvaluation::route('/{record}/edit'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }

}
