<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('announcements', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('content');
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->string('target_type'); // all_users, specific_users, specific_roles
            $table->timestamps();
        });

        Schema::create('announcement_user', function (Blueprint $table) {
            $table->foreignId('announcement_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->primary(['announcement_id', 'user_id']);
        });

        Schema::create('announcement_role', function (Blueprint $table) {
            $table->foreignId('announcement_id')->constrained()->cascadeOnDelete();
            $table->foreignId('role_id')->constrained('roles')->cascadeOnDelete();
            $table->primary(['announcement_id', 'role_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('announcement_role');
        Schema::dropIfExists('announcement_user');
        Schema::dropIfExists('announcements');
    }
};
