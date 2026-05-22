<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('documents', function (Blueprint $table) {
            $table->string('visibility')->default('all')->after('description');
        });

        Schema::create('document_role', function (Blueprint $table) {
            $table->foreignId('document_id')->constrained()->cascadeOnDelete();
            $table->foreignId('role_id')->constrained('roles')->cascadeOnDelete();
            $table->primary(['document_id', 'role_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('document_role');
        Schema::table('documents', function (Blueprint $table) {
            $table->dropColumn('visibility');
        });
    }
};
