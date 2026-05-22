<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Spatie\Permission\Models\Role;

class Announcement extends Model
{
    protected $fillable = [
        'title',
        'content',
        'created_by',
        'target_type',
        'scheduled_at',
        'expired_at',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
            'expired_at' => 'datetime',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function specificUsers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'announcement_user');
    }

    public function specificRoles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class, 'announcement_role');
    }

    public function getShareStatusAttribute(): string
    {
        if ($this->expired_at && $this->expired_at->isPast()) {
            return 'expired';
        }
        if ($this->scheduled_at && $this->scheduled_at->isFuture()) {
            return 'scheduled';
        }
        return 'active';
    }

    public function scopeScheduled($query)
    {
        return $query->where(function ($q) {
            $q->whereNull('scheduled_at')
              ->orWhere('scheduled_at', '<=', now());
        })->where(function ($q) {
            $q->whereNull('expired_at')
              ->orWhere('expired_at', '>=', now());
        });
    }

    public function scopeVisibleTo($query, User $user)
    {
        return $query->where(function ($q) use ($user) {
            $q->where('target_type', 'all_users')
              ->orWhere(function ($sub) use ($user) {
                  $sub->where('target_type', 'specific')
                       ->where(function ($inner) use ($user) {
                           $inner->whereHas('specificUsers', fn($q) => $q->where('user_id', $user->id))
                                 ->orWhereHas('specificRoles', fn($q) => $q->whereIn('role_id', $user->roles->pluck('id')));
                       });
              });
        });
    }
}
