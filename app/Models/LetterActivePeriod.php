<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LetterActivePeriod extends Model
{
    protected $fillable = [
        'nama_surat',
        'start_aktif',
        'jenis_surat',
        'masa_aktif_berakhir',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'start_aktif' => 'date:Y-m-d',
            'masa_aktif_berakhir' => 'date:Y-m-d',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
