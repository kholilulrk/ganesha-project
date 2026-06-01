<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('letter_active_periods', function (Blueprint $table) {
            $table->id();
            $table->string('nama_surat');
            $table->date('start_aktif');
            $table->string('jenis_surat');
            $table->date('masa_aktif_berakhir');
            $table->foreignId('created_by')->constrained('users');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('letter_active_periods');
    }
};
