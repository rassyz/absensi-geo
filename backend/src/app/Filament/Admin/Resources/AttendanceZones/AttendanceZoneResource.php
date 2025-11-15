<?php

namespace App\Filament\Admin\Resources\AttendanceZones;

use App\Filament\Admin\Resources\AttendanceZones\Pages\CreateAttendanceZone;
use App\Filament\Admin\Resources\AttendanceZones\Pages\EditAttendanceZone;
use App\Filament\Admin\Resources\AttendanceZones\Pages\ListAttendanceZones;
use App\Filament\Admin\Resources\AttendanceZones\Schemas\AttendanceZoneForm;
use App\Filament\Admin\Resources\AttendanceZones\Tables\AttendanceZonesTable;
use App\Models\AttendanceZone;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class AttendanceZoneResource extends Resource
{
    protected static ?string $model = AttendanceZone::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedMapPin;

    protected static ?string $recordTitleAttribute = 'AttendanceZone';

    protected static string|\UnitEnum|null $navigationGroup = 'Attendance Management';

    public static function form(Schema $schema): Schema
    {
        return AttendanceZoneForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return AttendanceZonesTable::configure($table);
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
            'index' => ListAttendanceZones::route('/'),
            'create' => CreateAttendanceZone::route('/create'),
            'edit' => EditAttendanceZone::route('/{record}/edit'),
        ];
    }


}
