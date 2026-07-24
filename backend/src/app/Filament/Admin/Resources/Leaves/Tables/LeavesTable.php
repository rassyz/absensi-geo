<?php

namespace App\Filament\Admin\Resources\Leaves\Tables;

use Carbon\Carbon;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class LeavesTable
{
    public static function configure(Table $table): Table
    {
        $monthOptions = [
            1  => 'Januari',
            2  => 'Februari',
            3  => 'Maret',
            4  => 'April',
            5  => 'Mei',
            6  => 'Juni',
            7  => 'Juli',
            8  => 'Agustus',
            9  => 'September',
            10 => 'Oktober',
            11 => 'November',
            12 => 'Desember',
        ];

        /*
         * Menampilkan pilihan tahun:
         * 1 tahun ke depan sampai 5 tahun ke belakang.
         */
        $yearOptions = collect(
            range(now()->year + 1, now()->year - 5)
        )->mapWithKeys(
            fn(int $year): array => [
                $year => (string) $year,
            ]
        )->all();

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
                    ->date('d F Y')
                    ->sortable(),

                TextColumn::make('end_date')
                    ->label('Tanggal Selesai')
                    ->date('d F Y')
                    ->sortable(),

                TextColumn::make('apply_days')
                    ->label('Jumlah Hari')
                    ->numeric()
                    ->sortable(),

                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'Pending'   => 'warning',
                        'Approved'  => 'success',
                        'Rejected'  => 'danger',
                        'Cancelled' => 'gray',
                        default     => 'primary',
                    })
                    ->searchable(),

                TextColumn::make('approver.name')
                    ->label('Disetujui Oleh')
                    ->placeholder('-')
                    ->sortable(),

                TextColumn::make('approved_at')
                    ->label('Tanggal Persetujuan')
                    ->dateTime('d F Y - H:i')
                    ->placeholder('-')
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
                Filter::make('periode_cuti')
                    ->label('Periode Cuti')
                    ->schema([
                        Select::make('month')
                            ->label('Bulan')
                            ->options($monthOptions)
                            ->default(now()->month)
                            ->required()
                            ->native(false),

                        Select::make('year')
                            ->label('Tahun')
                            ->options($yearOptions)
                            ->default(now()->year)
                            ->required()
                            ->native(false),
                    ])
                    ->query(function (
                        Builder $query,
                        array $data
                    ): Builder {
                        $month = isset($data['month'])
                            ? (int) $data['month']
                            : null;

                        $year = isset($data['year'])
                            ? (int) $data['year']
                            : null;

                        if (! $month || ! $year) {
                            return $query;
                        }

                        $periodStart = Carbon::create(
                            $year,
                            $month,
                            1
                        )->startOfMonth();

                        $periodEnd = Carbon::create(
                            $year,
                            $month,
                            1
                        )->endOfMonth();

                        return $query
                            ->whereDate(
                                'start_date',
                                '<=',
                                $periodEnd
                            )
                            ->whereDate(
                                'end_date',
                                '>=',
                                $periodStart
                            );
                    })
                    ->indicateUsing(function (array $data): ?string {
                        $month = isset($data['month'])
                            ? (int) $data['month']
                            : null;

                        $year = isset($data['year'])
                            ? (int) $data['year']
                            : null;

                        if (! $month || ! $year) {
                            return null;
                        }

                        $period = Carbon::create(
                            $year,
                            $month,
                            1
                        )
                            ->locale('id')
                            ->translatedFormat('F Y');

                        return "Periode: {$period}";
                    }),
            ])

            ->deferFilters(false)

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
