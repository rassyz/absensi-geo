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
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\AttendanceExport;
use Filament\Actions\Action;
use App\Models\Attendance;

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
                    ->label('Filter berdasarkan Tanggal')
                    ->form([
                        DatePicker::make('start_date')
                            ->label('Tanggal Mulai')
                            ->required(),
                        DatePicker::make('end_date')
                            ->label('Tanggal Akhir')
                            ->required(),
                    ])
                    ->query(function (Builder $query, array $data) {
                        if (!empty($data['start_date']) && !empty($data['end_date'])) {
                            $query->whereBetween('check_in', [$data['start_date'], $data['end_date']]);
                        }
                    }),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
                ViewAction::make(),
            ])
            ->toolbarActions([
                Action::make('export')
                    ->label('Ekspor Data Dashboard')
                    ->action(function ($action) {
                        // Ambil Livewire yang sedang menjalankan tabel
                        $livewire = $action->getLivewire();

                        // Ambil query yang sudah terfilter FILAMENT
                        $filteredQuery = $livewire->getFilteredTableQuery();

                        // Ambil data final
                        $dataToExport = $filteredQuery->get();

                        if ($dataToExport->isEmpty()) {
                            session()->flash('message', 'Tidak ada data untuk diekspor.');
                            return;
                        }

                        return Excel::download(
                            new AttendanceExport($dataToExport),
                            'attendance_dashboard_export_' . now()->format('Y_m_d_His') . '.xlsx'
                        );
                    }),
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
