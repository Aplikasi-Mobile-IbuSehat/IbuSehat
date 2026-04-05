import 'package:flutter/material.dart';
import 'package:mobile/pages/progress/widgets/langkah_card.dart';
import 'package:mobile/pages/progress/widgets/score_tidur_card.dart';
import 'package:mobile/pages/progress/widgets/berat_card.dart';
import 'package:mobile/pages/progress/widgets/waktu_latihan_card.dart';
import 'package:mobile/pages/progress/widgets/kalori_makanan_card.dart';
import 'package:mobile/widgets/app_background.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Progress',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              children: [
                Row(
                  children: const [
                    Expanded(child: LangkahCard()),
                    SizedBox(width: 16),
                    Expanded(child: ScoreTidurCard()),
                  ],
                ),
                const SizedBox(height: 16),
                const BeratCard(),
                const SizedBox(height: 16),
                const WaktuLatihanCard(),
                const SizedBox(height: 16),
                const KaloriMakananCard(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
