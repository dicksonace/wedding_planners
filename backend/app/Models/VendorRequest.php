<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VendorRequest extends Model
{
    protected $fillable = [
        'wedding_plan_id',
        'vendor_id',
        'couple_id',
        'message',
        'status',
        'response_message',
        'budget_item_id',
        'quoted_amount',
    ];

    protected function casts(): array
    {
        return [
            'quoted_amount' => 'decimal:2',
        ];
    }

    public function weddingPlan(): BelongsTo
    {
        return $this->belongsTo(WeddingPlan::class);
    }

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function couple(): BelongsTo
    {
        return $this->belongsTo(User::class, 'couple_id');
    }

    public function budgetItem(): BelongsTo
    {
        return $this->belongsTo(BudgetItem::class);
    }
}
