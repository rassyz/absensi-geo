<?php

namespace App\Filament\Admin\Resources\OvertimeEmployees\Tables;

use Carbon\Carbon;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
// use Filament\Actions\EditAction;
// use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class OvertimeEmployeesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('employee.full_name')
                    ->label('Nama Karyawan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('overtime.title')
                    ->label('Judul Lembur')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('overtime.date')
                    ->label('Tanggal Lembur')
                    // ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->locale('id')->isoFormat('LL') : null)
                    ->date()
                    ->sortable(),
                TextColumn::make('overtime.planned_start_time')
                    ->label('Waktu Mulai')
                    ->time()
                    ->sortable(),
                TextColumn::make('overtime.planned_end_time')
                    ->label('Waktu Selesai')
                    ->time()
                    ->sortable(),
                TextColumn::make('check_in')
                    ->label('Masuk Lembur')
                    ->time()
                    ->sortable(),
                TextColumn::make('check_out')
                    ->label('Keluar Lembur')
                    ->time()
                    ->sortable(),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->recordActions([
                // EditAction::make(),
                // ViewAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
