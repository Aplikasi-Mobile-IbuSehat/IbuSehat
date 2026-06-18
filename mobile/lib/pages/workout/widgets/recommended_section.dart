import 'package:flutter/material.dart';
import 'package:mobile/pages/workout/active_workout_page.dart';
import 'package:mobile/pages/workout/workout_preview_page.dart';
import 'package:mobile/utils/video_pool.dart';

class RecommendedSection extends StatelessWidget {
  final String selectedCategory;

  const RecommendedSection({super.key, this.selectedCategory = 'Semua'});

  @override
  Widget build(BuildContext context) {
    final workoutCards = <Widget>[
      if (selectedCategory == 'Semua' || selectedCategory == 'Pemanasan Tubuh')
        _buildWorkoutCard(
          context: context,
          title: 'Pemanasan Tubuh',
          time: '8 mnt',
          level: 'Pemula',
          imageUrl:
              'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=400',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutPreviewPage(
                  title: 'Warm-Up (Pemanasan)',
                  imageUrl:
                      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=400',
                  duration: '5–10 menit',
                  difficulty: 'Beginner',
                  target: 'Full Body',
                  equipment: 'None / Mat (optional)',
                  instructions: [
                    'Lakukan pemanasan ringan selama beberapa menit',
                    'Gunakan gerakan dinamis untuk mengaktifkan otot',
                    'Tingkatkan detak jantung secara bertahap',
                    'Fokus pada pergerakan seluruh tubuh',
                    'Siapkan tubuh sebelum latihan inti dimulai',
                  ],
                  exerciseDetails: [
                    ExerciseData(
                      title: "Sit Up",
                      description:
                          "Sit Up dilakukan untuk memperkuat otot perut dengan cara mengangkat tubuh dari posisi telentang hingga posisi duduk.",
                      tips: [
                        "Jangan tarik leher saat naik",
                        "Gunakan otot perut, bukan punggung",
                        "Turun perlahan, jangan jatuhkan badan",
                        "Bernapas teratur",
                      ],
                      categories: [
                        "💪 Perut",
                        "🏋️ Kekuatan",
                        "⚠️ Lahir Normal",
                      ],
                    ),
                    ExerciseData(
                      title: "Lateral Lunge",
                      description:
                          "Lateral Lunge dilakukan untuk melatih paha, bokong, dan paha dalam dengan gerakan langkah ke samping lalu jongkok.",
                      tips: [
                        "Lutut jangan melewati ujung kaki",
                        "Punggung tetap lurus",
                        "Kaki satunya tetap lurus",
                        "Turun perlahan",
                      ],
                      categories: [
                        "🏋️ Kekuatan",
                        "✅ Lahir Normal",
                        "✅ Lahir Sesar",
                      ],
                    ),
                    ExerciseData(
                      title: "Bicycle Kicks",
                      description:
                          "Bicycle Kicks dilakukan untuk melatih otot perut bawah dengan gerakan kaki naik turun bergantian seperti mengayuh sepeda.",
                      tips: [
                        "Punggung tetap menempel di lantai",
                        "Perut dikencangkan",
                        "Gerakan jangan terlalu cepat",
                        "Bernapas teratur",
                      ],
                      categories: [
                        "💪 Perut",
                        "⏱️ Ketahanan",
                        "⚠️ Lahir Normal",
                      ],
                    ),
                    ExerciseData(
                      title: "Bicycle Crunch",
                      description:
                          "Bicycle Crunch dilakukan untuk melatih perut dengan gerakan siku menyentuh lutut yang berlawanan secara bergantian.",
                      tips: [
                        "Jangan tarik leher",
                        "Putar badan, bukan hanya tangan",
                        "Gerakan perlahan",
                        "Fokus ke otot perut",
                      ],
                      categories: [
                        "💪 Perut",
                        "🏋️ Kekuatan",
                        "⚠️ Lahir Normal",
                      ],
                    ),
                    ExerciseData(
                      title: "Jackknife Sit-Up",
                      description:
                          "Jackknife Sit-Up seagai Latihan perut dengan mengangkat kaki dan badan secara bersamaan hingga membentuk huruf V.",
                      tips: [
                        "Kaki tetap lurus",
                        "Angkat badan dengan otot perut",
                        "Turun perlahan",
                        "Jangan menahan napas",
                      ],
                      categories: [
                        "💪 Perut",
                        "🏋️ Kekuatan",
                        "✅ Lahir Normal",
                      ],
                    ),
                    ExerciseData(
                      title: "Russian Twist",
                      description:
                          "Russian Twist untuk melatih otot perut samping dengan gerakan memutar badan ke kanan dan kiri.",
                      tips: [
                        "Putar badan, bukan hanya tangan",
                        "Punggung agak miring",
                        "Perut tetap kencang",
                        "Gerakan perlahan",
                      ],
                      categories: [
                        "💪 Perut",
                        "🏋️ Kekuatan",
                        "⚠️ Lahir Normal",
                      ],
                    ),
                    ExerciseData(
                      title: "Side Plank",
                      description:
                          "Side Plank untuk melatih otot perut samping dan core dengan posisi tubuh menyamping dan ditahan.",
                      tips: [
                        "Badan harus lurus",
                        "Pinggul jangan turun",
                        "Kencangkan perut",
                        "Tahan posisi dan bernapas normal",
                      ],
                      categories: [
                        "💪 Perut",
                        "🏋️ Kekuatan",
                        "⚠️ Lahir Normal",
                        "⚠️ Lahir Sesar",
                      ],
                    ),
                    ExerciseData(
                      title: "Push Up",
                      description:
                          "Latihan Push Up untuk memperkuat otot dada, bahu, lengan, dan otot inti (core) dengan gerakan mendorong tubuh naik turun menggunakan tangan.",
                      tips: [
                        "Badan harus lurus dari kepala sampai kaki",
                        "Jangan turunkan pinggul",
                        "Siku jangan terlalu melebar",
                        "Turun perlahan, naik kuat",
                        "Bernapas teratur (turun tarik napas, naik buang napas)",
                      ],
                      categories: [
                        "🏋️ Kekuatan",
                        "✅ Lahir Normal",
                        "⚠️ Lahir Sesar",
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      if (selectedCategory == 'Semua' || selectedCategory == 'Kekuatan Tubuh')
        _buildWorkoutCard(
          context: context,
          title: 'Kekuatan Tubuh',
          time: '6 mnt',
          level: 'Menengah',
          imageUrl:
              'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=400',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutPreviewPage(
                  title: 'Full Body Strength',
                  imageUrl:
                      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=400',
                  duration: '30 min',
                  difficulty: 'Intermediate',
                  target: 'Full Body',
                  equipment: 'Dumbbells',
                  instructions: [
                    'Start with a 5-minute warm-up',
                    'Perform each exercise for 45 seconds',
                    'Rest for 15 seconds between exercises',
                    'Complete 3 rounds of the circuit',
                    'Cool down and stretch for 5 minutes',
                  ],
                  exerciseDetails: [
                    ExerciseData(
                      title: "Dumbbell Forward Lunge",
                      description:
                          "Forward Lunge dilakukan untuk memperkuat otot kaki dan bokong dengan cara melangkah ke depan lalu menurunkan badan sampai lutut belakang mendekati lantai, kemudian kembali berdiri.",
                      tips: [
                        "Pastikan lutut depan tidak melewati ujung kaki",
                        "Jaga punggung tetap tegak",
                        "Turunkan badan secara perlahan",
                        "Dorong tubuh kembali berdiri menggunakan tumit",
                      ],
                      categories: [
                        "🦵 Kaki & Bokong",
                        "🏋️ Kekuatan",
                        "✅ Lahir Normal",
                        "✅ Lahir Sesar",
                      ],
                    ),
                    ExerciseData(
                      title: "Dumbbell Biceps Curl",
                      description:
                          "Biceps Curl dilakukan untuk memperkuat otot lengan depan (biceps) dengan cara mengangkat dumbbell ke atas dengan menekuk siku lalu menurunkannya kembali secara perlahan.",
                      tips: [
                        "Siku tetap di samping badan",
                        "Jangan mengayunkan badan",
                        "Angkat dumbbell perlahan",
                        "Turunkan dumbbell secara terkontrol",
                      ],
                      categories: [
                        "💪 Lengan",
                        "🏋️ Kekuatan",
                        "✅ Lahir Normal",
                        "✅ Lahir Sesar",
                      ],
                    ),
                    ExerciseData(
                      title: "Dumbbell Shoulder Press",
                      description:
                          "Shoulder Press dilakukan untuk memperkuat otot bahu dengan cara mendorong dumbbell dari posisi bahu ke atas kepala lalu menurunkannya kembali ke posisi semula.",
                      tips: [
                        "Tekan dumbbell lurus ke atas",
                        "Jangan melengkungkan punggung",
                        "Turunkan dumbbell sampai setinggi bahu",
                        "Kencangkan otot perut saat mendorong",
                      ],
                      categories: [
                        "🦾 Bahu & Lengan",
                        "🏋️ Kekuatan",
                        "✅ Lahir Normal",
                        "⚠️ Lahir Sesar",
                      ],
                    ),
                    ExerciseData(
                      title: "Dumbbell Lateral Raise",
                      description:
                          "Lateral Raise dilakukan untuk melatih otot bahu samping dengan cara mengangkat dumbbell ke samping sampai setinggi bahu lalu menurunkannya kembali.",
                      tips: [
                        "Angkat dumbbell hanya sampai setinggi bahu",
                        "Siku sedikit ditekuk",
                        "Jangan mengayunkan badan",
                        "Turunkan dumbbell perlahan",
                      ],
                      categories: [
                        "🦾 Bahu",
                        "🏋️ Kekuatan",
                        "✅ Lahir Normal",
                        "⚠️ Lahir Sesar",
                      ],
                    ),
                    ExerciseData(
                      title: "Dumbbell Front Raise",
                      description:
                          "Front Raise dilakukan untuk melatih otot bahu depan dengan cara mengangkat dumbbell ke depan sampai setinggi bahu lalu menurunkannya kembali secara perlahan.",
                      tips: [
                        "Angkat dumbbell sampai setinggi bahu",
                        "Jangan mengayunkan badan",
                        "Jaga punggung tetap tegak",
                        "Turunkan dumbbell secara perlahan",
                      ],
                      categories: [
                        "🦾 Bahu",
                        "🏋️ Kekuatan",
                        "✅ Lahir Normal",
                        "⚠️ Lahir Sesar",
                      ],
                    ),
                    ExerciseData(
                      title: "Dumbbell Overhead Triceps Extension",
                      description:
                          "Overhead Triceps Extension dilakukan untuk melatih otot triceps (belakang lengan) dengan cara menurunkan dumbbell ke belakang kepala lalu mengangkatnya kembali ke atas.",
                      tips: [
                        "Siku tetap mengarah ke depan",
                        "Jangan membuka siku ke samping",
                        "Turunkan dumbbell perlahan",
                        "Jaga perut tetap kencang",
                      ],
                      categories: [
                        "💪 Lengan (Triceps)",
                        "🏋️ Kekuatan",
                        "✅ Lahir Normal",
                        "⚠️ Lahir Sesar",
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      if (selectedCategory == 'Semua' ||
          selectedCategory == 'Latihan Kelenturan' ||
          selectedCategory == 'Fitnest')
        _buildWorkoutCard(
          context: context,
          title: 'Core Pilates',
          time: '5 mnt',
          level: 'Pemula',
          imageUrl:
              'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=400',
        ),
      if (selectedCategory == 'Semua' || selectedCategory == 'Latihan Mikro')
        _buildWorkoutCard(
          context: context,
          title: 'Peregangan Malam',
          time: '5 mnt',
          level: 'Pemula',
          imageUrl: 'https://pbs.twimg.com/media/FC1RfxgWUAMr_qY.jpg',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (workoutCards.isEmpty)
          const SizedBox.shrink()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Lebar kartu: ~2 kartu penuh + cuplikan kartu ketiga → jelas bisa di-slide
              final w = constraints.maxWidth;
              final cardWidth = ((w - 16) / 2.15).clamp(148.0, 172.0);
              return SizedBox(
                height: 232,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 4),
                  clipBehavior: Clip.none,
                  itemCount: workoutCards.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) =>
                      SizedBox(width: cardWidth, child: workoutCards[index]),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildWorkoutCard({
    BuildContext? context,
    required String title,
    required String time,
    required String level,
    required String imageUrl,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video belum tersedia untuk kategori ini'),
                ),
              );
            }
          },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image part
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image fails to load
                    return Container(
                      width: double.infinity,
                      color: Colors.purple.shade50,
                      child: Icon(
                        Icons.fitness_center,
                        color: Colors.purple.shade200,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Text part
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1235),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
