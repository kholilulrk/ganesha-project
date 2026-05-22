<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Support\Facades\Storage;
use Spatie\Permission\Models\Role;

class Document extends Model
{
    protected $fillable = [
        'title',
        'document_type',
        'file',
        'description',
        'uploaded_by',
        'visibility',
    ];

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    public function sharedRoles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class, 'document_role');
    }

    public function scopeVisibleTo($query, User $user)
    {
        return $query->where(function ($q) use ($user) {
            $q->where('visibility', 'all')
              ->orWhere(function ($sub) use ($user) {
                  $sub->where('visibility', 'roles')
                       ->whereHas('sharedRoles', fn($q) => $q->whereIn('role_id', $user->roles->pluck('id')));
              });
        });
    }

    public function url(): string
    {
        return Storage::url($this->file);
    }

    public function isImage(): bool
    {
        return str_starts_with($this->document_type, 'image/');
    }

    public function isPdf(): bool
    {
        return $this->document_type === 'application/pdf';
    }
}
