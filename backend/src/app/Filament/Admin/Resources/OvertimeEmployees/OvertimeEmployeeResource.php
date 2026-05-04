<?php

namespace App\Filament\Admin\Resources\OvertimeEmployees;

use App\Filament\Admin\Resources\OvertimeEmployees\Pages\CreateOvertimeEmployee;
use App\Filament\Admin\Resources\OvertimeEmployees\Pages\EditOvertimeEmployee;
use App\Filament\Admin\Resources\OvertimeEmployees\Pages\ListOvertimeEmployees;
use App\Filament\Admin\Resources\OvertimeEmployees\Schemas\OvertimeEmployeeForm;
use App\Filament\Admin\Resources\OvertimeEmployees\Tables\OvertimeEmployeesTable;
use App\Filament\Resources\OvertimeEmployeeResource\Widgets\TopOvertimeEmployeesChart;
use App\Models\OvertimeEmployee;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class OvertimeEmployeeResource extends Resource
{
    protected static ?string $model = OvertimeEmployee::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedArrowLeftStartOnRectangle;

    protected static ?string $recordTitleAttribute = 'OvertimeEmployee';

    protected static string|\UnitEnum|null $navigationGroup = 'HR Management';

    public static function form(Schema $schema): Schema
    {
        return OvertimeEmployeeForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return OvertimeEmployeesTable::configure($table);
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
            'index' => ListOvertimeEmployees::route('/'),
            'create' => CreateOvertimeEmployee::route('/create'),
            'edit' => EditOvertimeEmployee::route('/{record}/edit'),
        ];
    }

    public static function getWidgets(): array
    {
        return [
            TopOvertimeEmployeesChart::class,
        ];
    }
}
