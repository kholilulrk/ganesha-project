<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('work_documents', function (Blueprint $table) {
            $table->string('sik_file')->nullable()->after('sik');
            $table->string('sph_file')->nullable()->after('sc');
            $table->string('spk_file')->nullable()->after('verifikasi_iii');
            $table->string('spektek_file')->nullable()->after('spk_file');
        });
    }

    public function down(): void
    {
        Schema::table('work_documents', function (Blueprint $table) {
            $table->dropColumn(['sik_file', 'sph_file', 'spk_file', 'spektek_file']);
        });
    }
};
