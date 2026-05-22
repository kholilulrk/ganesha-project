<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class ShoppingItem extends Model
{
    protected $fillable = [
        'task_id',
        'item_name',
        'qty',
        'unit',
        'is_checked',
        'notes',
        'image',
        'checked_by',
    ];

    protected function casts(): array
    {
        return [
            'is_checked' => 'boolean',
            'qty' => 'integer',
        ];
    }

    public function task(): BelongsTo
    {
        return $this->belongsTo(Task::class);
    }

    public function checker(): BelongsTo
    {
        return $this->belongsTo(User::class, 'checked_by');
    }

    public function imageUrl(): ?string
    {
        return $this->image ? Storage::url($this->image) : null;
    }
}
