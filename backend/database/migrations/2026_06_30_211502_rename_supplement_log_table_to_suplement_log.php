<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::rename('supplement_logs', 'suplement_logs');
    }

    public function down(): void
    {
        Schema::rename('suplement_logs', 'supplement_logs');
    }
};