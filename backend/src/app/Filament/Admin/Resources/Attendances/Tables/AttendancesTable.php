<?php

namespace App\Filament\Admin\Resources\Attendances\Tables;

use Dom\Text;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Illuminate\Database\Eloquent\Builder;
use Filament\Tables\Filters\Filter;
use Filament\Forms\Components\DatePicker;


class AttendancesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('employee.full_name')
                    ->label('Nama Karyawan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('attendanceZone.name')
                    ->label('Zona Absensi')
                    ->sortable(),
                TextColumn::make('check_in')
                    ->label('Check-In')
                    ->dateTime('d M Y - H:i')
                    ->timezone('Asia/Jakarta')
                    ->sortable(),
                TextColumn::make('check_out')
                    ->label('Check-Out')
                    ->dateTime('d M Y - H:i')
                    ->timezone('Asia/Jakarta')
                    ->sortable(),
                TextColumn::make('status')
                    ->label('Status')
                    ->sortable(),
                TextColumn::make('created_at')
                    ->label('Created At')
                    ->dateTime('d M Y - H:i')
                    ->timezone('Asia/Jakarta')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('updated_at')
                    ->label('Updated At')
                    ->dateTime('d M Y - H:i')
                    ->timezone('Asia/Jakarta')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                Filter::make('date')
                    ->label('Filter by Date')
                    ->form([
                        DatePicker::make('selected_date')
                            ->label('Pilih Tanggal')
                            ->required(),
                    ])
                    ->query(function (Builder $query, array $data) {
                        if (!empty($data['selected_date'])) {
                            $query->whereDate('check_in', $data['selected_date'])
                                ->orWhereDate('check_out', $data['selected_date']);
                        }
                    }),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
                ViewAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
