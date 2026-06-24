<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

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
    ];

    protected function casts(): array
    {
        return [
            'plus_one' => 'boolean',
        ];
    }

    public function weddingPlan(): BelongsTo
    {
        return $this->belongsTo(WeddingPlan::class);
    }
}
