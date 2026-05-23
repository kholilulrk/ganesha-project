<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('work_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('task_id')->constrained()->cascadeOnDelete()->unique();
            $table->decimal('nilai_pekerjaan', 15, 2)->nullable();
            $table->text('catatan')->nullable();
            $table->boolean('sik')->default(false);
            $table->boolean('sc')->default(false);
            $table->boolean('verifikasi_i')->default(false);
            $table->boolean('verifikasi_ii')->default(false);
            $table->boolean('verifikasi_iii')->default(false);
            $table->date('tds')->nullable();
            $table->date('tdm')->nullable();
            $table->foreignId('created_by')->constrained('users');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('work_documents');
    }
};
