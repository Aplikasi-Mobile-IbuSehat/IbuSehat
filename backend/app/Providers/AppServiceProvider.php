<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Database\QueryException;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Rate limiter untuk chat AI
        RateLimiter::for('chat', function ($request) {
            return Limit::perMinute(5)
                ->by($request->user()?->id ?: $request->ip());
        });

        // CA bundle untuk HTTPS keluar (lihat config/services.php 'http').
        // Verifikasi sertifikat tetap aktif; ini hanya memberi tahu lokasinya.
        $caBundle = config('services.http.ca_bundle');
        if (is_string($caBundle) && $caBundle !== '' && is_file($caBundle)) {
            Http::globalOptions(['verify' => $caBundle]);
        }

        // Auto-create database jika belum ada (fitur Hakim)
        $this->ensureMysqlDatabaseExists();
    }

    private function ensureMysqlDatabaseExists(): void
    {
        if (config('database.default') !== 'mysql') {
            return;
        }

        $host = (string) config('database.connections.mysql.host', '127.0.0.1');
        $port = (int) config('database.connections.mysql.port', 3306);
        $database = (string) config('database.connections.mysql.database', '');
        $username = (string) config('database.connections.mysql.username', 'root');
        $password = (string) config('database.connections.mysql.password', '');

        if ($database === '') {
            return;
        }

        try {
            \DB::connection('mysql')->select('SELECT 1');
            return;
        } catch (QueryException $e) {
            $message = (string) $e->getMessage();

            $unknownDb =
                str_contains($message, 'Unknown database') ||
                str_contains($message, '1049');

            if (!$unknownDb) {
                return;
            }
        } catch (\Throwable) {
            return;
        }

        try {
            $dsn = "mysql:host={$host};port={$port};charset=utf8mb4";

            $pdo = new \PDO(
                $dsn,
                $username,
                $password,
                [
                    \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
                ]
            );

            $quotedDb = '`' . str_replace('`', '``', $database) . '`';

            $pdo->exec(
                "CREATE DATABASE IF NOT EXISTS {$quotedDb}
                CHARACTER SET utf8mb4
                COLLATE utf8mb4_unicode_ci"
            );
        } catch (\Throwable) {
            // Jika gagal membuat database, migration akan menampilkan error yang jelas
        }
    }
}