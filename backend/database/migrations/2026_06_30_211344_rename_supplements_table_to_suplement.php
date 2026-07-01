<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::rename('suplements', 'supplement');
    }

    public function down(): void
    {
        Schema::rename('supplement', 'suplements');
    }
};