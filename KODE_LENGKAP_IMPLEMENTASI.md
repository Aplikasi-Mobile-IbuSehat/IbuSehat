# Kode Lengkap Implementasi Weekly Sleep Tracking

## 📦 1. FILE BARU: SleepProvider

**Path**: `mobile/lib/providers/sleep_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:mobile/models/sleep_weekly_summary_model.dart';
import 'package:mobile/services/sleep_service.dart';

/// Provider untuk mengelola state data tidur mingguan
/// Digunakan untuk sinkronisasi data antara halaman input dan Beranda
class SleepProvider with ChangeNotifier {
  final SleepService _sleepService;
  
  SleepProvider({SleepService? sleepService})
      : _sleepService = sleepService ?? SleepService();

  SleepWeeklySummaryModel? _weeklySummary;
  bool _isLoading = false;
  String? _errorMessage;

  SleepWeeklySummaryModel? get weeklySummary => _weeklySummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _weeklySummary?.hasData ?? false;

  /// Mengambil data ringkasan tidur mingguan dari API
  Future<void> fetchWeeklySummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('=== SleepProvider: fetching weekly summary...');
      final summary = await _sleepService.fetchWeeklySummary();
      _weeklySummary = summary;
      _errorMessage = null;
      debugPrint('=== SleepProvider: fetched successfully, hasData=${summary.hasData}');
      debugPrint('=== SleepProvider: averageDuration=${summary.averageDuration}');
    } on SleepServiceException catch (e) {
      _errorMessage = e.message;
      debugPrint('=== SleepProvider: SleepServiceException: ${e.message}');
    } catch (e, st) {
      _errorMessage = 'Gagal memuat data tidur';
      debugPrint('=== SleepProvider: Error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset data (untuk logout atau clear cache)
  void clear() {
    _weeklySummary = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Konversi durasi string (format "Xj Ym") ke total jam desimal
  /// Contoh: "7j 30m" -> 7.5 jam
  double getTotalHoursFromDuration(String? duration) {
    if (duration == null || duration.isEmpty || duration == '-') return 0.0;
    
    try {
      // Parse format "7j 30m"
      final parts = duration.split(' ');
      if (parts.length != 2) return 0.0;
      
      final hours = int.tryParse(parts[0].replaceAll('j', '')) ?? 0;
      final minutes = int.tryParse(parts[1].replaceAll('m', '')) ?? 0;
      
      return hours + (minutes / 60.0);
    } catch (e) {
      debugPrint('=== SleepProvider: Error parsing duration "$duration": $e');
      return 0.0;
    }
  }

  /// Mendapatkan total jam tidur mingguan
  double get weeklyTotalHours {
    if (!hasData) return 0.0;
    
    // Hitung total dari semua hari yang ada data di chart
    final chart = _weeklySummary?.chart ?? [];
    final avgDurationStr = _weeklySummary?.averageDuration;
    
    if (avgDurationStr == null || avgDurationStr.isEmpty || avgDurationStr == '-') {
      return 0.0;
    }
    
    // Hitung berapa hari yang ada data (score tidak null)
    final daysWithData = chart.where((d) => d.score != null).length;
    
    if (daysWithData == 0) return 0.0;
    
    // Average duration adalah rata-rata per hari
    // Total jam = average per hari × jumlah hari yang ada data
    final avgHoursPerDay = getTotalHoursFromDuration(avgDurationStr);
    final totalHours = avgHoursPerDay * daysWithData;
    
    debugPrint('=== SleepProvider: avgDuration=$avgDurationStr, daysWithData=$daysWithData, totalHours=$totalHours');
    
    return totalHours;
  }

  /// Mendapatkan persentase progress terhadap target 49 jam per minggu
  int get weeklyProgressPercent {
    const targetHours = 49.0;
    final total = weeklyTotalHours;
    
    if (total <= 0) return 0;
    
    final percent = (total / targetHours * 100).round();
    return percent.clamp(0, 100);
  }
}
```

---

## 🔧 2. UPDATE: CatatTidurPage

**Path**: `mobile/lib/pages/catat_tidur_page.dart`

### Tambahkan Import (di bagian atas file):
```dart
import 'package:mobile/providers/sleep_provider.dart';
import 'package:provider/provider.dart';
```

