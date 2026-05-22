<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class TeknisiTaskItemImage extends Model
{
    protected $fillable = [
        'teknisi_task_item_id',
        'image',
    ];

    public function teknisiTaskItem(): BelongsTo
    {
        return $this->belongsTo(TeknisiTaskItem::class);
    }

    public function imageUrl(): ?string
    {
        return $this->image ? Storage::url($this->image) : null;
    }
}
