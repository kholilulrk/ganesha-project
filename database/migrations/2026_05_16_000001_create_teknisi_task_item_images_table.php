<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('teknisi_task_item_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('teknisi_task_item_id')->constrained('teknisi_task_items')->cascadeOnDelete();
            $table->string('image');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('teknisi_task_item_images');
    }
};
