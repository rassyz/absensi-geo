<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\OvertimeEmployee;
use Illuminate\Auth\Access\HandlesAuthorization;

class OvertimeEmployeePolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:OvertimeEmployee');
    }

    public function view(AuthUser $authUser, OvertimeEmployee $overtimeEmployee): bool
    {
        return $authUser->can('View:OvertimeEmployee');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:OvertimeEmployee');
    }

    public function update(AuthUser $authUser, OvertimeEmployee $overtimeEmployee): bool
    {
        return $authUser->can('Update:OvertimeEmployee');
    }

    public function delete(AuthUser $authUser, OvertimeEmployee $overtimeEmployee): bool
    {
        return $authUser->can('Delete:OvertimeEmployee');
    }

}