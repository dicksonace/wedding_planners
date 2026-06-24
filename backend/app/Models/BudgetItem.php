<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BudgetItem extends Model
{
    protected $fillable = [
        'wedding_plan_id',
        'category',
        'description',
        'estimated_amount',
        'actual_amount',
        'is_paid',
        'payment_date',
    ];

    protected function casts(): array
    {
        return [
            'estimated_amount' => 'decimal:2',
            'actual_amount' => 'decimal:2',
            'is_paid' => 'boolean',
            'payment_date' => 'date',
        ];
    }

    public function weddingPlan(): BelongsTo
    {
        return $this->belongsTo(WeddingPlan::class);
    }
}
