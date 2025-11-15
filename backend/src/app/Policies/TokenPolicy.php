<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use Rupadana\ApiService\Models\Token;
use Illuminate\Auth\Access\HandlesAuthorization;

class TokenPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:Token');
    }

    public function view(AuthUser $authUser, Token $token): bool
    {
        return $authUser->can('View:Token');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:Token');
    }

    public function update(AuthUser $authUser, Token $token): bool
    {
        return $authUser->can('Update:Token');
    }

    public function delete(AuthUser $authUser, Token $token): bool
    {
        return $authUser->can('Delete:Token');
    }

}