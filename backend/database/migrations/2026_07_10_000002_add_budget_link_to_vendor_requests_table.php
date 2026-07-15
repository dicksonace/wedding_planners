<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('vendor_requests', function (Blueprint $table) {
            $table->foreignId('budget_item_id')->nullable()->after('response_message')->constrained('budget_items')->nullOnDelete();
            $table->decimal('quoted_amount', 12, 2)->nullable()->after('budget_item_id');
        });
    }

    public function down(): void
    {
        Schema::table('vendor_requests', function (Blueprint $table) {
            $table->dropConstrainedForeignId('budget_item_id');
            $table->dropColumn('quoted_amount');
        });
    }
};
