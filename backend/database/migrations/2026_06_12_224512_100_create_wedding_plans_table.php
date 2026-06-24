<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wedding_plans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->string('bride_name')->nullable();
            $table->string('groom_name')->nullable();
            $table->date('wedding_date')->nullable();
            $table->string('location')->nullable();
            $table->string('region')->nullable();
            $table->decimal('total_budget', 12, 2)->default(0);
            $table->json('ceremony_types')->nullable();
            $table->string('status')->default('planning');
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wedding_plans');
    }
};
