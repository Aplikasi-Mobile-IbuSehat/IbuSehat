import 'package:flutter/material.dart';
import 'package:mobile/pages/skincare/skincare_detail_page.dart';
import 'package:mobile/theme/app_colors.dart';

class SkincarePage extends StatefulWidget {
  const SkincarePage({super.key});

  @override
  State<SkincarePage> createState() => _SkincarePageState();
}

class _SkincarePageState extends State<SkincarePage> {
  bool _isNormalDelivery = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Skincare Rekomendasi',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildTypeSelector(isDark),
              const SizedBox(height: 24),
              _buildHeroSection(isDark),
              const SizedBox(height: 32),
              _buildSectionTitle('Masalah Kulit', textPrimary),
              const SizedBox(height: 16),
              _buildSkinProblemsHorizontal(isDark),
              const SizedBox(height: 32),
              _buildSectionTitle('Quick Routine', textPrimary),
              const SizedBox(height: 16),
              _buildQuickRoutineCard(isDark),
              const SizedBox(height: 32),
              _buildSectionTitle('Kandungan Aman', textPrimary),
              const SizedBox(height: 16),
              _buildSafeIngredientsSection(isDark),
              const SizedBox(height: 32),
              _buildSectionTitle('Tips Singkat', textPrimary),
              const SizedBox(height: 16),
              _buildQuickTipsFooter(isDark),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    final surface = isDark ? darkSurface : Colors.white;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: isDark ? 0.9 : 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? darkBorder : Colors.white),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                title: 'Lahir Normal',
                isActive: _isNormalDelivery,
                onTap: () => setState(() => _isNormalDelivery = true),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _buildTypeButton(
                title: 'Lahir Sesar',
                isActive: !_isNormalDelivery,
                onTap: () => setState(() => _isNormalDelivery = false),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({required String title, required bool isActive, required VoidCallback onTap, required bool isDark}) {
    final textPrimary = isDark ? darkTextPrimary : const Color(0xFF1F1235);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isActive
              ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)])
              : null,
          color: isActive ? null : Colors.transparent,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : textPrimary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    final surface = isDark ? darkSurface : Colors.white;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  _isNormalDelivery 
                    ? 'assets/images/skincare/hero_section_normal.webp' 
                    : 'assets/images/skincare/hero_section_sesar.webp',
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isNormalDelivery ? 'Pemulihan Kilau' : 'Perawatan Pasca Sesar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 180,
                      child: Text(
                        _isNormalDelivery 
                          ? 'Kembalikan kesehatan kulitmu setelah momen istimewa.'
                          : 'Fokus pada penyembuhan luka dan kesehatan kulit di area operasi.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSkinProblemsHorizontal(bool isDark) {
    final sections = _isNormalDelivery ? _normalSections() : _sesarSections();
    final problems = sections.where((s) => s['title'] != 'Rutinitas Perawatan Harian' && s['title'] != 'Rutinitas Perawatan Harian (Sesar)').toList();
    final surface = isDark ? darkSurface : Colors.white;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(problems.length, (index) {
          final problem = problems[index];
          final color = problem['color'] as Color;
          final title = problem['title'] as String;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                final content = problem['contentData'] as Map<String, dynamic>;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SkincareDetailPage(
                      title: title,
                      overview: content['overview'] as String,
                      recommendations: (content['recommendations'] as List).cast<ItemDetail>(),
                      avoid: (content['avoid'] as List).cast<String>(),
                      tips: content['tips'] as String,
                      themeColor: color,
                      imagePath: problem['image'] as String,
                    ),
                  ),
                );
              },
              child: Container(
                width: 240,
                height: 160,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // Background Image
                      Positioned.fill(
                        child: Image.asset(
                          problem['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: color.withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(problem['icon'] as IconData, color: color, size: 48),
                            ),
                          ),
                        ),
                      ),
                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.8),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Title Text Overlay
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickRoutineCard(bool isDark) {
    final surface = isDark ? darkSurface : Colors.white;
    final textPrimary = isDark ? darkTextPrimary : const Color(0xFF1F1235);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Rutinitas Singkat',
                  style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRoutineGroupHeader(Icons.wb_sunny_rounded, 'Pagi'),
                      const SizedBox(height: 16),
                      _buildRoutineStep('1', 'Bersihkan', 'Gentle cleanser', isDark),
                      _buildRoutineStep('2', 'Hidrasi', 'Hyaluronic Acid', isDark),
                      _buildRoutineStep('3', 'Proteksi', 'Sunscreen', isDark),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRoutineGroupHeader(Icons.nightlight_round, 'Malam'),
                      const SizedBox(height: 16),
                      _buildRoutineStep('1', 'Bersihkan', 'Double cleanse', isDark),
                      _buildRoutineStep('2', 'Nutrisi', 'Serum & Night cream', isDark),
                      _buildRoutineStep('3', 'Hidrasi', 'Moisturizer', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineGroupHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF8B5CF6),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineStep(String num, String title, String subtitle, bool isDark) {
    final textPrimary = isDark ? darkTextPrimary : const Color(0xFF1F1235);
    final textSecondary = isDark ? darkTextSecondary : const Color(0xFF1F1235).withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                Text(subtitle, style: TextStyle(color: textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeIngredientsSection(bool isDark) {
    final surface = isDark ? darkSurface : Colors.white;
    final textPrimary = isDark ? darkTextPrimary : const Color(0xFF1F1235);

    final ingredients = [
      {'name': 'Vitamin C', 'icon': Icons.brightness_high_rounded, 'color': Colors.orange},
      {'name': 'Hyaluronic', 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
      {'name': 'Niacinamide', 'icon': Icons.verified_user_rounded, 'color': Colors.green},
      {'name': 'Ceramides', 'icon': Icons.shield_rounded, 'color': Colors.purple},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          final item = ingredients[index];
          final color = item['color'] as Color;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: isDark ? 0.2 : 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(item['icon'] as IconData, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  item['name'] as String,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickTipsFooter(bool isDark) {
    final surface = isDark ? darkSurface : Colors.white;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTipItem(Icons.water_drop_rounded, 'Minum minimal 2.5–3 Liter air per hari untuk hidrasi kulit dari dalam.', isDark),
            const SizedBox(height: 20),
            _buildTipItem(Icons.auto_awesome_rounded, 'Gunakan sarung bantal berbahan sutra atau katun lembut untuk kurangi gesekan.', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text, bool isDark) {
    final textPrimary = isDark ? darkTextPrimary : const Color(0xFF1F1235);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _normalSections() => [
    {
      'title': 'Hiperpigmentasi',
      'icon': Icons.brightness_3_rounded,
      'image': 'assets/images/skincare/hiperpigmentasi.webp',
      'color': const Color(0xFFF59E0B),
      'contentData': {
        'overview': 'Peningkatan melanin akibat perubahan hormon estrogen & progesteron selama kehamilan menyebabkan bercak gelap (melasma/chloasma) di wajah, leher, dan perut.',
        'recommendations': [
          const ItemDetail(title: 'Gunakan Sunscreen SPF 30+', desc: 'Pilih mineral sunscreen berbahan Zinc Oxide atau Titanium Dioxide yang aman untuk ibu menyusui.'),
          const ItemDetail(title: 'Vitamin C Serum', desc: 'Gunakan serum Vitamin C 10-15% di pagi hari untuk membantu mencerahkan noda gelap.'),
          const ItemDetail(title: 'Niacinamide', desc: 'Bahan ini efektif mereduksi produksi melanin. Cocok digunakan pagi dan malam hari.'),
          const ItemDetail(title: 'Azelaic Acid', desc: 'Alternatif aman untuk mencerahkan kulit di masa menyusui. Lebih lembut dibanding bahan pemutih lainnya.'),
        ],
        'avoid': [
          'Hidroquinon — tidak aman untuk ibu menyusui',
          'Retinol/Tretinoin dosis tinggi tanpa konsultasi dokter',
          'Paparan sinar matahari langsung tanpa perlindungan',
        ],
        'tips': 'Hiperpigmentasi pasca melahirkan biasanya membaik sendiri dalam 3-6 bulan. Konsisten menggunakan sunscreen adalah kunci utama.',
      },
    },
    {
      'title': 'Kulit Kering & Dehidrasi',
      'icon': Icons.water_drop_outlined,
      'image': 'assets/images/skincare/kulit_kering.webp',
      'color': const Color(0xFF3B82F6),
      'contentData': {
        'overview': 'Penurunan kadar hormon estrogen setelah melahirkan mengurangi kemampuan kulit mempertahankan kelembaban, menyebabkan kulit terasa kering dan kusam.',
        'recommendations': [
          const ItemDetail(title: 'Pelembab Hyaluronic Acid', desc: 'Aplikasikan segera setelah mandi saat kulit masih sedikit lembab.'),
          const ItemDetail(title: 'Ceramides', desc: 'Memperkuat skin barrier yang melemah setelah melahirkan.'),
          const ItemDetail(title: 'Minyak Alami', desc: 'Rosehip oil atau Jojoba oil bisa digunakan untuk mengunci kelembaban.'),
          const ItemDetail(title: 'Konsumsi Air Cukup', desc: 'Minum minimal 2,5–3 liter air per hari. Produksi ASI membutuhkan banyak cairan.'),
        ],
        'avoid': [
          'Produk pembersih berbahan SLS yang keras',
          'Air panas saat mandi — gunakan air hangat suam-suam kuku',
          'Alkohol dalam kandungan toner atau serum',
        ],
        'tips': 'Gunakan pelembab saat kulit masih lembab setelah mandi (teknik damp skin) untuk hasil maksimal.',
      },
    },
    {
      'title': 'Jerawat Hormonal',
      'icon': Icons.bubble_chart_rounded,
      'image': 'assets/images/skincare/jerawat_hormonal.webp',
      'color': const Color(0xFFEF4444),
      'contentData': {
        'overview': 'Lonjakan hormon androgen setelah melahirkan dapat memicu produksi minyak berlebih, menyebabkan jerawat di area dagu dan pipi.',
        'recommendations': [
          const ItemDetail(title: 'Niacinamide 5-10%', desc: 'Mengontrol produksi sebum dan meminimalkan tampilan pori.'),
          const ItemDetail(title: 'BHA (Salicylic Acid)', desc: 'Dalam konsentrasi rendah (0.5-2%), aman untuk ibu menyusui.'),
          const ItemDetail(title: 'Zinc-based Products', desc: 'Zinc PCA membantu mengontrol minyak dan bersifat antibakteri ringan.'),
        ],
        'avoid': [
          'Memencet jerawat — dapat menyebabkan infeksi and bekas luka',
          'Benzoyl Peroxide dosis tinggi tanpa rekomendasi dokter',
        ],
        'tips': 'Jaga pola makan rendah gula yang dapat memperburuk jerawat hormonal.',
      },
    },
    {
      'title': 'Stretch Marks (Striae)',
      'icon': Icons.linear_scale_rounded,
      'image': 'assets/images/skincare/stretch_marks.webp',
      'color': const Color(0xFF8B5CF6),
      'contentData': {
        'overview': 'Stretch marks terbentuk akibat peregangan kulit yang cepat selama kehamilan. Berwarna merah/ungu di awal, lalu memudar menjadi putih.',
        'recommendations': [
          const ItemDetail(title: 'Centella Asiatica', desc: 'Membantu merangsang produksi kolagen dan mempercepat regenerasi kulit.'),
          const ItemDetail(title: 'Rosehip Oil', desc: 'Kaya Vitamin A alami dan asam lemak omega untuk memudarkan warna.'),
          const ItemDetail(title: 'Shea Butter', desc: 'Melembabkan dan menjaga elastisitas kulit secara intensif.'),
        ],
        'avoid': [
          'Retinol tinggi tanpa konsultasi dokter',
          'Menggosok terlalu keras area stretch marks',
        ],
        'tips': 'Pijat ringan dengan minyak alami selama 5-10 menit dapat meningkatkan sirkulasi dan penyerapan.',
      },
    },
  ];

  List<Map<String, dynamic>> _sesarSections() => [
    {
      'title': 'Perawatan Bekas Luka Sesar',
      'icon': Icons.healing_rounded,
      'image': 'assets/images/skincare/bekas_luka_sesar.webp',
      'color': const Color(0xFF8B5CF6),
      'contentData': {
        'overview': 'Setelah luka operasi menutup sempurna (6-8 minggu), perawatan bekas luka dimulai untuk meminimalkan keloid dan tekstur tidak rata.',
        'recommendations': [
          const ItemDetail(title: 'Silicone Gel / Sheet', desc: 'Metode terbaik secara klinis untuk mengurangi bekas luka parut.'),
          const ItemDetail(title: 'Centella Asiatica Oil', desc: 'Merangsang produksi kolagen normal dan mengurangi inflamasi.'),
          const ItemDetail(title: 'Vitamin E Oil', desc: 'Melembabkan area sekitar bekas luka und mengurangi ketegangan kulit.'),
        ],
        'avoid': [
          'Menggaruk atau mengelupas kerak pada bekas luka',
          'Paparan sinar matahari tanpa perlindungan (mudah hitam)',
        ],
        'tips': 'Pijat bekas luka secara bertahap membantu memecah jaringan fibrosa yang kaku.',
      },
    },
    {
      'title': 'Perawatan Luka Operasi (Fase Awal)',
      'icon': Icons.medical_services_rounded,
      'image': 'assets/images/skincare/bekas_operasi.webp',
      'color': const Color(0xFFEF4444),
      'contentData': {
        'overview': 'Luka operasi sesar perlu perawatan ketat pada 6-8 minggu pertama. Kebersihan adalah kunci penyembuhan.',
        'recommendations': [
          const ItemDetail(title: 'Jaga Kebersihan Luka', desc: 'Bersihkan area luka dengan air bersih dan sabun lembut tanpa parfum.'),
          const ItemDetail(title: 'Hindari Air Berlebih', desc: 'Jangan merendam luka di bak mandi pada 2 minggu pertama.'),
          const ItemDetail(title: 'Gunakan Pakaian Katun', desc: 'Pilih pakaian longgar berbahan katun 100% untuk mengurangi gesekan.'),
        ],
        'avoid': [
          'Mengaplikasikan produk apapun ke luka yang belum menutup',
          'Memakai pakaian ketat yang menekan area luka',
        ],
        'tips': 'Gunakan bantal kecil di perut saat batuk untuk mengurangi tekanan pada luka.',
      },
    },
    {
      'title': 'Stretch Marks Pasca Sesar',
      'icon': Icons.linear_scale_rounded,
      'image': 'assets/images/skincare/stretch_marks_sesar.webp',
      'color': const Color(0xFF10B981),
      'contentData': {
        'overview': 'Perawatan stretch marks pada ibu sesar sama dengan normal, namun perlu hati-hati di sekitar area luka operasi.',
        'recommendations': [
          const ItemDetail(title: 'Fokus pada Area Aman', desc: 'Perlakukan area paha, pinggul, dan payudara terlebih dahulu.'),
          const ItemDetail(title: 'Centella Body Butter', desc: 'Aplikasikan pada area stretch marks jauh dari luka operasi.'),
        ],
        'avoid': [
          'AHA/BHA di area dekat luka operasi',
          'Tekanan/gosokan keras di area perut dalam 3 bulan pertama',
        ],
        'tips': 'Mulai perawatan area perut hanya setelah luka benar-benar sembuh total.',
      },
    },
  ];
}
