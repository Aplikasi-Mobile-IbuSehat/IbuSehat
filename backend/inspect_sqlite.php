<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

config(['database.connections.sqlite.database' => database_path('database.sqlite')]);
$connection = DB::connection('sqlite');

try {
    $tables = $connection->select("SELECT name FROM sqlite_master WHERE type='table'");
    echo "Tables in SQLite:\n";
    foreach ($tables as $table) {
        echo "- " . $table->name . "\n";
    }
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
