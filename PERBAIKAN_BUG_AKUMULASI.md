# Perbaikan Bug: Total Jam Tidur Tidak Terakumulasi

## 🐛 Masalah yang Ditemukan

### Gejala:
- Tidur pertama = 7 jam ✅
- Tidur kedua = 6 jam ✅
- Card menampilkan: **6 jam** ❌ (seharusnya 13 jam)

### Root Cause:

#### 1. **Backend - SleepLogController::weeklySummary()** ❌
**File**: `backend/app/Http/Controllers/SleepLogController.php`
**Line**: 233-251

**Masalah**:
```php
// ❌ HANYA MENGAMBIL LOG PERTAMA PER HARI
for ($i = 0; $i < 7; $i++) {
    $day = $start->copy()->addDays($i);
    $log = $logs->first(
        fn (SleepLog $l) => $l->created_at->isSameDay($day),
    );
    // Jika ada 2 catatan di hari yang sama, hanya log pertama yang diambil
}
```

**Dampak**: Jika user mencatat tidur 2x di hari yang sama, hanya catatan pertama yang dihitung.

#### 2. **Flutter - SleepProvider::weeklyTotalHours** ❌
**File**: `mobile/lib/providers/sleep_provider.dart`
**Line**: 72-90

**Masalah**:
```dart
// ❌ MENGHITUNG BERDASARKAN AVERAGE × JUMLAH HARI
final avgHoursPerDay = getTotalHoursFromDuration(avgDurationStr);
final totalHours = avgHoursPerDay * daysWithData;
// Ini SALAH karena average sudah dibagi, lalu dikali lagi
```

**Dampak**: Perhitungan tidak akurat, tidak menggunakan SUM langsung dari backend.

---

## ✅ Solusi yang Diimplementasikan

### FIX 1: Backend - Update weeklySummary() untuk SUM semua records

**File**: `backend/app/Http/Controllers/SleepLogController.php`
**Method**: `weeklySummary()`

**Perubahan**:

```php
// ✅ SEBELUM (SALAH):
for ($i = 0; $i < 7; $i++) {
    $day = $start->copy()->addDays($i);
    $log = $logs->first(
        fn (SleepLog $l) => $l->created_at->isSameDay($day),
    );
    // Hanya ambil pertama
}

// ✅ SESUDAH (BENAR):
for ($i = 0; $i < 7; $i++) {
    $day = $start->copy()->addDays($i);
    
    // AMBIL SEMUA LOGS DI HARI INI
    $dayLogs = $logs->filter(
        fn (SleepLog $l) => $l->created_at->isSameDay($day),
    );

    if ($dayLogs->isNotEmpty()) {
        // SUM durasi semua catatan di hari ini
        $dayTotalMinutes = (int) $dayLogs->sum('sleep_duration_minutes');
        $dayAvgScore = (int) round($dayLogs->avg('score'));
        
        $chart[] = [
            'day' => $this->dayLabelShort($day),
            'score' => $dayAvgScore,
            'duration_minutes' => $dayTotalMinutes, // ✅ TOTAL PER HARI
        ];
    }
}

// ✅ TAMBAHKAN FIELD BARU DI RESPONSE
return response()->json([
    'status' => 'success',
    'data' => [
        'has_data' => true,
        'total_duration' => $this->formatDurationCompact($totalMinutes),
        'total_hours' => round($totalMinutes / 60, 1), // ✅ TOTAL JAM
        'chart' => $chart,
    ],
]);
```

**Hasil**: 
- Backend sekarang SUM semua catatan di minggu yang sama
- Response API mengirim `total_hours` yang sudah dihitung dengan benar

---

### FIX 2: Flutter Model - Tambahkan totalHours field

**File**: `mobile/lib/models/sleep_weekly_summary_model.dart`

**Perubahan**:

```dart
// ✅ TAMBAH FIELD BARU
class SleepWeeklySummaryModel {
  const SleepWeeklySummaryModel({
    required this.hasData,
    this.totalDuration,     // ✅ BARU: "13j 30m"
    this.totalHours,        // ✅ BARU: 13.5
    // ... field lainnya
  });

  final String? totalDuration;
  final double? totalHours;  // ✅ GUNAKAN INI

  factory SleepWeeklySummaryModel.fromJson(Map<String, dynamic> json) {
    return SleepWeeklySummaryModel(
      totalDuration: root['total_duration'] as String?,
      totalHours: (root['total_hours'] as num?)?.toDouble(), // ✅ PARSE
    );
  }
}

// ✅ TAMBAH FIELD DI CHART
class SleepChartDay {
  const SleepChartDay({
    required this.day,
    this.score,
    this.durationMinutes = 0, // ✅ BARU: total menit per hari
  });
  
  final int durationMinutes;
}
```

---

### FIX 3: Flutter Provider - Gunakan total_hours langsung

**File**: `mobile/lib/providers/sleep_provider.dart`
**Method**: `weeklyTotalHours`

**Perubahan**:

```dart
// ✅ SEBELUM (SALAH):
double get weeklyTotalHours {
  final avgHoursPerDay = getTotalHoursFromDuration(avgDurationStr);
  final totalHours = avgHoursPerDay * daysWithData; // ❌ SALAH
  return totalHours;
}

// ✅ SESUDAH (BENAR):
double get weeklyTotalHours {
  if (!hasData) return 0.0;
  
  // GUNAKAN TOTAL_HOURS DARI BACKEND (SUDAH SUM SEMUA)
  final totalHours = _weeklySummary?.totalHours;
  
  if (totalHours != null && totalHours > 0) {
    return totalHours; // ✅ LANGSUNG DARI BACKEND
  }
  
  // Fallback: hitung dari chart
  final chart = _weeklySummary?.chart ?? [];
  double totalFromChart = 0.0;
  
  for (final day in chart) {
    totalFromChart += day.durationMinutes / 60.0; // ✅ SUM SEMUA
  }
  
  return totalFromChart;
}
```

