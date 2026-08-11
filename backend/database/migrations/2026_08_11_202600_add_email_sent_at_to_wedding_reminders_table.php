<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('wedding_reminders', function (Blueprint $table) {
            $table->timestamp('email_sent_at')->nullable()->after('is_done');
        });
    }

    public function down(): void
    {
        Schema::table('wedding_reminders', function (Blueprint $table) {
            $table->dropColumn('email_sent_at');
        });
    }
};
