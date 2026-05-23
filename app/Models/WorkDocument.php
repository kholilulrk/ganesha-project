<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WorkDocument extends Model
{
    protected $fillable = [
        'task_id',
        'nilai_pekerjaan',
        'catatan',
        'sik',
        'sc',
        'verifikasi_i',
        'verifikasi_ii',
        'verifikasi_iii',
        'sik_file',
        'sph_file',
        'spk_file',
        'spektek_file',
        'tds',
        'tdm',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'nilai_pekerjaan' => 'decimal:2',
            'sik' => 'boolean',
            'sc' => 'boolean',
            'verifikasi_i' => 'boolean',
            'verifikasi_ii' => 'boolean',
            'verifikasi_iii' => 'boolean',
            'tds' => 'date:Y-m-d',
            'tdm' => 'date:Y-m-d',
        ];
    }

    public function task(): BelongsTo
    {
        return $this->belongsTo(Task::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
