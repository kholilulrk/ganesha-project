<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('task_user', function (Blueprint $table) {
            $table->foreignId('task_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->primary(['task_id', 'user_id']);
        });

        DB::statement('INSERT INTO task_user (task_id, user_id) SELECT id, assigned_to FROM tasks WHERE assigned_to IS NOT NULL');

        Schema::table('tasks', function (Blueprint $table) {
            $table->dropForeign(['assigned_to']);
            $table->dropColumn('assigned_to');
        });
    }

    public function down(): void
    {
        Schema::table('tasks', function (Blueprint $table) {
            $table->foreignId('assigned_to')->nullable()->after('created_by')->constrained('users');
        });

        DB::statement('UPDATE tasks SET assigned_to = (SELECT user_id FROM task_user WHERE task_id = tasks.id LIMIT 1) WHERE id IN (SELECT task_id FROM task_user)');

        Schema::dropIfExists('task_user');
    }
};
