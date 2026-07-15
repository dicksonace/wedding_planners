<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class WeddingMedia extends Model
{
    protected $table = 'wedding_media';

    protected $fillable = [
        'wedding_plan_id',
        'user_id',
        'type',
        'title',
        'file_path',
        'mime_type',
        'file_size',
    ];

    protected $appends = ['url'];

    public function weddingPlan(): BelongsTo
    {
        return $this->belongsTo(WeddingPlan::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function getUrlAttribute(): string
    {
        return Storage::disk('public')->url($this->file_path);
    }
}
