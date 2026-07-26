<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('wedding_plans', function (Blueprint $table) {
            $table->string('guest_registration_token', 64)->nullable()->unique()->after('notes');
        });

        Schema::create('wedding_reminders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wedding_plan_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('notes')->nullable();
            $table->string('category')->default('other'); // fitting, hair, makeup, venue, other
            $table->dateTime('remind_at');
            $table->boolean('is_done')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wedding_reminders');

        Schema::table('wedding_plans', function (Blueprint $table) {
            $table->dropColumn('guest_registration_token');
        });
    }
};
