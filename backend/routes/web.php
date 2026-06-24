<?php

use App\Http\Controllers\RsvpController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/rsvp/{token}', [RsvpController::class, 'show'])->name('rsvp.show');
Route::get('/rsvp/{token}/accept', [RsvpController::class, 'accept'])->name('rsvp.accept');
Route::get('/rsvp/{token}/decline', [RsvpController::class, 'decline'])->name('rsvp.decline');
