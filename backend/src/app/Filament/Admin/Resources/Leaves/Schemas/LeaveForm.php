<?php

namespace App\Filament\Admin\Resources\Leaves\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\FileUpload;
use Filament\Schemas\Schema;

class LeaveForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('employee_id')
                    ->relationship('employee', 'full_name')
                    ->searchable()
                    ->preload()
                    ->required(),

                Select::make('leave_type')
                    ->options([
                        'Cuti Tahunan' => 'Cuti Tahunan',
                        'Cuti Sakit' => 'Cuti Sakit',
                        'Cuti Melahirkan' => 'Cuti Melahirkan',
                        'Cuti Alasan Penting' => 'Cuti Alasan Penting',
                    ])
                    ->required(),

                DatePicker::make('start_date')->required(),
                DatePicker::make('end_date')->required(),

                TextInput::make('apply_days')
                    ->required()
                    ->numeric(),

                FileUpload::make('attachment')
                    ->directory('leave-attachments')
                    ->columnSpanFull(),

                Textarea::make('reason')
                    ->required()
                    ->columnSpanFull(),

                Select::make('status')
                    ->options([
                        'Pending' => 'Pending',
                        'Approved' => 'Approved',
                        'Rejected' => 'Rejected',
                        'Cancelled' => 'Cancelled',
                    ])
                    ->required()
                    ->default('Pending'),

                Select::make('approved_by')
                    ->relationship('approver', 'name')
                    ->searchable()
                    ->preload(),
            ]);
    }
}
