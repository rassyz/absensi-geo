<?php

namespace App\Filament\Admin\Resources\Overtimes\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class OvertimesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('admin.name')
                    ->label('Admin')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('title')
                    ->label('Judul')
                    ->searchable(),
                TextColumn::make('date')
                    ->label('Tanggal')
                    ->date()
                    ->sortable(),
                TextColumn::make('planned_start_time')
                    ->label('Waktu Mulai')
                    ->time()
                    ->sortable(),
                TextColumn::make('planned_end_time')
                    ->label('Waktu Selesai')
                    ->time()
                    ->sortable(),
                TextColumn::make('employees_count')
                    ->label('Jumlah Peserta')
                    ->counts('employees')
                    ->badge(),
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
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
