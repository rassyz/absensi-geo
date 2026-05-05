<?php

namespace App\Filament\Admin\Resources\Attendances\Tables;

use App\Exports\AttendanceExport;
// use Dom\Text;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DatePicker;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Maatwebsite\Excel\Facades\Excel;

class AttendancesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('date', 'desc')
            ->columns([
                TextColumn::make('employee.full_name')
                    ->label('Nama Karyawan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('employee.department.name')
                    ->label('Departemen')
                    ->sortable(),
                TextColumn::make('date')
                    ->label('Tanggal')
                    ->date()
                    ->sortable()
                    ->searchable(),
                TextColumn::make('check_in')
                    ->label('Absen Masuk')
                    ->dateTime('d M Y - H:i')
                    ->timezone('Asia/Jakarta')
                    ->sortable(),
                TextColumn::make('check_out')
                    ->label('Absen Keluar')
                    ->dateTime('d M Y - H:i')
                    ->timezone('Asia/Jakarta')
                    ->sortable(),
                ImageColumn::make('check_in_photo_path')
                    ->label('Foto Masuk')
                    ->disk('public') // Sesuaikan dengan disk dan path penyimpanan di controller
                    ->circular(), // Opsional: membuat foto jadi bulat agar tabel terlihat lebih rapi
                ImageColumn::make('check_out_photo_path')
                    ->label('Foto Keluar')
                    ->disk('public') // Sesuaikan dengan disk dan path penyimpanan di controller
                    ->circular(),
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
                SelectFilter::make('employee_id')
                    ->relationship('employee', 'full_name')
                    ->label('Nama Karyawan')
                    ->searchable()
                    ->preload(),
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
                    ->label('Ekspor Data Excel')
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
