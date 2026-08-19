<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\WorkAssignment;
use Illuminate\Auth\Access\HandlesAuthorization;

class WorkAssignmentPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:WorkAssignment');
    }

    public function view(AuthUser $authUser, WorkAssignment $workAssignment): bool
    {
        return $authUser->can('View:WorkAssignment');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:WorkAssignment');
    }

    public function update(AuthUser $authUser, WorkAssignment $workAssignment): bool
    {
        return $authUser->can('Update:WorkAssignment');
    }

    public function delete(AuthUser $authUser, WorkAssignment $workAssignment): bool
    {
        return $authUser->can('Delete:WorkAssignment');
    }

}