### Update Method `_hitungSkor()`:
```dart
Future<void> _hitungSkor() async {
  setState(() => _isLoading = true);
  try {
    final result = await _sleepService.submitSleepLog(
      SleepLogRequest(
        sleepTime: _formatTime(_jamTidur),
        wakeTime: _formatTime(_jamBangun),
        nightWakings: _terbangun,
        awakeDuration: _lamaTerjaga,
        mood: _mood,
      ),
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _hasSubmitted = true;
    });

    // 🔥 REFRESH DATA TIDUR MINGGUAN SETELAH SUBMIT BERHASIL
    debugPrint('=== CatatTidurPage: Submit berhasil, refreshing weekly data...');
    try {
      final sleepProvider = context.read<SleepProvider>();
      await sleepProvider.fetchWeeklySummary();
      debugPrint('=== CatatTidurPage: Weekly data refreshed successfully');
    } catch (e) {
      debugPrint('=== CatatTidurPage: Failed to refresh weekly data: $e');
      // Tidak perlu menampilkan error, data akan direfresh saat kembali ke Beranda
    }

    try {
      await showHasilSkorTidurDialog(
        context,
        result.toDataMap(),
        showLihatRiwayatButton: true,
      );
    } catch (e, st) {
      debugPrint('CatatTidurPage showHasilSkor: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data tersimpan (skor ${result.score}), tetapi gagal '
            'menampilkan hasil.',
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } on SleepServiceException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e, st) {
    debugPrint('CatatTidurPage._hitungSkor: $e\n$st');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Gagal menghitung skor. Periksa koneksi ke server lalu coba lagi.',
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

## 🏠 3. UPDATE: BerandaPage

**Path**: `mobile/lib/pages/beranda/beranda_page.dart`

### Tambahkan Import (di bagian atas file):
```dart
import 'package:mobile/providers/sleep_provider.dart';
import 'package:provider/provider.dart';
```

### Update initState():
```dart
@override
void initState() {
  super.initState();
  _scrollController = widget.scrollController ?? ScrollController();
  WidgetsBinding.instance.addObserver(this);
  
  _fetchStreakData();
  _fetchSleepData();  // 🔥 TAMBAHKAN INI

  if (!_hasShownWelcomeDialog) {
    _hasShownWelcomeDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WelcomeDialog(),
      );
    });
  }
}
```

### Update didChangeAppLifecycleState():
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  super.didChangeAppLifecycleState(state);
  if (state == AppLifecycleState.resumed) {
    print('=== BERANDA: page focused, refreshing...');
    _fetchStreakData();
    _fetchSleepData();  // 🔥 TAMBAHKAN INI
  }
}
```

### Tambahkan Method Baru:
```dart
Future<void> _fetchSleepData() async {
  print('=== BERANDA: fetching sleep data...');
  try {
    final sleepProvider = context.read<SleepProvider>();
    await sleepProvider.fetchWeeklySummary();
    print('=== BERANDA: sleep data fetched');
  } catch (e) {
    debugPrint('Error fetching sleep data: $e');
  }
}
```

### Update _buildProgressTodaySection():
```dart
Widget _buildProgressTodaySection(BuildContext context) {
  // 🔥 GET SLEEP DATA FROM PROVIDER
  final sleepProvider = context.watch<SleepProvider>();
  final sleepTotalHours = sleepProvider.weeklyTotalHours;
  final sleepPercent = sleepProvider.weeklyProgressPercent;
  final sleepProgress = sleepPercent / 100.0;
  
  // Variables for backend integration - reset all to 0
  int olahragaMenit = 0;
  int airPutihGelas = 0;
  int nutrisiKkal = 0;
  
  final items = <Widget>[
    _buildProgressCard(
      title: 'Olahraga',
      value: '$olahragaMenit menit',
      target: 'Target mingguan 75 menit',
      percent: 0,
      progress: 0.0,
      icon: Icons.directions_run_rounded,
      iconColor: _kPrimary,
      iconBg: _kVeryLightPurple,
      barColor: _kPrimary,
    ),
    _buildProgressCard(
      title: 'Air Putih',
      value: '$airPutihGelas ML',
      target: 'Target mingguan 15 liter',
      percent: 0,
      progress: 0.0,
      icon: Icons.water_drop_rounded,
      iconColor: _kBlue,
      iconBg: const Color(0xFFDBEAFE),
      barColor: _kBlue,
    ),
    _buildProgressCard(
      title: 'Nutrisi',
      value: '$nutrisiKkal kkal',
      target: 'Target Mingguan 15.400 kkal',
      percent: 0,
      progress: 0.0,
      icon: Icons.restaurant_rounded,
      iconColor: _kSuccess,
      iconBg: const Color(0xFFDCFCE7),
      barColor: _kSuccess,
    ),
    // 🔥 UPDATE CARD JAM TIDUR
    _buildProgressCard(
      title: 'Jam Tidur',
      value: '${sleepTotalHours.toStringAsFixed(1)} jam',
      target: 'Target Mingguan 49 jam',
      percent: sleepPercent,
      progress: sleepProgress,
      icon: Icons.bedtime,
      iconColor: _kPink,
      iconBg: const Color(0xFFFCE7F3),
      barColor: _kPink,
    ),
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Progress Minggu Ini',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => _goToTab(1),
            child: const Text(
              'Lihat detail >',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 12,
        childAspectRatio: 1.65,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: items,
      ),
    ],
  );
}
```

