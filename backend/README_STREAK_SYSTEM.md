# Streak System Implementation - IbuSehat Backend

## 📋 Overview

A complete workout streak tracking system for the IbuSehat application. Tracks consecutive days of workout completion and maintains user streaks.

## ✅ Files Created

### Migrations
- `database/migrations/2026_06_16_152448_create_user_streaks_table.php`
- `database/migrations/2026_06_16_152505_create_workout_logs_table.php`

### Models
- `app/Models/UserStreak.php` - User streak data model
- `app/Models/WorkoutLog.php` - Workout completion log model

### Services
- `app/Services/StreakService.php` - Business logic for streak management

### Controllers
- `app/Http/Controllers/StreakController.php` - API endpoint handlers

### Requests
- `app/Http/Requests/CompleteWorkoutRequest.php` - Validation for workout completion

### Routes
- Updated `routes/api.php` with new endpoints:
  - `POST /api/workout/complete` - Complete a workout
  - `GET /api/streak` - Get streak information

### Documentation
- `docs/STREAK_API.md` - Complete API documentation

### Tests
- `tests/Feature/StreakTest.php` - Feature tests for the streak system

## 🗄️ Database Schema

### user_streaks Table
```
- id (bigint, primary key)
- user_id (bigint, foreign key, unique)
- streak_active (int, default 0)
- streak_longest (int, default 0)
- last_workout_date (date, nullable)
- created_at (timestamp)
- updated_at (timestamp)
```

### workout_logs Table
```
- id (bigint, primary key)
- user_id (bigint, foreign key)
- workout_id (bigint, foreign key, nullable)
- completed_at (date)
- is_completed (boolean, default false)
- created_at (timestamp)
- updated_at (timestamp)
- Index: (user_id, completed_at)
```

## 🚀 API Endpoints

### 1. Complete Workout
**POST** `/api/workout/complete`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Body:**
```json
{
  "workout_id": 1  // optional
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "streak_active": 5,
    "streak_longest": 10,
    "is_new_streak_day": true,
    "message": "Streak berhasil diperbarui!"
  }
}
```

### 2. Get Streak Information
**GET** `/api/streak?year=2026&month=6`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "streak_active": 5,
    "streak_longest": 10,
    "total_aktivitas": 20,
    "hari_aktif_bulan_ini": 12,
    "calendar": [
      {
        "date": "2026-06-01",
        "status": "completed"
      },
      {
        "date": "2026-06-02",
        "status": "missed"
      }
    ]
  }
}
```

**Calendar Status Values:**
- `completed` - Workout completed on this date
- `missed` - No workout (past date)
- `today` - Today's date
- `future` - Future date

## 🔧 Installation & Setup

### 1. Run Migrations
```bash
cd backend
php artisan migrate
```

### 2. Test the APIs
```bash
# Run tests
php artisan test --filter StreakTest

# Or run all tests
php artisan test
```

### 3. Test with cURL

**Complete a workout:**
```bash
curl -X POST http://localhost:8000/api/workout/complete \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"workout_id": 1}'
```

**Get streak data:**
```bash
curl -X GET "http://localhost:8000/api/streak?year=2026&month=6" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📊 Streak Logic

1. **First Workout:**
   - Creates streak record with `streak_active = 1`

2. **Consecutive Days:**
   - If last workout was yesterday → increment streak
   - If last workout was today → don't change streak
   - If missed days → reset streak to 1

3. **Multiple Workouts Per Day:**
   - Only first workout counts toward streak
   - Additional workouts logged but don't affect streak

4. **Longest Streak:**
   - Automatically updated when current streak exceeds it

## 🧪 Testing

Run the feature tests:
```bash
php artisan test tests/Feature/StreakTest.php
```

Test cases include:
- ✅ First workout creates streak
- ✅ Second workout same day doesn't increase streak
- ✅ Get streak returns correct data structure
- ✅ Unauthenticated requests fail
- ✅ Invalid workout_id fails validation

## 📱 Mobile Integration Example

```dart
// In your Flutter app
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> completeWorkout(String token, int? workoutId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/workout/complete'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'workout_id': workoutId}),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data'];
  }
  throw Exception('Failed to complete workout');
}

Future<Map<String, dynamic>> getStreak(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/streak'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data'];
  }
  throw Exception('Failed to get streak');
}
```

## 🔐 Security Features

- ✅ Authentication required (Sanctum)
- ✅ User can only access their own streaks
- ✅ Input validation on all endpoints
- ✅ Database transactions for data consistency
- ✅ Foreign key constraints

## 📝 Notes

- All dates use server timezone
- Streaks are based on calendar days, not 24-hour periods
- User streaks are auto-created on first workout
- Workout logs are never deleted (audit trail)

## 🐛 Troubleshooting

### Migration Error
```bash
# If you get foreign key constraint errors:
php artisan migrate:fresh
```

### Test Failures
```bash
# Clear cache and run tests again:
php artisan config:clear
php artisan cache:clear
php artisan test
```

### API Not Working
1. Check if migrations ran successfully
2. Verify authentication token is valid
3. Check error logs: `storage/logs/laravel.log`

## 📚 Additional Resources

- Full API Documentation: `docs/STREAK_API.md`
- Laravel Documentation: https://laravel.com/docs
- Sanctum Documentation: https://laravel.com/docs/sanctum

## ✨ Features

- ✅ Track consecutive workout days
- ✅ Record longest streak ever
- ✅ Calendar view of workout history
- ✅ Multiple workouts per day support
- ✅ Automatic streak calculation
- ✅ Monthly activity summary
- ✅ RESTful API design
- ✅ Comprehensive validation
- ✅ Full test coverage

---

**Created:** June 16, 2026
**Version:** 1.0.0
**Author:** IbuSehat Development Team