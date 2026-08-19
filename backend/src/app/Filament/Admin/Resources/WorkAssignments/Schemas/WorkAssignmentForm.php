<?php

namespace App\Filament\Admin\Resources\WorkAssignments\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Hidden;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\Auth;

class WorkAssignmentForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Hidden::make('created_by')
                    ->default(fn() => Auth::id()),

                Select::make('employees')
                    ->label('Karyawan')
                    ->relationship(
                        name: 'employees',
                        titleAttribute: 'full_name',
                    )
                    ->multiple()
                    ->searchable()
                    ->preload()
                    ->required(),

                TextInput::make('assignment_number')
                    ->label('Nomor Surat Tugas')
                    ->required()
                    ->maxLength(255)
                    ->unique(ignoreRecord: true),

                DatePicker::make('start_date')
                    ->label('Tanggal Mulai')
                    ->required(),

                DatePicker::make('end_date')
                    ->label('Tanggal Selesai')
                    ->required()
                    ->rules([
                        'after_or_equal:start_date',
                    ]),

                TextInput::make('destination')
                    ->label('Lokasi / Tujuan Tugas')
                    ->required()
                    ->maxLength(255)
                    ->columnSpanFull(),

                Textarea::make('purpose')
                    ->label('Keperluan / Uraian Tugas')
                    ->required()
                    ->rows(4)
                    ->columnSpanFull(),

                FileUpload::make('attachment')
                    ->label('Dokumen Surat Tugas')
                    ->disk('public')
                    ->directory('work-assignments')
                    ->acceptedFileTypes([
                        'application/pdf',
                        'image/jpeg',
                        'image/png',
                    ])
                    ->maxSize(5120)
                    ->downloadable()
                    ->openable()
                    ->required()
                    ->columnSpanFull(),

                Toggle::make('is_active')
                    ->label('Surat Tugas Aktif')
                    ->helperText(
                        'Surat tugas aktif memungkinkan karyawan melakukan presensi tugas luar selama tanggal surat masih berlaku.'
                    )
                    ->default(true)
                    ->required(),
            ]);
    }
}
