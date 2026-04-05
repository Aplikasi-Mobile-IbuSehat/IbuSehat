import 'package:flutter/material.dart';
import 'package:mobile/pages/workout/active_workout_page.dart';

class RecommendedSection extends StatelessWidget {
  final String selectedCategory;

  const RecommendedSection({
    super.key,
    this.selectedCategory = 'Semua',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.75, // Adjust width to height ratio
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            if (selectedCategory == 'Semua' || selectedCategory == 'Pemanasan Tubuh')
              _buildWorkoutCard(
                context: context,
                title: 'Pemanasan Tubuh',
                time: '14 mnt',
                level: 'Pemula',
                imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=400',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActiveWorkoutPage(
                      playlist: [
                        "assets/videos/vid_1.mp4",
                        "assets/videos/vid_3.mp4",
                        "assets/videos/vid_4.mp4",
                        "assets/videos/vid_5.mp4",
                        "assets/videos/vid_6.mp4",
                        "assets/videos/vid_7.mp4",
                        "assets/videos/vid_8.mp4",
                        "assets/videos/vid_9.mp4",
                      ],
                      exerciseDetails: const [
                        ExerciseData(
                          title: "Sit Up",
                          description: "Sit Up dilakukan untuk memperkuat otot perut dengan cara mengangkat tubuh dari posisi telentang hingga posisi duduk.",
                          tips: [
                            "Jangan tarik leher saat naik",
                            "Gunakan otot perut, bukan punggung",
                            "Turun perlahan, jangan jatuhkan badan",
                            "Bernapas teratur"
                          ],
                          categories: ["💪 Perut", "🏋️ Kekuatan", "⚠️ Lahir Normal"],
                        ),
                        ExerciseData(
                          title: "Lateral Lunge",
                          description: "Lateral Lunge dilakukan untuk melatih paha, bokong, dan paha dalam dengan gerakan langkah ke samping lalu jongkok.",
                          tips: [
                            "Lutut jangan melewati ujung kaki",
                            "Punggung tetap lurus",
                            "Kaki satunya tetap lurus",
                            "Turun perlahan"
                          ],
                          categories: ["🏋️ Kekuatan", "🔥 Pemula", "✅ Lahir Normal", "✅ Lahir Sesar"],
                        ),
                        ExerciseData(
                          title: "Bicycle Kicks",
                          description: "Bicycle Kicks dilakukan untuk melatih otot perut bawah dengan gerakan kaki naik turun bergantian seperti mengayuh sepeda.",
                          tips: [
                            "Punggung tetap menempel di lantai",
                            "Perut dikencangkan",
                            "Gerakan jangan terlalu cepat",
                            "Bernapas teratur"
                          ],
                          categories: ["💪 Perut", "⏱️ Ketahanan", "⚠️ Lahir Normal"],
                        ),
                        ExerciseData(
                          title: "Bicycle Crunch",
                          description: "Bicycle Crunch dilakukan untuk melatih perut dengan gerakan siku menyentuh lutut yang berlawanan secara bergantian.",
                          tips: [
                            "Jangan tarik leher",
                            "Putar badan, bukan hanya tangan",
                            "Gerakan perlahan",
                            "Fokus ke otot perut"
                          ],
                          categories: ["💪 Perut", "🏋️ Kekuatan", "⚠️ Lahir Normal"],
                        ),
                        ExerciseData(
                          title: "Jackknife Sit-Up",
                          description: "Jackknife Sit-Up seagai Latihan perut dengan mengangkat kaki dan badan secara bersamaan hingga membentuk huruf V.",
                          tips: [
                            "Kaki tetap lurus",
                            "Angkat badan dengan otot perut",
                            "Turun perlahan",
                            "Jangan menahan napas"
                          ],
                          categories: ["💪 Perut", "🏋️ Kekuatan", "✅ Lahir Normal"],
                        ),
                        ExerciseData(
                          title: "Russian Twist",
                          description: "Russian Twist untuk melatih otot perut samping dengan gerakan memutar badan ke kanan dan kiri.",
                          tips: [
                            "Putar badan, bukan hanya tangan",
                            "Punggung agak miring",
                            "Perut tetap kencang",
                            "Gerakan perlahan"
                          ],
                          categories: ["💪 Perut", "🏋️ Kekuatan", "⚠️ Lahir Normal"],
                        ),
                        ExerciseData(
                          title: "Side Plank",
                          description: "Side Plank untuk melatih otot perut samping dan core dengan posisi tubuh menyamping dan ditahan.",
                          tips: [
                            "Badan harus lurus",
                            "Pinggul jangan turun",
                            "Kencangkan perut",
                            "Tahan posisi dan bernapas normal"
                          ],
                          categories: ["💪 Perut", "🏋️ Kekuatan", "⚠️ Lahir Normal", "⚠️ Lahir Sesar"],
                        ),
                        ExerciseData(
                          title: "Push Up",
                          description: "Latihan Push Up untuk memperkuat otot dada, bahu, lengan, dan otot inti (core) dengan gerakan mendorong tubuh naik turun menggunakan tangan.",
                          tips: [
                            "Badan harus lurus dari kepala sampai kaki",
                            "Jangan turunkan pinggul",
                            "Siku jangan terlalu melebar",
                            "Turun perlahan, naik kuat",
                            "Bernapas teratur (turun tarik napas, naik buang napas)"
                          ],
                          categories: ["🏋️ Kekuatan", "✅ Lahir Normal", "⚠️ Lahir Sesar"],
                        ),
                      ],
                    )),
                  );
                },
              ),
            if (selectedCategory == 'Semua' || selectedCategory == 'Kekuatan Tubuh')
              _buildWorkoutCard(
                context: context,
                title: 'Kekuatan Tubuh',
                time: '45 mnt',
                level: 'Menengah',
                imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?q=80&w=400',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActiveWorkoutPage(
                      playlist: const [
                        "assets/videos/dumble/1.mp4",
                        "assets/videos/dumble/2.mp4",
                        "assets/videos/dumble/3.mp4",
                        "assets/videos/dumble/4.mp4",
                        "assets/videos/dumble/5.mp4",
                        "assets/videos/dumble/6.mp4",
                      ],
                      exerciseDetails: const [
                        ExerciseData(
                          title: "Dumbbell Forward Lunge",
                          description: "Forward Lunge dilakukan untuk memperkuat otot kaki dan bokong dengan cara melangkah ke depan lalu menurunkan badan sampai lutut belakang mendekati lantai, kemudian kembali berdiri.",
                          tips: [
                            "Pastikan lutut depan tidak melewati ujung kaki",
                            "Jaga punggung tetap tegak",
                            "Turunkan badan secara perlahan",
                            "Dorong tubuh kembali berdiri menggunakan tumit",
                          ],
                          categories: ["🦵 Kaki & Bokong", "🏋️ Kekuatan", "🔥 Pemula", "✅ Lahir Normal", "✅ Lahir Sesar"],
                        ),
                        ExerciseData(
                          title: "Dumbbell Biceps Curl",
                          description: "Biceps Curl dilakukan untuk memperkuat otot lengan depan (biceps) dengan cara mengangkat dumbbell ke atas dengan menekuk siku lalu menurunkannya kembali secara perlahan.",
                          tips: [
                            "Siku tetap di samping badan",
                            "Jangan mengayunkan badan",
                            "Angkat dumbbell perlahan",
                            "Turunkan dumbbell secara terkontrol",
                          ],
                          categories: ["💪 Lengan", "🏋️ Kekuatan", "🔥 Pemula", "✅ Lahir Normal", "✅ Lahir Sesar"],
                        ),
                        ExerciseData(
                          title: "Dumbbell Shoulder Press",
                          description: "Shoulder Press dilakukan untuk memperkuat otot bahu dengan cara mendorong dumbbell dari posisi bahu ke atas kepala lalu menurunkannya kembali ke posisi semula.",
                          tips: [
                            "Tekan dumbbell lurus ke atas",
                            "Jangan melengkungkan punggung",
                            "Turunkan dumbbell sampai setinggi bahu",
                            "Kencangkan otot perut saat mendorong",
                          ],
                          categories: ["🦾 Bahu & Lengan", "🏋️ Kekuatan", "🔥 Pemula", "✅ Lahir Normal", "⚠️ Lahir Sesar"],
                        ),
                        ExerciseData(
                          title: "Dumbbell Lateral Raise",
                          description: "Lateral Raise dilakukan untuk melatih otot bahu samping dengan cara mengangkat dumbbell ke samping sampai setinggi bahu lalu menurunkannya kembali.",
                          tips: [
                            "Angkat dumbbell hanya sampai setinggi bahu",
                            "Siku sedikit ditekuk",
                            "Jangan mengayunkan badan",
                            "Turunkan dumbbell perlahan",
                          ],
                          categories: ["🦾 Bahu", "🏋️ Kekuatan", "🔥 Pemula", "✅ Lahir Normal", "⚠️ Lahir Sesar"],
                        ),
                        ExerciseData(
                          title: "Dumbbell Front Raise",
                          description: "Front Raise dilakukan untuk melatih otot bahu depan dengan cara mengangkat dumbbell ke depan sampai setinggi bahu lalu menurunkannya kembali secara perlahan.",
                          tips: [
                            "Angkat dumbbell sampai setinggi bahu",
                            "Jangan mengayunkan badan",
                            "Jaga punggung tetap tegak",
                            "Turunkan dumbbell secara perlahan",
                          ],
                          categories: ["🦾 Bahu", "🏋️ Kekuatan", "🔥 Pemula", "✅ Lahir Normal", "⚠️ Lahir Sesar"],
                        ),
                        ExerciseData(
                          title: "Dumbbell Overhead Triceps Extension",
                          description: "Overhead Triceps Extension dilakukan untuk melatih otot triceps (belakang lengan) dengan cara menurunkan dumbbell ke belakang kepala lalu mengangkatnya kembali ke atas.",
                          tips: [
                            "Siku tetap mengarah ke depan",
                            "Jangan membuka siku ke samping",
                            "Turunkan dumbbell perlahan",
                            "Jaga perut tetap kencang",
                          ],
                          categories: ["💪 Lengan (Triceps)", "🏋️ Kekuatan", "🔥 Pemula", "✅ Lahir Normal", "⚠️ Lahir Sesar"],
                        ),
                      ],
                    )),
                  );
                },
              ),
            if (selectedCategory == 'Semua' || selectedCategory == 'Latihan Kelenturan')
              _buildWorkoutCard(
                context: context,
                title: 'Core Pilates',
                time: '25 mnt',
                level: 'Pemula',
                imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=400',
              ),
            if (selectedCategory == 'Semua' || selectedCategory == 'Latihan Mikro')
              _buildWorkoutCard(
                context: context,
                title: 'Peregangan Malam',
                time: '15 mnt',
                level: 'Pemula',
                imageUrl: 'https://pbs.twimg.com/media/FC1RfxgWUAMr_qY.jpg',
              ),
          ],
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
      onTap: onTap ?? () {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video belum tersedia untuk kategori ini')),
          );
        }
      },
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image fails to load
                  return Container(
                    width: double.infinity,
                    color: Colors.purple.shade50,
                    child: Icon(Icons.fitness_center, color: Colors.purple.shade200, size: 40),
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
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      level,
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
