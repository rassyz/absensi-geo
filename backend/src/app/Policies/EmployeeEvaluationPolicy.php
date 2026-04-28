<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\EmployeeEvaluation;
use Illuminate\Auth\Access\HandlesAuthorization;

class EmployeeEvaluationPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:EmployeeEvaluation');
    }

    public function view(AuthUser $authUser, EmployeeEvaluation $employeeEvaluation): bool
    {
        return $authUser->can('View:EmployeeEvaluation');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:EmployeeEvaluation');
    }

    public function update(AuthUser $authUser, EmployeeEvaluation $employeeEvaluation): bool
    {
        return $authUser->can('Update:EmployeeEvaluation');
    }

    public function delete(AuthUser $authUser, EmployeeEvaluation $employeeEvaluation): bool
    {
        return $authUser->can('Delete:EmployeeEvaluation');
    }

}