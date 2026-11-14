# Implementasi Weekly Sleep Tracking - Card Jam Tidur Beranda

## 📋 Ringkasan
Implementasi fitur pelacakan jam tidur mingguan yang menampilkan total jam tidur dan progress pada card "Jam Tidur" di halaman Beranda.

## ✅ Fitur yang Diimplementasikan

### 1. **State Management dengan Provider**
- **File Baru**: `lib/providers/sleep_provider.dart`
- **Fungsi**:
  - Menyimpan dan mengelola state data tidur mingguan
  - Mengambil data dari API `fetchWeeklySummary()`
  - Menghitung total jam tidur mingguan
  - Menghitung persentase progress terhadap target 49 jam/minggu
  - Notifikasi listener saat data berubah (`notifyListeners()`)

### 2. **Auto-refresh Data**
- Setelah user menghitung skor tidur di `CatatTidurPage`:
  - Data otomatis di-refresh melalui `SleepProvider`
  - Card Jam Tidur di Beranda langsung terupdate tanpa restart
  
- Refresh otomatis saat:
  - Aplikasi dibuka kembali (`didChangeAppLifecycleState`)
  - User kembali ke halaman Beranda
  - User berhasil menghitung skor tidur baru

### 3. **Integrasi Backend**
- **Endpoint yang Digunakan**: `GET /api/sleep/log/weekly-summary`
- **Data yang Diterima**:
  ```json
  {
    "status": "success",
    "data": {
      "has_data": true,
      "average_score": 85,
      "average_duration": "7j 30m",
      "chart": [
        {"day": "Sen", "score": 80},
        {"day": "Sel", "score": 90},
        ...
      ]
    }
  }
  ```

### 4. **Perhitungan Total Jam Tidur**
```dart
// Formula:
totalJamTidur = averageDurationPerHari × jumlahHariAdaData

// Contoh:
// Average duration: 7j 30m = 7.5 jam/hari
// Hari dengan data: 5 hari
// Total = 7.5 × 5 = 37.5 jam

// Progress:
progressPercent = (totalJamTidur / 49) × 100
```

## 📁 File yang Dimodifikasi

### 1. **File Baru**
- ✅ `mobile/lib/providers/sleep_provider.dart` - Provider untuk state management

### 2. **File yang Diupdate**

#### `mobile/lib/pages/catat_tidur_page.dart`
```dart
// Tambahan import
import 'package:mobile/providers/sleep_provider.dart';
import 'package:provider/provider.dart';

// Di method _hitungSkor(), setelah submit berhasil:
final sleepProvider = context.read<SleepProvider>();
await sleepProvider.fetchWeeklySummary();
```

#### `mobile/lib/pages/beranda/beranda_page.dart`
```dart
// Tambahan import
import 'package:mobile/providers/sleep_provider.dart';
import 'package:provider/provider.dart';

// Di initState():
_fetchSleepData();

// Di didChangeAppLifecycleState():
_fetchSleepData();

// Method baru:
Future<void> _fetchSleepData() async {
  final sleepProvider = context.read<SleepProvider>();
  await sleepProvider.fetchWeeklySummary();
}

// Di _buildProgressTodaySection():
final sleepProvider = context.watch<SleepProvider>();
final sleepTotalHours = sleepProvider.weeklyTotalHours;
final sleepPercent = sleepProvider.weeklyProgressPercent;

_buildProgressCard(
  title: 'Jam Tidur',
  value: '${sleepTotalHours.toStringAsFixed(1)} jam',
  target: 'Target Mingguan 49 jam',
  percent: sleepPercent,
  progress: sleepPercent / 100.0,
  ...
)
```

#### `mobile/lib/main.dart`
```dart
// Sudah ada: Provider terdaftar di main()
runApp(
  ChangeNotifierProvider(
    create: (_) => SleepProvider(),
    child: const MyApp(),
  ),
);
```

## 🔄 Flow Data

```
┌─────────────────┐
│ User Input Tidur│
│ (CatatTidurPage)│
└────────┬────────┘
         │
         │ 1. submitSleepLog()
         ▼
┌─────────────────┐
│ Laravel Backend │
│ SleepLogController
└────────┬────────┘
         │
         │ 2. Store ke DB
         │    (sleep_logs table)
         ▼
┌─────────────────┐
│ Submit Success  │
└────────┬────────┘
         │
         │ 3. Refresh data
         ▼
┌─────────────────┐
│  SleepProvider  │
│ fetchWeeklySummary()
└────────┬────────┘
         │
         │ 4. notifyListeners()
         ▼
┌─────────────────┐
│  BerandaPage    │
│ (context.watch) │
└────────┬────────┘
         │
         │ 5. Rebuild UI
         ▼
┌─────────────────┐
│ Card Jam Tidur  │
│ Updated! ✅      │
└─────────────────┘
```