---

## ✅ 4. BACKEND - SUDAH ADA (Tidak Perlu Diubah)

### Route API (Sudah Terdaftar):
**File**: `backend/routes/api.php`
```php
Route::get('/sleep/log/weekly-summary', [SleepLogController::class, 'weeklySummary']);
Route::post('/sleep/log', [SleepLogController::class, 'store']);
```

### Controller (Sudah Implementasi):
**File**: `backend/app/Http/Controllers/SleepLogController.php`
- ✅ Method `store()` - Menyimpan data tidur
- ✅ Method `weeklySummary()` - Menghitung total jam tidur mingguan

### Database Table (Sudah Ada):
**Table**: `sleep_logs`
```sql
- id
- user_id
- sleep_time
- wake_time
- night_wakings
- awake_duration
- mood
- notes
- score
- category
- sleep_duration_minutes  -- 🔥 Ini yang digunakan untuk hitung total
- is_saved
- created_at
- updated_at
```

---

## 🚀 5. CARA MENGGUNAKAN

### Step 1: Pastikan Provider Terdaftar (Sudah Ada)
File `mobile/lib/main.dart` sudah memiliki:
```dart
runApp(
  ChangeNotifierProvider(
    create: (_) => SleepProvider(),
    child: const MyApp(),
  ),
);
```

### Step 2: Test Flow
1. Buka aplikasi → Beranda
2. Tap FAB "Catat Tidur"
3. Input data:
   - Jam Tidur: 22:30
   - Jam Bangun: 06:00
   - Terbangun: 1 kali
   - Lama Terjaga: 10 menit
   - Mood: Baik
4. Tap "Hitung Skor Tidur"
5. Lihat hasil skor
6. Tutup dialog
7. **Kembali ke Beranda** → Card "Jam Tidur" akan terupdate otomatis! ✅

### Step 3: Verifikasi
**Expected Output**:
```
Card Jam Tidur:
- Value: "7.5 jam" (atau sesuai durasi input)
- Progress bar: Terisi sesuai persentase
- Percent: "15%" (jika 7.5 jam dari target 49 jam)
```

---

## 🔍 6. DEBUG CHECKLIST

Jika card masih menampilkan 0:

### ✅ Cek 1: Provider Logs
```dart
// Di console/logcat, cari:
=== SleepProvider: fetching weekly summary...
=== SleepProvider: fetched successfully, hasData=true
=== SleepProvider: avgDuration=7j 30m, daysWithData=1, totalHours=7.5
```

### ✅ Cek 2: Beranda Logs
```dart
// Di console/logcat, cari:
=== BERANDA: fetching sleep data...
=== BERANDA: sleep data fetched
```

### ✅ Cek 3: API Response
Test endpoint menggunakan Postman/curl:
```bash
GET http://YOUR_IP:8000/api/sleep/log/weekly-summary
Header: Authorization: Bearer YOUR_TOKEN
```

Expected response:
```json
{
  "status": "success",
  "data": {
    "has_data": true,
    "average_duration": "7j 30m",
    "chart": [
      {"day": "Sen", "score": 85},
      ...
    ]
  }
}
```

### ✅ Cek 4: Widget Rebuild
Pastikan `context.watch<SleepProvider>()` digunakan di dalam `build()` method, bukan di `initState()`.

---

## 📝 7. SUMMARY

**File yang Dibuat**:
1. ✅ `mobile/lib/providers/sleep_provider.dart`

**File yang Dimodifikasi**:
1. ✅ `mobile/lib/pages/catat_tidur_page.dart` (2 perubahan)
2. ✅ `mobile/lib/pages/beranda/beranda_page.dart` (4 perubahan)

**Backend**:
- ✅ Tidak perlu perubahan (sudah implementasi lengkap)

**Dependencies**:
- ✅ `provider: ^6.1.2` (sudah ada di pubspec.yaml)

**Result**:
- ✅ Card Jam Tidur menampilkan total jam tidur mingguan
- ✅ Progress bar menunjukkan % terhadap target 49 jam
- ✅ Auto-refresh setelah input baru tanpa restart
- ✅ Integrasi penuh dengan backend API

---

## 🎉 DONE!

Implementasi selesai dan siap digunakan. Card "Jam Tidur" akan otomatis terupdate setelah user menginput data tidur baru.
