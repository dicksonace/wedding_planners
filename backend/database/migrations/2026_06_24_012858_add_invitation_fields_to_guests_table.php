<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('guests', function (Blueprint $table) {
            $table->string('invitation_token', 64)->nullable()->unique()->after('table_number');
            $table->timestamp('invitation_sent_at')->nullable()->after('invitation_token');
        });
    }

    public function down(): void
    {
        Schema::table('guests', function (Blueprint $table) {
            $table->dropColumn(['invitation_token', 'invitation_sent_at']);
        });
    }
};