## 🧪 Testing

### Manual Testing:
1. **Buka aplikasi** → Card Jam Tidur menampilkan 0 jam
2. **Klik FAB "Catat Tidur"** 
3. **Input data**:
   - Jam Tidur: 22:30
   - Jam Bangun: 06:00
   - Terbangun: 1 kali
   - Lama Terjaga: 10 menit
   - Mood: Baik
4. **Klik "Hitung Skor Tidur"**
5. **Tutup dialog hasil**
6. **Kembali ke Beranda** → Card Jam Tidur otomatis terupdate!

### Expected Results:
```
Input: Tidur 22:30, Bangun 06:00
Durasi: ~7.5 jam
Card shows: "7.5 jam"
Progress: 7.5/49 × 100 = 15%
Progress bar: 15% filled
```

## 📊 Data Model

### SleepWeeklySummaryModel
```dart
class SleepWeeklySummaryModel {
  final bool hasData;
  final int? averageScore;
  final String? averageCategory;
  final String? averageDuration;      // "7j 30m"
  final String totalDebt;
  final String qualityLabel;
  final String qualityColor;
  final List<SleepChartDay> chart;    // 7 days
}

class SleepChartDay {
  final String day;    // "Sen", "Sel", etc
  final int? score;    // null jika belum ada data
}
```

## 🐛 Troubleshooting

### Card masih menampilkan 0 jam?

**Cek 1: Provider terdaftar?**
```dart
// Di main.dart harus ada:
runApp(
  ChangeNotifierProvider(
    create: (_) => SleepProvider(),
    child: const MyApp(),
  ),
);
```

**Cek 2: API endpoint berjalan?**
```bash
# Test endpoint:
curl -X GET "http://YOUR_IP:8000/api/sleep/log/weekly-summary" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Cek 3: Debug logs**
```dart
// Di SleepProvider, cek log:
=== SleepProvider: fetching weekly summary...
=== SleepProvider: fetched successfully, hasData=true
=== SleepProvider: avgDuration=7j 30m, daysWithData=1, totalHours=7.5

// Di BerandaPage, cek log:
=== BERANDA: fetching sleep data...
=== BERANDA: sleep data fetched
```

**Cek 4: Context.watch() vs context.read()**
```dart
// Di build() method, gunakan watch:
final sleepProvider = context.watch<SleepProvider>();

// Di initState atau async method, gunakan read:
final sleepProvider = context.read<SleepProvider>();
```

## 🚀 Next Steps (Optional Enhancements)

1. **Loading State**
   - Tambahkan shimmer loading saat fetch data
   
2. **Error Handling**
   - Tampilkan pesan error jika API gagal
   
3. **Pull to Refresh**
   - Tambahkan gesture pull down untuk manual refresh
   
4. **Caching**
   - Simpan data terakhir di SharedPreferences
   
5. **Animasi**
   - Animasi saat progress bar berubah

## 📝 Backend API Reference

### Endpoint: `/api/sleep/log/weekly-summary`
- **Method**: GET
- **Auth**: Required (Bearer Token)
- **Response Success**:
```json
{
  "status": "success",
  "data": {
    "has_data": true,
    "average_score": 85,
    "average_category": "Good Sleep",
    "average_category_message": "Kualitas tidurmu tergolong baik 🎉",
    "average_duration": "7j 30m",
    "average_sleep_time": "22:30",
    "average_wake_time": "06:00",
    "total_debt": "2j 30m",
    "quality_label": "Baik",
    "quality_color": "green",
    "chart": [
      {"day": "Sen", "score": 80},
      {"day": "Sel", "score": 85},
      {"day": "Rab", "score": null},
      {"day": "Kam", "score": 90},
      {"day": "Jum", "score": 88},
      {"day": "Sab", "score": null},
      {"day": "Min", "score": null}
    ]
  }
}
```

### Endpoint: `/api/sleep/log`
- **Method**: POST
- **Auth**: Required (Bearer Token)
- **Body**:
```json
{
  "sleep_time": "22:30",
  "wake_time": "06:00",
  "night_wakings": 1,
  "awake_duration": 10,
  "mood": "baik"
}
```

## ✨ Kesimpulan

Implementasi ini memastikan:
- ✅ Data tidur tersimpan ke backend
- ✅ Card Jam Tidur menampilkan total jam mingguan
- ✅ Progress bar menunjukkan % terhadap target 49 jam
- ✅ Auto-refresh tanpa restart aplikasi
- ✅ State management dengan Provider
- ✅ Integrasi penuh backend ↔ frontend

**Status**: READY FOR PRODUCTION 🚀
