<?php

declare(strict_types=1);

namespace App\Repositories\Eloquent;

use App\Models\Leave;
use App\Repositories\Contracts\LeaveRepositoryInterface;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class LeaveRepository implements LeaveRepositoryInterface
{
    /**
     * {@inheritdoc}
     */
    public function create(array $data): Leave
    {
        return Leave::create($data);
    }

    /**
     * {@inheritdoc}
     */
    public function findById(int $id, array $relations = []): ?Leave
    {
        $query = Leave::query();

        if (!empty($relations)) {
            $query->with($relations);
        }

        return $query->find($id);
    }

    /**
     * {@inheritdoc}
     */
    public function getStatusCounts(int $employeeId): Collection
    {
        return Leave::where('employee_id', $employeeId)
            ->select('status', DB::raw('count(*) as total'))
            ->groupBy('status')
            ->get()
            ->pluck('total', 'status');
    }

    /**
     * {@inheritdoc}
     */
    public function getEmployeeLeaves(int $employeeId, array $relations = ['leaveType', 'approver']): Collection
    {
        return Leave::with($relations)
            ->where('employee_id', $employeeId)
            ->orderBy('created_at', 'desc')
            ->get();
    }

    /**
     * {@inheritdoc}
     */
    public function getPendingTeamLeaves(
        int $employeeId,
        string $position,
        ?int $departmentId,
        array $relations = ['employee.user', 'employee.department', 'leaveType']
    ): Collection {
        $query = Leave::with($relations)
            ->where('status', 'Pending');

        if ($position === 'manager') {
            $query->whereHas('employee', static function ($employeeQuery) use ($employeeId): void {
                $employeeQuery->where('id', '!=', $employeeId);
            });
        } elseif ($position === 'head' && $departmentId !== null) {
            $query->whereHas('employee', static function ($employeeQuery) use ($employeeId, $departmentId): void {
                $employeeQuery
                    ->where('department_id', $departmentId)
                    ->where('id', '!=', $employeeId);
            });
        } else {
            $query->whereRaw('1 = 0');
        }

        return $query->orderBy('created_at', 'desc')->get();
    }

    /**
     * {@inheritdoc}
     */
    public function update(int $id, array $data): bool
    {
        return (bool) Leave::where('id', $id)->update($data);
    }
}

