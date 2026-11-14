@echo off
echo ========================================
echo IbuSehat Streak System Setup
echo ========================================
echo.

echo [1/3] Running migrations...
php artisan migrate
if %errorlevel% neq 0 (
    echo ERROR: Migration failed!
    pause
    exit /b 1
)
echo.

echo [2/3] Clearing caches...
php artisan cache:clear
php artisan config:clear
php artisan route:clear
echo.

echo [3/3] Running tests...
php artisan test --filter=StreakTest
if %errorlevel% neq 0 (
    echo WARNING: Some tests failed!
)
echo.

echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo API Endpoints Available:
echo - POST /api/workout/complete
echo - GET  /api/streak
echo.
echo Documentation: docs/STREAK_API.md
echo.
pause
