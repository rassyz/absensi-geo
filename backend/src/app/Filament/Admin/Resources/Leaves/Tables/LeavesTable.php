<?php

namespace App\Filament\Admin\Resources\Leaves\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class LeavesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('employee.full_name')
                    ->label('Nama Karyawan')
                    ->sortable()
                    ->searchable(),

                TextColumn::make('leaveType.name')
                    ->label('Jenis Cuti')
                    ->sortable()
                    ->searchable(),
                TextColumn::make('start_date')
                    ->label('Tanggal Mulai')
                    ->date('d F Y')->sortable(),
                TextColumn::make('end_date')
                    ->label('Tanggal Selesai')
                    ->date('d F Y')->sortable(),
                TextColumn::make('apply_days')
                    ->label('Jumlah Hari')
                    ->numeric()->sortable(),

                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'Pending' => 'warning',
                        'Approved' => 'success',
                        'Rejected' => 'danger',
                        'Cancelled' => 'gray',
                        default => 'primary',
                    })
                    ->searchable(),

                TextColumn::make('approver.name')
                    ->label('Approved By')
                    ->sortable(),

                TextColumn::make('approved_at')
                    ->label('Approved At')
                    ->date('d F Y')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime('d F Y - H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('updated_at')
                    ->label('Diperbarui')
                    ->dateTime('d F Y - H:i')
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
