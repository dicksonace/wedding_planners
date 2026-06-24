<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PlanningTask extends Model
{
    protected $fillable = [
        'wedding_plan_id',
        'title',
        'description',
        'due_date',
        'status',
        'priority',
        'ceremony_type',
    ];

    protected function casts(): array
    {
        return [
            'due_date' => 'date',
        ];
    }

    public function weddingPlan(): BelongsTo
    {
        return $this->belongsTo(WeddingPlan::class);
    }
}
