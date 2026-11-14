# Streak System API Documentation

## Overview
The Streak System tracks workout completion and maintains user streaks based on consecutive days of activity.

## Database Schema

### Table: `user_streaks`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Foreign key to users table (unique) |
| streak_active | int | Current active streak count (default: 0) |
| streak_longest | int | Longest streak ever achieved (default: 0) |
| last_workout_date | date | Date of last completed workout (nullable) |
| created_at | timestamp | Record creation time |
| updated_at | timestamp | Record last update time |

### Table: `workout_logs`
| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Foreign key to users table |
| workout_id | bigint | Foreign key to workout_programs table (nullable) |
| completed_at | date | Date when workout was completed |
| is_completed | boolean | Completion status (default: false) |
| created_at | timestamp | Record creation time |
| updated_at | timestamp | Record last update time |

**Indexes:**
- `workout_logs (user_id, completed_at)` - For faster queries

---

## API Endpoints

### 1. Complete Workout

**Endpoint:** `POST /api/workout/complete`

**Authentication:** Required (Bearer token)

**Description:** Records a workout completion and updates the user's streak.

**Request Body:**
```json
{
  "workout_id": 1
}
```

**Request Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| workout_id | integer | No | ID of the workout program (nullable) |

**Success Response (200):**
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

**Response Fields:**
- `streak_active`: Current consecutive days streak
- `streak_longest`: Longest streak ever achieved
- `is_new_streak_day`: Boolean indicating if this workout counted toward today's streak
- `message`: Human-readable message

**Already Completed Today Response (200):**
```json
{
  "success": true,
  "data": {
    "streak_active": 5,
    "streak_longest": 10,
    "is_new_streak_day": false,
    "message": "Workout berhasil dicatat, namun streak sudah dihitung hari ini."
  }
}
```

**Validation Error Response (422):**
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "workout_id": [
      "Workout tidak ditemukan."
    ]
  }
}
```

**Error Response (500):**
```json
{
  "success": false,
  "message": "Gagal mencatat workout: [error message]"
}
```

**cURL Example:**
```bash
curl -X POST https://api.example.com/api/workout/complete \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"workout_id": 1}'
```

---

### 2. Get Streak Information

**Endpoint:** `GET /api/streak`

**Authentication:** Required (Bearer token)

**Description:** Retrieves detailed streak information including calendar data for a specific month.

**Query Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| year | integer | No | Current year | Year for calendar (2020-2100) |
| month | integer | No | Current month | Month for calendar (1-12) |

**Success Response (200):**
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
        "status": "completed"
      },
      {
        "date": "2026-06-03",
        "status": "missed"
      },
      {
        "date": "2026-06-04",
        "status": "today"
      },
      {
        "date": "2026-06-05",
        "status": "future"
      }
    ]
  }
}
```

**Response Fields:**
- `streak_active`: Current active streak (consecutive days)
- `streak_longest`: All-time longest streak
- `total_aktivitas`: Total number of completed workouts (all time)
- `hari_aktif_bulan_ini`: Number of active days in the requested month
- `calendar`: Array of all days in the requested month with their status

**Calendar Status Values:**
- `completed`: Workout was completed on this date
- `missed`: No workout on this date (date is in the past)
- `today`: Today's date
- `future`: Future date (not yet reached)

**Validation Error Response (422):**
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "month": [
      "The month field must be between 1 and 12."
    ]
  }
}
```

**Error Response (500):**
```json
{
  "success": false,
  "message": "Gagal mengambil data streak: [error message]"
}
```

**cURL Example:**
```bash
# Get current month
curl -X GET "https://api.example.com/api/streak" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get specific month
curl -X GET "https://api.example.com/api/streak?year=2026&month=6" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Streak Logic

### How Streaks Work

1. **First Workout Ever:**
   - Sets `streak_active = 1`
   - Sets `last_workout_date = today`

2. **Workout Yesterday (Continue Streak):**
   - If `last_workout_date = yesterday`
   - Increments `streak_active += 1`
   - Updates `last_workout_date = today`

3. **Workout Today (Already Counted):**
   - If `last_workout_date = today`
   - No change to streak
   - Second workout of the day doesn't count

4. **Missed Days (Reset Streak):**
   - If `last_workout_date < yesterday`
   - Resets `streak_active = 1`
   - Updates `last_workout_date = today`

5. **Longest Streak Update:**
   - If `streak_active > streak_longest`
   - Updates `streak_longest = streak_active`

### Multiple Workouts Per Day
- Only the first completed workout of each day counts toward the streak
- Subsequent workouts on the same day are logged but don't affect the streak counter
- The response will indicate `is_new_streak_day: false` for additional workouts

---

## Usage Examples

### Flutter/Dart Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class StreakService {
  final String baseUrl = 'https://api.example.com/api';
  final String token;

  StreakService(this.token);

  Future<Map<String, dynamic>> completeWorkout(int? workoutId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workout/complete'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'workout_id': workoutId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to complete workout');
    }
  }

  Future<Map<String, dynamic>> getStreak({int? year, int? month}) async {
    final queryParams = <String, String>{};
    if (year != null) queryParams['year'] = year.toString();
    if (month != null) queryParams['month'] = month.toString();

    final uri = Uri.parse('$baseUrl/streak').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get streak data');
    }
  }
}
```

### JavaScript/React Example

```javascript
const API_BASE_URL = 'https://api.example.com/api';

async function completeWorkout(token, workoutId = null) {
  const response = await fetch(`${API_BASE_URL}/workout/complete`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ workout_id: workoutId }),
  });

  if (!response.ok) {
    throw new Error('Failed to complete workout');
  }

  return response.json();
}

async function getStreak(token, year = null, month = null) {
  const params = new URLSearchParams();
  if (year) params.append('year', year);
  if (month) params.append('month', month);

  const url = `${API_BASE_URL}/streak?${params.toString()}`;
  
  const response = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error('Failed to get streak data');
  }

  return response.json();
}
```

---

## Testing

### Test Complete Workout API

1. **Complete First Workout:**
```bash
curl -X POST http://localhost:8000/api/workout/complete \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"workout_id": 1}'
```

Expected: `streak_active: 1`, `is_new_streak_day: true`

2. **Complete Second Workout Same Day:**
```bash
curl -X POST http://localhost:8000/api/workout/complete \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"workout_id": 2}'
```

Expected: Same streak, `is_new_streak_day: false`

3. **Get Streak Data:**
```bash
curl -X GET "http://localhost:8000/api/streak?year=2026&month=6" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Error Handling

### Common Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 401 | Unauthorized | Check if token is valid and not expired |
| 422 | Validation Error | Check request parameters |
| 500 | Server Error | Check server logs, retry request |

### Best Practices

1. Always check `success` field in response
2. Handle `is_new_streak_day: false` gracefully (show different message)
3. Cache streak data locally and update after successful completion
4. Implement retry logic for network failures
5. Show user-friendly error messages from the `message` field

---

## Migration Commands

```bash
# Run migrations
php artisan migrate

# Rollback migrations
php artisan migrate:rollback

# Fresh migrations (DANGER: drops all tables)
php artisan migrate:fresh
```

---

## Notes

- All dates are in `Y-m-d` format (e.g., "2026-06-16")
- Streak counts are based on consecutive days, not 24-hour periods
- The system uses the server's timezone for date calculations
- User streaks are initialized on first workout completion
- Calendar data is generated for the entire requested month
