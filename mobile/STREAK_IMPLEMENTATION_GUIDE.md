# Streak System Implementation Guide - Flutter Mobile App

## ✅ Completed Files

### 1. Models
**File:** `lib/models/streak_models.dart`
- ✅ StreakResult - For workout completion responses
- ✅ CalendarDay - For calendar day status
- ✅ StreakData - For full streak information

### 2. Services
**File:** `lib/services/streak_service.dart`
- ✅ completeWorkout(workoutId) - POST /api/workout/complete
- ✅ getStreakData({year, month}) - GET /api/streak
- ✅ Proper error handling and token management

### 3. Widgets
**File:** `lib/widgets/streak_celebration_overlay.dart`
- ✅ Full-screen celebration animation
- ✅ Animated fire emoji with pulse effect
- ✅ Number count-up animation
- ✅ Confetti particles
- ✅ Glowing purple ring animation
- ✅ Auto-dismiss after 4 seconds
- ✅ "Lanjutkan" button

### 4. Workout Integration
**File:** `lib/pages/workout/active_workout_page.dart`
- ✅ Added workoutId parameter
- ✅ Workout completion detection (last video finished)
- ✅ API call on workout completion
- ✅ Streak celebration trigger
- ✅ Navigation with completion status

### 5. Dependencies
**File:** `pubspec.yaml`
- ✅ Added `confetti: ^0.7.0`
- ✅ Installed successfully

---

## 🔨 TODO: Integration Steps

### Step 1: Update Beranda Page to Use Real Streak Data

**File to modify:** `lib/pages/beranda/beranda_page.dart`

Add at the top of the file:
```dart
import 'package:mobile/services/streak_service.dart';
import 'package:mobile/models/streak_models.dart';
```

Add state variables in `_BerandaPageState`:
```dart
StreakData? _streakData;
bool _isLoadingStreak = false;
final StreakService _streakService = StreakService();
```

Add method to fetch streak data:
```dart
Future<void> _fetchStreakData() async {
  if (!mounted) return;
  setState(() => _isLoadingStreak = true);
  
  try {
    final data = await _streakService.getStreakData();
    if (mounted) {
      setState(() {
        _streakData = data;
        _isLoadingStreak = false;
      });
    }
  } catch (e) {
    debugPrint('Error fetching streak data: $e');
    if (mounted) {
      setState(() => _isLoadingStreak = false);
    }
  }
}
```

Call in `initState`:
```dart
@override
void initState() {
  super.initState();
  _fetchStreakData();
  // ... rest of existing initState code
}
```

Update `_buildWeeklyActivityCard` to use real data:
```dart
Widget _buildWeeklyActivityCard(BuildContext context) {
  const dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  
  // Get streak data
  final currentStreak = _streakData?.streakActive ?? 0;
  final longestStreak = _streakData?.streakLongest ?? 0;
  
  // Get last 7 days from calendar
  final today = DateTime.now();
  final last7Days = List.generate(7, (i) {
    final date = today.subtract(Duration(days: 6 - i));
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    // Find this date in calendar
    final calendarDay = _streakData?.calendar.firstWhere(
      (day) => day.date == dateStr,
      orElse: () => CalendarDay(date: dateStr, status: 'future'),
    );
    
    return calendarDay?.status ?? 'future';
  });
  
  // ... rest of the widget code
  // Replace hardcoded dayStatuses with last7Days
}
```

### Step 2: Update Streak Detail Page to Use Real Data

**File to modify:** `lib/pages/beranda/streak_detail_page.dart`

Convert from StatelessWidget to StatefulWidget:
```dart
class StreakDetailPage extends StatefulWidget {
  const StreakDetailPage({
    super.key,
    this.initialStreak,
    this.initialLongest,
  });

  final int? initialStreak;
  final int? initialLongest;

  @override
  State<StreakDetailPage> createState() => _StreakDetailPageState();
}

class _StreakDetailPageState extends State<StreakDetailPage> {
  final StreakService _streakService = StreakService();
  StreakData? _streakData;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchStreakData();
  }
  
  Future<void> _fetchStreakData() async {
    try {
      final data = await _streakService.getStreakData();
      if (mounted) {
        setState(() {
          _streakData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  int get currentStreak => _streakData?.streakActive ?? widget.initialStreak ?? 0;
  int get longestStreak => _streakData?.streakLongest ?? widget.initialLongest ?? 0;
  int get _activeDaysThisMonth => _streakData?.hariAktifBulanIni ?? 0;
  int get _totalActivities => _streakData?.totalAktivitas ?? 0;
  
  // Update calendar building to use real data
  List<_StreakCalendarDay> get _calendarDays {
    if (_streakData == null) return _buildCalendarDays(_displayMonth);
    
    return _buildCalendarDaysFromAPI(_displayMonth, _streakData!);
  }
  
  static List<_StreakCalendarDay> _buildCalendarDaysFromAPI(
    DateTime month,
    StreakData data,
  ) {
    // Build calendar grid with real API data
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = first.weekday % 7;
    final days = <_StreakCalendarDay>[];

    // Leading blanks
    for (var i = leadingBlanks; i > 0; i--) {
      final date = first.subtract(Duration(days: i));
      days.add(_StreakCalendarDay(date: date, dayNumber: date.day));
    }

    // Days in month
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final calendarDay = data.calendar.firstWhere(
        (day) => day.date == dateStr,
        orElse: () => CalendarDay(date: dateStr, status: 'future'),
      );
      
      String? status;
      if (calendarDay.status == 'completed') {
        // Check if part of active streak (for purple color)
        final now = DateTime.now();
        final daysDiff = now.difference(date).inDays;
        if (daysDiff < data.streakActive) {
          status = 'streak'; // Purple - part of current streak
        } else {
          status = 'activity'; // Green - completed but not in streak
        }
      } else if (calendarDay.status == 'missed') {
        status = 'inactive'; // Grey
      } else if (calendarDay.status == 'today') {
        status = 'activity'; // Green if completed today
      }
      
      days.add(_StreakCalendarDay(
        date: date,
        dayNumber: d,
        status: status,
      ));
    }

    // Trailing blanks
    var trailing = 1;
    while (days.length % 7 != 0) {
      final date = DateTime(month.year, month.month + 1, trailing);
      days.add(_StreakCalendarDay(date: date, dayNumber: date.day));
      trailing++;
    }

    return days;
  }
}
```