---

## 📊 Contoh Response API Setelah Perbaikan

### Request:
```
GET /api/sleep/log/weekly-summary
Authorization: Bearer TOKEN
```

### Response:
```json
{
  "status": "success",
  "data": {
    "has_data": true,
    "average_score": 85,
    "average_duration": "6j 30m",
    "total_duration": "13j 0m",      // ✅ BARU
    "total_hours": 13.0,             // ✅ BARU
    "chart": [
      {
        "day": "Sen",
        "score": 90,
        "duration_minutes": 420    // ✅ BARU: 7 jam × 60
      },
      {
        "day": "Sel",
        "score": 80,
        "duration_minutes": 360    // ✅ BARU: 6 jam × 60
      },
      {
        "day": "Rab",
        "score": null,
        "duration_minutes": 0
      }
    ]
  }
}
```

### Perhitungan:
```
Senin: 7 jam (420 menit)
Selasa: 6 jam (360 menit)
---------------
Total: 13 jam (780 menit) ✅
```

---

## 🧪 Testing Scenario

### Skenario 1: User mencatat tidur 1x per hari
```
Hari 1: 7 jam
Hari 2: 6 jam
-----------
Total: 13 jam ✅
```

### Skenario 2: User mencatat tidur 2x di hari yang sama
```
Hari 1 - Catatan 1: 3 jam (tidur siang)
Hari 1 - Catatan 2: 7 jam (tidur malam)
Hari 2: 6 jam
-----------
Total: 16 jam ✅ (3 + 7 + 6)
```

### Skenario 3: User mencatat tidur beberapa hari
```
Senin: 7 jam
Rabu: 8 jam
Jumat: 6 jam
Sabtu: 7 jam
-----------
Total: 28 jam ✅
Progress: 28/49 × 100 = 57% ✅
```

---

## 📁 File yang Dimodifikasi

### Backend:
1. ✅ `backend/app/Http/Controllers/SleepLogController.php`
   - Method: `weeklySummary()`
   - Line: 197-276
   - Perubahan: Filter logs per hari, SUM durasi, tambah `total_hours` di response

### Flutter:
1. ✅ `mobile/lib/models/sleep_weekly_summary_model.dart`
   - Tambah field: `totalDuration`, `totalHours`, `durationMinutes`
   - Update: `fromJson()` parser

2. ✅ `mobile/lib/providers/sleep_provider.dart`
   - Method: `weeklyTotalHours`
   - Perubahan: Gunakan `totalHours` langsung dari backend

### Tidak Perlu Diubah:
- ✅ `backend/app/Http/Controllers/SleepLogController.php::store()` - Sudah pakai `create()`
- ✅ `mobile/lib/pages/catat_tidur_page.dart` - Sudah refresh provider
- ✅ `mobile/lib/pages/beranda/beranda_page.dart` - Sudah watch provider

---

## ✅ Checklist Verifikasi

### Backend:
- [x] `SleepLog::create()` digunakan (bukan `updateOrCreate`)
- [x] `weeklySummary()` mengambil SEMUA logs di minggu yang sama
- [x] Loop chart memproses SEMUA logs per hari (bukan hanya pertama)
- [x] Response mengirim `total_hours` yang sudah SUM
- [x] Endpoint `POST /api/sleep/log` membuat record baru setiap kali

### Flutter:
- [x] Model menerima `total_hours` dari backend
- [x] Provider menggunakan `total_hours` langsung
- [x] Provider di-refresh setelah POST berhasil
- [x] Beranda menggunakan `context.watch()` untuk reactive update
- [x] Card Jam Tidur menampilkan `weeklyTotalHours`

---

## 🎯 Hasil Akhir

### Sebelum Perbaikan:
```
Catatan 1: 7 jam
Catatan 2: 6 jam
Card shows: 6 jam ❌
```

### Setelah Perbaikan:
```
Catatan 1: 7 jam
Catatan 2: 6 jam
Card shows: 13 jam ✅
Progress: 27% ✅
```

---

## 🚀 Cara Test

1. **Bersihkan data lama**:
   ```sql
   DELETE FROM sleep_logs WHERE user_id = YOUR_USER_ID;
   ```

2. **Catat tidur pertama**:
   - Input: Tidur 22:00, Bangun 05:00 (7 jam)
   - Cek card: Harus tampil **7.0 jam**

3. **Catat tidur kedua**:
   - Input: Tidur 22:30, Bangun 04:30 (6 jam)
   - Cek card: Harus tampil **13.0 jam** ✅

4. **Catat tidur ketiga di hari yang sama** (optional):
   - Input: Tidur 14:00, Bangun 16:00 (2 jam tidur siang)
   - Cek card: Harus tampil **15.0 jam** ✅ (7 + 6 + 2)

---

## 📌 Catatan Penting

1. **Setiap catatan tidur disimpan sebagai record baru** - Tidak ada update/replace
2. **Backend menghitung SUM semua records di minggu yang sama** - Bukan average × jumlah hari
3. **Flutter langsung menggunakan `total_hours` dari backend** - Tidak perlu kalkulasi ulang
4. **Provider otomatis refresh setelah POST** - Data selalu up-to-date
5. **Chart per hari juga SUM jika ada multiple catatan** - Akurat per hari

---

## ✅ DONE!

Bug telah diperbaiki. Total jam tidur sekarang akan terakumulasi dengan benar, baik untuk:
- Multiple catatan di hari berbeda
- Multiple catatan di hari yang sama
- Kombinasi keduanya

**Status**: READY FOR TESTING 🚀
