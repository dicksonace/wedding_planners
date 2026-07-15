<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

trait AuthorizesCouple
{
    protected function authorizeCouple(Request $request): void
    {
        abort_unless($request->user()->isCouple(), 403, 'This action is for couples only.');
    }
}
