<?php

namespace App\Filament\Admin\Resources\Leaves;

use App\Filament\Admin\Resources\Leaves\Pages\CreateLeave;
use App\Filament\Admin\Resources\Leaves\Pages\EditLeave;
use App\Filament\Admin\Resources\Leaves\Pages\ListLeaves;
use App\Filament\Admin\Resources\Leaves\Schemas\LeaveForm;
use App\Filament\Admin\Resources\Leaves\Tables\LeavesTable;
use App\Filament\Resources\LeaveResource\Widgets\LeaveStatusChart;
use App\Models\Leave;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class LeaveResource extends Resource
{
    protected static ?string $model = Leave::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCalendar;

    protected static ?string $recordTitleAttribute = 'Leave';

    protected static string|\UnitEnum|null $navigationGroup = 'HR Management';

    public static function form(Schema $schema): Schema
    {
        return LeaveForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return LeavesTable::configure($table);
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
            'index' => ListLeaves::route('/'),
            'create' => CreateLeave::route('/create'),
            'edit' => EditLeave::route('/{record}/edit'),
        ];
    }

    public static function getWidgets(): array
    {
        return [
            LeaveStatusChart::class,
        ];
    }
}
