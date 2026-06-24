<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('couple')->after('email');
            $table->string('phone')->nullable()->after('role');
            $table->string('partner_name')->nullable()->after('phone');
            $table->string('region')->nullable()->after('partner_name');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['role', 'phone', 'partner_name', 'region']);
        });
    }
};
