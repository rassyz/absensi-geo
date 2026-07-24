<?php

namespace App\Filament\Admin\Resources\Leaves\Widgets;

use App\Filament\Admin\Resources\Leaves\Pages\ListLeaves;
use Filament\Widgets\ChartWidget;
use Filament\Widgets\Concerns\InteractsWithPageTable;
use Illuminate\Database\Eloquent\Builder;

class LeaveStatusChart extends ChartWidget
{
    use InteractsWithPageTable;

    protected function getTablePage(): string
    {
        return ListLeaves::class;
    }

    public function getHeading(): ?string
    {
        return 'Distribusi Status Cuti';
    }

    protected function getData(): array
    {
        $filteredQuery = $this->getPageTableQuery();

        $pending = $this->countByStatus(
            $filteredQuery,
            'Pending'
        );

        $approved = $this->countByStatus(
            $filteredQuery,
            'Approved'
        );

        $rejected = $this->countByStatus(
            $filteredQuery,
            'Rejected'
        );

        return [
            'datasets' => [
                [
                    'label' => 'Total Cuti',
                    'data' => [
                        $pending,
                        $approved,
                        $rejected,
                    ],
                    'backgroundColor' => [
                        '#eab308',
                        '#22c55e',
                        '#ef4444',
                    ],
                    'borderColor' => '#18181b',
                    'borderWidth' => 2,
                ],
            ],
            'labels' => [
                "Menunggu Persetujuan ({$pending})",
                "Disetujui ({$approved})",
                "Ditolak ({$rejected})",
            ],
        ];
    }

    private function countByStatus(
        Builder $query,
        string $status
    ): int {
        return (clone $query)
            ->reorder()
            ->where('status', $status)
            ->count();
    }

    protected function getType(): string
    {
        return 'pie';
    }

    protected function getOptions(): array
    {
        return [
            'maintainAspectRatio' => false,
            'plugins' => [
                'legend' => [
                    'position' => 'right',
                    'labels' => [
                        'font' => [
                            'weight' => 'bold',
                        ],
                    ],
                ],
            ],
        ];
    }
}
