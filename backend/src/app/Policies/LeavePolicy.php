<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\Leave;
use Illuminate\Auth\Access\HandlesAuthorization;

class LeavePolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:Leave');
    }

    public function view(AuthUser $authUser, Leave $leave): bool
    {
        return $authUser->can('View:Leave');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:Leave');
    }

    public function update(AuthUser $authUser, Leave $leave): bool
    {
        return $authUser->can('Update:Leave');
    }

    public function delete(AuthUser $authUser, Leave $leave): bool
    {
        return $authUser->can('Delete:Leave');
    }

}