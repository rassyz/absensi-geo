<?php

namespace App\Filament\Admin\Resources\EmployeeEvaluations\Tables;

use App\Services\EmployeeEvaluationService;
use Carbon\Carbon;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\Select;
use Filament\Notifications\Notification;
use Filament\Support\Enums\FontWeight;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class EmployeeEvaluationsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('final_score', 'desc')

            ->columns([
                TextColumn::make('employee.full_name')
                    ->label('Nama Karyawan')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('month')
                    ->label('Periode')
                    ->formatStateUsing(
                        function ($state, $record): string {
                            return Carbon::create(
                                (int) $record->year,
                                (int) $record->month,
                                1
                            )
                                ->locale('id')
                                ->translatedFormat('F Y');
                        }
                    ),

                TextColumn::make('attendance_percentage')
                    ->label('Kehadiran')
                    ->formatStateUsing(
                        fn($state): string => number_format(
                            (float) $state,
                            2,
                            ',',
                            '.'
                        )
                    )
                    ->suffix('%')
                    ->sortable(),

                TextColumn::make('total_attendance')
                    ->label('Jumlah Hadir')
                    ->numeric()
                    ->sortable(),

                TextColumn::make('late_count')
                    ->label('Telat')
                    ->numeric()
                    ->sortable(),

                TextColumn::make('absent_count')
                    ->label('Alpa')
                    ->numeric()
                    ->sortable(),

                TextColumn::make('final_score')
                    ->label('Skor')
                    ->formatStateUsing(
                        fn($state): string => number_format(
                            (float) $state,
                            4,
                            ',',
                            '.'
                        )
                    )
                    ->sortable()
                    ->weight(FontWeight::Bold),

                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->formatStateUsing(
                        fn(?string $state): string => match ($state) {
                            'sangat disiplin' => 'Sangat Disiplin',
                            'cukup' => 'Cukup',
                            'pembinaan' => 'Pembinaan',
                            default => ucfirst((string) $state),
                        }
                    )
                    ->color(
                        fn(?string $state): string => match ($state) {
                            'sangat disiplin' => 'success',
                            'cukup' => 'warning',
                            'pembinaan' => 'danger',
                            default => 'gray',
                        }
                    )
                    ->sortable(),
            ])

            ->filters([
                SelectFilter::make('month')
                    ->label('Bulan')
                    ->options(self::monthOptions())
                    ->default((int) now()->month)
                    ->native(false),

                SelectFilter::make('year')
                    ->label('Tahun')
                    ->options(self::yearOptions())
                    ->default((int) now()->year)
                    ->native(false),

                SelectFilter::make('status')
                    ->label('Status Evaluasi')
                    ->options([
                        'sangat disiplin' => 'Sangat Disiplin',
                        'cukup' => 'Cukup',
                        'pembinaan' => 'Pembinaan',
                    ])
                    ->native(false),
            ])

            ->recordActions([
                ViewAction::make()
                    ->label('Lihat'),

                DeleteAction::make()
                    ->label('Hapus'),
            ])

            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make()
                        ->label('Hapus Terpilih'),
                ]),
            ])

            ->headerActions([
                Action::make('generate')
                    ->label('Generate Evaluasi')
                    ->icon('heroicon-o-calculator')
                    ->color('primary')

                    ->requiresConfirmation()
                    ->modalHeading('Generate Evaluasi Karyawan')
                    ->modalDescription(
                        'Data evaluasi pada periode yang dipilih akan dibuat ulang berdasarkan jumlah hadir, keterlambatan, dan alpa.'
                    )
                    ->modalSubmitActionLabel('Generate')

                    ->schema([
                        Select::make('month')
                            ->label('Bulan')
                            ->options(self::monthOptions())
                            ->default((int) now()->month)
                            ->required()
                            ->native(false),

                        Select::make('year')
                            ->label('Tahun')
                            ->options(self::yearOptions())
                            ->default((int) now()->year)
                            ->required()
                            ->native(false),
                    ])

                    ->action(function (array $data): void {
                        $month = (int) $data['month'];
                        $year = (int) $data['year'];

                        app(EmployeeEvaluationService::class)
                            ->generate($month, $year);

                        $period = Carbon::create(
                            $year,
                            $month,
                            1
                        )
                            ->locale('id')
                            ->translatedFormat('F Y');

                        Notification::make()
                            ->title('Evaluasi berhasil dibuat')
                            ->body(
                                "Data evaluasi karyawan periode {$period} berhasil dibuat."
                            )
                            ->success()
                            ->send();
                    }),
            ]);
    }

    private static function monthOptions(): array
    {
        return [
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
        ];
    }

    private static function yearOptions(): array
    {
        $currentYear = (int) now()->year;

        return collect(
            range($currentYear, $currentYear - 5)
        )
            ->mapWithKeys(
                fn(int $year): array => [
                    $year => (string) $year,
                ]
            )
            ->all();
    }
}
