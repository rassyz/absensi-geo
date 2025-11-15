<?php

namespace App\Filament\Admin\Resources\Employees\Schemas;

use Dom\Text;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class EmployeeForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->label('User')
                    ->relationship('user', 'email')
                    ->unique()
                    ->searchable()
                    ->required(),
                Select::make('department_id')
                    ->label('Departemen')
                    ->relationship('department', 'name')
                    ->searchable()
                    ->required(),
                TextInput::make('full_name')
                    ->label('Nama Lengkap')
                    ->required(),
                TextInput::make('employee_number')
                    ->label('Nomor Karyawan')
                    ->required(),
                TextInput::make('position')
                    ->label('Jabatan')
                    ->required(),
                TextInput::make('phone')
                    ->label('Telepon')
                    ->required(),
                TextInput::make('address')
                    ->label('Alamat')
                    ->required(),
            ]);
    }
}
