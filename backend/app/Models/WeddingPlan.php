<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WeddingPlan extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'bride_name',
        'groom_name',
        'wedding_date',
        'location',
        'region',
        'total_budget',
        'ceremony_types',
        'status',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'wedding_date' => 'date',
            'total_budget' => 'decimal:2',
            'ceremony_types' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function guests(): HasMany
    {
        return $this->hasMany(Guest::class);
    }

    public function budgetItems(): HasMany
    {
        return $this->hasMany(BudgetItem::class);
    }

    public function tasks(): HasMany
    {
        return $this->hasMany(PlanningTask::class);
    }

    public function vendorRequests(): HasMany
    {
        return $this->hasMany(VendorRequest::class);
    }

    public function media(): HasMany
    {
        return $this->hasMany(WeddingMedia::class);
    }
}
