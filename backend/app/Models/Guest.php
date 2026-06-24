<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class Guest extends Model
{
    protected $fillable = [
        'wedding_plan_id',
        'name',
        'phone',
        'email',
        'side',
        'rsvp_status',
        'plus_one',
        'table_number',
        'invitation_token',
        'invitation_sent_at',
    ];

    protected function casts(): array
    {
        return [
            'plus_one' => 'boolean',
            'invitation_sent_at' => 'datetime',
        ];
    }

    public function weddingPlan(): BelongsTo
    {
        return $this->belongsTo(WeddingPlan::class);
    }

    public function ensureInvitationToken(): string
    {
        if (! $this->invitation_token) {
            $this->update(['invitation_token' => Str::random(48)]);
            $this->refresh();
        }

        return $this->invitation_token;
    }
}
