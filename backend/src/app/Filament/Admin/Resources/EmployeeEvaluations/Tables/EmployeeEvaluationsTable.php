<?php

namespace App\Filament\Admin\Resources\EmployeeEvaluations\Tables;

use App\Services\EmployeeEvaluationService;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\Select;
use Filament\Tables\Columns\BadgeColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class EmployeeEvaluationsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('final_score', 'desc') // 🔥 ranking otomatis
            ->columns([
                TextColumn::make('employee.full_name')
                    ->label('Nama Karyawan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('period')
                    ->label('Periode'),
                TextColumn::make('attendance_percentage')
                    ->label('Kehadiran')
                    ->suffix('%')
                    ->sortable(),
                TextColumn::make('total_attendance')
                    ->label('Jumlah Hadir'),
                TextColumn::make('late_count')
                    ->label('Telat'),
                TextColumn::make('absent_count')
                    ->label('Alpha'),
                TextColumn::make('final_score')
                    ->label('Skor')
                    ->sortable()
                    ->weight('bold'),
                BadgeColumn::make('status')
                    ->colors([
                        'success' => 'sangat disiplin',
                        'warning' => 'cukup',
                        'danger' => 'pembinaan',
                    ]),
            ])
            ->filters([
                SelectFilter::make('month')
                    ->options([
                        1 => 'Januari',
                        2 => 'Februari',
                        3 => 'Maret',
                        4 => 'April',
                        5 => 'Mei',
                        6 => 'Juni',
                        7 => 'Juli',
                        8 => 'Agustus',
                        9 => 'September',
                        10 => 'Oktober',
                        11 => 'November',
                        12 => 'Desember',
                    ]),
                SelectFilter::make('year')
                    ->options([
                        2025 => '2025',
                        2026 => '2026',
                    ]),

            ])
            ->recordActions([
                ViewAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ])
            ->headerActions([
                Action::make('generate')
                    ->label('Generate Evaluasi')
                    ->form([
                        Select::make('month')
                            ->options([
                                1 => 'Januari',
                                2 => 'Februari',
                                3 => 'Maret',
                                4 => 'April',
                                5 => 'Mei',
                                6 => 'Juni',
                                7 => 'Juli',
                                8 => 'Agustus',
                                9 => 'September',
                                10 => 'Oktober',
                                11 => 'November',
                                12 => 'Desember',
                            ])
                            ->required(),
                        Select::make('year')
                            ->options([
                                2025 => 2025,
                                2026 => 2026,
                            ])
                            ->required(),
                    ])
                    ->action(function (array $data) {

                        app(EmployeeEvaluationService::class)
                            ->generate($data['month'], $data['year']);
                    })
                    ->successNotificationTitle('Evaluasi berhasil dibuat!'),
            ]);
    }
}
