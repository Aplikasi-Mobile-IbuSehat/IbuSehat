import 'package:flutter/material.dart';
import 'package:mobile/pages/catat_tidur_page.dart';
import 'package:mobile/theme/app_colors.dart';

class SleepFab extends StatelessWidget {
  const SleepFab({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: buttonGradient,
          boxShadow: [
            BoxShadow(
              color: Color(0x406C4DFF),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const CatatTidurPage(),
                ),
              );
            },
            child: const Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 22,
                  child: Icon(
                    Icons.hotel_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                Positioned(
                  top: 8,
                  child: Icon(
                    Icons.bedtime_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
