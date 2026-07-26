<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WeddingReminder extends Model
{
    protected $fillable = [
        'wedding_plan_id',
        'title',
        'notes',
        'category',
        'remind_at',
        'is_done',
    ];

    protected function casts(): array
    {
        return [
            'remind_at' => 'datetime',
            'is_done' => 'boolean',
        ];
    }

    public function weddingPlan(): BelongsTo
    {
        return $this->belongsTo(WeddingPlan::class);
    }
}
