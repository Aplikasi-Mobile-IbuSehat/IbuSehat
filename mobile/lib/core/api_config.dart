// Steps to run:
// 1. Start XAMPP and make sure MySQL is running
// 2. Run: php artisan migrate:fresh --seed
// 3. Run: php artisan serve
// 4. Run: flutter run -d chrome
// After these 4 steps, Program Latihan should work!
//
/// Base URL for Laravel API (Flutter web/Chrome).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
 