### Step 3: Update Workout Screens to Pass Workout ID

**Files to modify:**
- Anywhere `ActiveWorkoutPage` is instantiated
- Ensure `workoutId` parameter is passed

Example:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ActiveWorkoutPage(
      playlist: workoutVideos,
      exerciseDetails: exercises,
      workoutId: program.id, // Add this
    ),
  ),
).then((completed) {
  if (completed == true) {
    // Refresh beranda data
    _fetchStreakData();
  }
});
```

### Step 4: Update Beranda Navigation to Handle Completion

**File:** `lib/pages/beranda/beranda_page.dart`

When navigating to workout:
```dart
// In _goToWorkout method or wherever workout is started
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => WorkoutScreen()),
);

// If workout was completed, refresh streak data
if (result == true) {
  _fetchStreakData();
}
```

---

## 🎨 Animation Sequence Details

The `StreakCelebrationOverlay` implements:

1. **Background fade-in** (0-300ms)
   - Dark semi-transparent overlay

2. **Card scale-up with bounce** (200-600ms)
   - Elastic curve for bounce effect

3. **Fire icon pulse** (600ms-ongoing)
   - Continuous scale animation 0.8-1.2

4. **Number count-up** (600-1200ms)
   - Animates from 0 to current streak

5. **Confetti burst** (700ms)
   - Particles fall from top
   - 5 colors: purple, pink, yellow, green

6. **Button fade-in** (1200-1500ms)
   - "Lanjutkan" button appears

7. **Auto-dismiss** (4000ms)
   - Automatically closes after 4 seconds
   - Or when user taps button

---

## 📱 Testing Checklist

### Test Workout Completion:
1. ✅ Start a workout with multiple videos
2. ✅ Complete all videos
3. ✅ Verify API call is made
4. ✅ If first workout of day → celebration shows
5. ✅ If already completed today → no celebration
6. ✅ Navigate back to Beranda
7. ✅ Verify streak counter updated

### Test Streak Display:
1. ✅ Open Beranda
2. ✅ Check "Aktivitas 7 Hari Terakhir" card shows correct data
3. ✅ Today should show checkmark if workout completed
4. ✅ Past days show checkmarks based on API data

### Test Streak Detail Page:
1. ✅ Tap "Lihat Detail" on streak card
2. ✅ Verify all numbers are from API:
   - Streak Aktif
   - Streak Terpanjang
   - Hari Aktif Bulan Ini
   - Total Aktivitas
3. ✅ Calendar colors correct:
   - Purple = part of current active streak
   - Green = completed but streak broken
   - Grey = missed day

### Test Error Handling:
1. ✅ Complete workout with no internet
2. ✅ Verify error message shown
3. ✅ Workout still marked as completed locally
4. ✅ Retry logic works

---

## 🔧 Configuration

### API Base URL
Ensure `lib/config/api_config.dart` has correct backend URL:
```dart
static String get apiBaseUrl => 'http://YOUR_IP:8000/api';
```

### Authentication
The StreakService automatically uses the token from AuthService:
```dart
final token = await AuthService.instance.token;
```

---

## 🐛 Troubleshooting

### Celebration Not Showing
- Check API response: `is_new_streak_day` should be `true`
- Verify token is valid
- Check console for error messages

### Streak Not Updating
- Verify backend migrations ran successfully
- Check Laravel logs: `storage/logs/laravel.log`
- Test API endpoint directly with Postman

### Calendar Not Showing Data
- Verify `calendar` array in API response
- Check date format: "YYYY-MM-DD"
- Ensure month/year parameters are correct

---

## 📚 API Endpoints Used

### Complete Workout
```
POST /api/workout/complete
Headers: Authorization: Bearer {token}
Body: { "workout_id": 1 }
Response: {
  "success": true,
  "data": {
    "streak_active": 5,
    "streak_longest": 10,
    "is_new_streak_day": true,
    "message": "Streak berhasil diperbarui!"
  }
}
```

### Get Streak Data
```
GET /api/streak?year=2026&month=6
Headers: Authorization: Bearer {token}
Response: {
  "success": true,
  "data": {
    "streak_active": 5,
    "streak_longest": 10,
    "total_aktivitas": 20,
    "hari_aktif_bulan_ini": 12,
    "calendar": [
      { "date": "2026-06-01", "status": "completed" },
      { "date": "2026-06-02", "status": "missed" },
      ...
    ]
  }
}
```

---

## ✨ Next Steps

1. Test workout completion flow end-to-end
2. Implement Beranda refresh after workout
3. Add loading states for streak data
4. Test with various streak scenarios:
   - First workout ever
   - Continuing streak
   - Breaking streak
   - Multiple workouts in one day
5. Polish animations and transitions
6. Add error retry mechanisms
7. Implement offline support (optional)

---

**Created:** June 16, 2026  
**Version:** 1.0.0  
**Status:** Core Implementation Complete, Integration Pending
