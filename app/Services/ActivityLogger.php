<?php

namespace App\Services;

use App\Models\ActivityLog;
use Illuminate\Database\Eloquent\Model;

class ActivityLogger
{
    private ?Model $subject = null;
    private ?int $userId = null;
    private string $logName = 'default';
    private array $properties = [];

    public function on(Model $subject): static
    {
        $this->subject = $subject;
        return $this;
    }

    public function by(?int $userId): static
    {
        $this->userId = $userId;
        return $this;
    }

    public function withLogName(string $name): static
    {
        $this->logName = $name;
        return $this;
    }

    public function withProperties(array $properties): static
    {
        $this->properties = $properties;
        return $this;
    }

    public function log(string $description): ActivityLog
    {
        return ActivityLog::create([
            'user_id' => $this->userId ?? auth()->id(),
            'log_name' => $this->logName,
            'description' => $description,
            'subject_type' => $this->subject ? get_class($this->subject) : null,
            'subject_id' => $this->subject?->getKey(),
            'properties' => empty($this->properties) ? null : $this->properties,
        ]);
    }
}
