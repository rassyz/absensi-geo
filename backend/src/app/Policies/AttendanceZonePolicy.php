<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\AttendanceZone;
use Illuminate\Auth\Access\HandlesAuthorization;

class AttendanceZonePolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:AttendanceZone');
    }

    public function view(AuthUser $authUser, AttendanceZone $attendanceZone): bool
    {
        return $authUser->can('View:AttendanceZone');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:AttendanceZone');
    }

    public function update(AuthUser $authUser, AttendanceZone $attendanceZone): bool
    {
        return $authUser->can('Update:AttendanceZone');
    }

    public function delete(AuthUser $authUser, AttendanceZone $attendanceZone): bool
    {
        return $authUser->can('Delete:AttendanceZone');
    }

}