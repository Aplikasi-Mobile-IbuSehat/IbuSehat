import 'package:flutter/material.dart';
import 'package:mobile/pages/beranda/sleep_tracking_sheet.dart';

class SleepFab extends StatelessWidget {
  const SleepFab({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const SleepTrackingSheet(),
          );
        },
        backgroundColor: const Color(0xFF7465F3), // Warna ungu sesuai contoh gambar
        elevation: 4,
        shape: const CircleBorder(), // Agar tombol bulat sempurna
        child: const Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Ikon orang tidur di kasur
            Positioned(
              top: 22,
              child: Icon(
                Icons.hotel_rounded,
                color: Colors.white70, // Ikon warna putih pudar
                size: 26,
              ),
            ),
            // Ikon bulan di atas kasur
            Positioned(
              top: 8,
              child: Icon(
                Icons.bedtime_rounded, // Bulan sabit
                color: Colors.white70, // Ikon warna putih pudar
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
