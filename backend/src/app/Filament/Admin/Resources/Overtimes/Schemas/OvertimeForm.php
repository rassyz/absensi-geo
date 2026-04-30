<?php

namespace App\Filament\Admin\Resources\Overtimes\Schemas;

use Filament\Forms\Components\Hidden;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\TimePicker;
use Filament\Forms\Components\Select;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\Auth;

class OvertimeForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Hidden::make('admin_id')
                    ->default(fn () => Auth::id()),

                TextInput::make('title')
                    ->label('Judul Lembur')
                    ->required(),

                DatePicker::make('date')
                    ->label('Tanggal Lembur')
                    ->required(),

                TimePicker::make('planned_start_time')
                    ->label('Waktu Mulai Direncanakan')
                    ->required(),

                TimePicker::make('planned_end_time')
                    ->label('Waktu Selesai Direncanakan')
                    ->required(),

                Textarea::make('notes')
                    ->label('Catatan')
                    ->columnSpanFull(),

                Select::make('employees')
                    ->label('Peserta Lembur (Pilih Karyawan)')
                    ->relationship('employees', 'full_name')
                    ->multiple()
                    ->preload()
                    ->searchable()
                    ->required()
                    ->columnSpanFull(),
            ]);
    }
}
