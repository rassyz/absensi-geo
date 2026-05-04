<?php

namespace App\Filament\Admin\Resources\Overtimes;

use App\Filament\Admin\Resources\Overtimes\Pages\CreateOvertime;
use App\Filament\Admin\Resources\Overtimes\Pages\EditOvertime;
use App\Filament\Admin\Resources\Overtimes\Pages\ListOvertimes;
use App\Filament\Admin\Resources\Overtimes\Schemas\OvertimeForm;
use App\Filament\Admin\Resources\Overtimes\Tables\OvertimesTable;
use App\Models\Overtime;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class OvertimeResource extends Resource
{
    protected static ?string $model = Overtime::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCalendar;

    protected static ?string $recordTitleAttribute = 'Overtime';

    protected static string|\UnitEnum|null $navigationGroup = 'HR Management';

    public static function form(Schema $schema): Schema
    {
        return OvertimeForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return OvertimesTable::configure($table);
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
            'index' => ListOvertimes::route('/'),
            'create' => CreateOvertime::route('/create'),
            'edit' => EditOvertime::route('/{record}/edit'),
        ];
    }
}
