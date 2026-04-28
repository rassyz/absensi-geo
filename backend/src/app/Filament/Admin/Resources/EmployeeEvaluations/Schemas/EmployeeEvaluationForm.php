<?php

namespace App\Filament\Admin\Resources\EmployeeEvaluations\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class EmployeeEvaluationForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('employee_id')
                    ->relationship('employee', 'full_name')
                    ->searchable()
                    ->required(),
                TextInput::make('month')
                    ->numeric()
                    ->minValue(1)
                    ->maxValue(12)
                    ->required(),
                TextInput::make('year')
                    ->numeric()
                    ->required(),
                TextInput::make('attendance_percentage')
                    ->numeric()
                    ->suffix('%')
                    ->disabled(), // ❗ hasil sistem
                TextInput::make('late_count')
                    ->numeric()
                    ->disabled(),
                TextInput::make('early_leave_count')
                    ->numeric()
                    ->disabled(),
                TextInput::make('absent_count')
                    ->numeric()
                    ->disabled(),
                TextInput::make('final_score')
                    ->numeric()
                    ->disabled(),
                Select::make('status')
                    ->options([
                        'sangat disiplin' => 'Sangat Disiplin',
                        'cukup' => 'Cukup',
                        'pembinaan' => 'Perlu Pembinaan',
                    ])
                    ->disabled(),
            ]);
    }
}
