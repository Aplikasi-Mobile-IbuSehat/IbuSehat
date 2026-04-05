import 'package:flutter/material.dart';
import 'package:mobile/widgets/app_background.dart';

class SkincarePage extends StatefulWidget {
  const SkincarePage({super.key});

  @override
  State<SkincarePage> createState() => _SkincarePageState();
}

class _SkincarePageState extends State<SkincarePage> {
  bool _isNormalDelivery = true;
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Perawatan Kulit',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1235),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F1235), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildTypeSelector(),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _isNormalDelivery
                        ? _buildNormalContent()
                        : _buildSesarContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                title: 'Lahir Normal',
                isActive: _isNormalDelivery,
                onTap: () => setState(() {
                  _isNormalDelivery = true;
                  _expandedIndex = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTypeButton(
                title: 'Lahir Sesar',
                isActive: !_isNormalDelivery,
                onTap: () => setState(() {
                  _isNormalDelivery = false;
                  _expandedIndex = null;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isActive
              ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)])
              : null,
          color: isActive ? null : Colors.transparent,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : const Color(0xFF1F1235).withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  // ─── NORMAL DELIVERY CONTENT ────────────────────────────────────────────────

  List<Widget> _buildNormalContent() {
    final sections = _normalSections();
    return [
      _buildIntroCard(
        title: 'Perawatan Kulit Pasca Lahir Normal',
        description:
            'Setelah melahirkan secara normal, tubuh Ibu mengalami perubahan hormon yang signifikan. Kondisi ini dapat mempengaruhi kulit secara langsung. Berikut panduan lengkap perawatan kulit pasca persalinan normal.',
        icon: Icons.spa_rounded,
        gradient: const [Color(0xFF9333EA), Color(0xFF7C3AED)],
      ),
      const SizedBox(height: 24),
      ...List.generate(sections.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildExpandableSection(
            index: i,
            title: sections[i]['title'] as String,
            icon: sections[i]['icon'] as IconData,
            color: sections[i]['color'] as Color,
            content: sections[i]['content'] as Widget,
          ),
        );
      }),
    ];
  }

  List<Map<String, dynamic>> _normalSections() => [
    {
      'title': 'Hiperpigmentasi',
      'icon': Icons.brightness_3_rounded,
      'color': const Color(0xFFF59E0B),
      'content': _buildDetailContent(
        overview: 'Peningkatan melanin akibat perubahan hormon estrogen & progesteron selama kehamilan menyebabkan bercak gelap (melasma/chloasma) di wajah, leher, dan perut.',
        recommendations: [
          _ItemDetail(title: 'Gunakan Sunscreen SPF 30+', desc: 'Pilih mineral sunscreen berbahan Zinc Oxide atau Titanium Dioxide yang aman untuk ibu menyusui. Aplikasikan setiap pagi, bahkan saat di dalam ruangan.'),
          _ItemDetail(title: 'Vitamin C Serum', desc: 'Gunakan serum Vitamin C 10-15% di pagi hari untuk membantu mencerahkan noda gelap dan melindungi dari radikal bebas.'),
          _ItemDetail(title: 'Niacinamide', desc: 'Bahan ini efektif mereduksi produksi melanin. Cocok digunakan pagi dan malam hari, aman untuk ibu menyusui.'),
          _ItemDetail(title: 'Azelaic Acid', desc: 'Alternatif aman untuk mencerahkan kulit di masa menyusui. Lebih lembut dibanding bahan pemutih lainnya.'),
        ],
        avoid: [
          'Hidroquinon — tidak aman untuk ibu menyusui',
          'Retinol/Tretinoin dosis tinggi tanpa konsultasi dokter',
          'Paparan sinar matahari langsung tanpa perlindungan',
        ],
        tips: 'Hiperpigmentasi pasca melahirkan biasanya membaik sendiri dalam 3-6 bulan setelah melahirkan. Konsisten menggunakan sunscreen adalah kunci utama.',
      ),
    },
    {
      'title': 'Kulit Kering & Dehidrasi',
      'icon': Icons.water_drop_outlined,
      'color': const Color(0xFF3B82F6),
      'content': _buildDetailContent(
        overview: 'Penurunan kadar hormon estrogen setelah melahirkan mengurangi kemampuan kulit mempertahankan kelembaban, menyebabkan kulit terasa kering, kusam, dan kasar.',
        recommendations: [
          _ItemDetail(title: 'Pelembab Hyaluronic Acid', desc: 'Aplikasikan segera setelah mandi saat kulit masih sedikit lembab. Hyaluronic Acid menarik dan mengunci kelembaban hingga 48 jam.'),
          _ItemDetail(title: 'Ceramides', desc: 'Memperkuat skin barrier yang melemah setelah melahirkan. Cari pelembab dengan kandungan Ceramide 1, 3, dan 6-II.'),
          _ItemDetail(title: 'Minyak Alami', desc: 'Rosehip oil, Jojoba oil, atau Argan oil bisa digunakan sebagai lapisan terakhir skincare untuk mengunci kelembaban semalaman.'),
          _ItemDetail(title: 'Konsumsi Air Cukup', desc: 'Minum minimal 2,5–3 liter air per hari. Produksi ASI membutuhkan banyak cairan tubuh, sehingga kebutuhan hidrasi lebih tinggi.'),
        ],
        avoid: [
          'Produk pembersih berbahan SLS (Sodium Lauryl Sulfate) yang bisa membuat kulit semakin kering',
          'Air panas saat mandi — gunakan air hangat suam-suam kuku',
          'Alkohol dalam kandungan toner atau serum',
        ],
        tips: 'Double-cleansing dan rutinitas "Moist & Seal" di malam hari sangat direkomendasikan: pelembab humektan (Hyaluronic Acid) + oklusif (minyak/butter) di atasnya.',
      ),
    },
    {
      'title': 'Jerawat Hormonal',
      'icon': Icons.bubble_chart_rounded,
      'color': const Color(0xFFEF4444),
      'content': _buildDetailContent(
        overview: 'Lonjakan hormon androgen setelah melahirkan dapat memicu produksi minyak berlebih dan menyumbat pori-pori, menyebabkan jerawat di area dagu, rahang, dan pipi.',
        recommendations: [
          _ItemDetail(title: 'Niacinamide 5-10%', desc: 'Mengontrol produksi sebum dan meminimalkan tampilan pori. Aman untuk ibu menyusui dan bisa digunakan pagi-malam.'),
          _ItemDetail(title: 'BHA (Salicylic Acid)', desc: 'Dalam konsentrasi rendah (0.5-2%), BHA aman untuk ibu menyusui dan efektif membersihkan pori dari dalam. Gunakan 2-3x seminggu.'),
          _ItemDetail(title: 'Zinc-based Products', desc: 'Zinc Pyrithione atau Zinc PCA membantu mengontrol minyak dan bersifat antibakteri ringan.'),
          _ItemDetail(title: 'Tea Tree Oil (encapsulated)', desc: 'Sebagai bahan spot treatment alami. Pilih yang sudah dalam bentuk formula produk, jangan langsung dari essential oil murni.'),
        ],
        avoid: [
          'Memencet jerawat — dapat menyebabkan infeksi dan bekas luka',
          'Benzoyl Peroxide dosis tinggi tanpa rekomendasi dokter saat menyusui',
          'Produk yang mengandung minyak berat (coconut oil) di area rentan berjerawat',
        ],
        tips: 'Jaga pola makan rendah gula dan susu tinggi lemak yang dapat memperburuk jerawat hormonal. Pastikan sarung bantal diganti minimal 2x seminggu.',
      ),
    },
    {
      'title': 'Stretch Marks (Striae)',
      'icon': Icons.linear_scale_rounded,
      'color': const Color(0xFF8B5CF6),
      'content': _buildDetailContent(
        overview: 'Stretch marks terbentuk akibat peregangan kulit yang cepat selama kehamilan. Pada awalnya berwarna merah/ungu (striae rubra), lalu memudar menjadi putih keperakan (striae alba).',
        recommendations: [
          _ItemDetail(title: 'Centella Asiatica', desc: 'Membantu merangsang produksi kolagen dan mempercepat regenerasi kulit. Paling efektif digunakan saat stretch marks masih dalam fase merah/ungu.'),
          _ItemDetail(title: 'Rosehip Oil', desc: 'Kaya Vitamin A alami (tretinoin) dan asam lemak omega. Membantu memudarkan warna stretch marks secara bertahap dengan pemakaian rutin.'),
          _ItemDetail(title: 'Shea Butter & Cocoa Butter', desc: 'Melembabkan dan menjaga elastisitas kulit di sekitar area stretch marks. Gunakan secara rutin setiap hari.'),
          _ItemDetail(title: 'Peptida', desc: 'Bahan seperti Matrixyl atau Copper Peptide merangsang produksi kolagen baru untuk memperbaiki tekstur kulit.'),
        ],
        avoid: [
          'Retinol tinggi tanpa konsultasi dokter (terutama saat menyusui)',
          'Menggosok terlalu keras area stretch marks',
          'Berharap hasil instan — perawatan stretch marks membutuhkan waktu 6-12 bulan',
        ],
        tips: 'Pijat ringan area stretch marks dengan minyak alami selama 5-10 menit sehari dapat meningkatkan sirkulasi dan membantu penyerapan bahan aktif.',
      ),
    },
    {
      'title': 'Rutinitas Perawatan Harian',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFF10B981),
      'content': _buildRoutineContent(
        morningSteps: [
          'Cuci wajah dengan gentle cleanser (sabun pH balanced)',
          'Toner/essence hyaluronic acid atau centella',
          'Serum Vitamin C + Niacinamide',
          'Pelembab ringan/gel moisturizer',
          'Sunscreen SPF 30+ (wajib setiap pagi)',
        ],
        nightSteps: [
          'Double cleanse (micellar water + sabun lembut)',
          'Toner pelembab',
          'Treatment serum (AHA/BHA 1-2x seminggu)',
          'Pelembab lebih kaya tekstur / sleeping mask',
          'Facial oil sebagai langkah terakhir (opsional)',
        ],
        bodySteps: [
          'Mandi dengan air suam-suam kuku',
          'Aplikasikan body lotion/oil saat kulit masih lembab',
          'Pijat area stretch marks dengan Rosehip/Centella oil',
          'Tabir surya tubuh jika beraktivitas di luar',
        ],
      ),
    },
  ];

  // ─── CESAREAN DELIVERY CONTENT ──────────────────────────────────────────────

  List<Widget> _buildSesarContent() {
    final sections = _sesarSections();
    return [
      _buildIntroCard(
        title: 'Perawatan Kulit Pasca Lahir Sesar',
        description:
            'Selain perubahan kulit akibat hormon, Ibu yang melahirkan melalui operasi sesar juga perlu perawatan ekstra pada area luka operasi. Panduan ini mencakup perawatan kulit wajah dan luka bekas operasi secara aman.',
        icon: Icons.healing_rounded,
        gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
      ),
      const SizedBox(height: 24),
      ...List.generate(sections.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildExpandableSection(
            index: i,
            title: sections[i]['title'] as String,
            icon: sections[i]['icon'] as IconData,
            color: sections[i]['color'] as Color,
            content: sections[i]['content'] as Widget,
          ),
        );
      }),
    ];
  }

  List<Map<String, dynamic>> _sesarSections() => [
    {
      'title': 'Perawatan Luka Operasi (Fase Awal)',
      'icon': Icons.medical_services_rounded,
      'color': const Color(0xFFEF4444),
      'content': _buildDetailContent(
        overview: 'Luka operasi sesar perlu perawatan ketat terutama pada 6-8 minggu pertama pasca melahirkan. Kebersihan dan kelembaban luka adalah kunci penyembuhan optimal.',
        recommendations: [
          _ItemDetail(title: 'Jaga Kebersihan Luka', desc: 'Bersihkan area luka dengan air bersih dan sabun lembut tanpa parfum. Keringkan dengan menepuk-nepuk (bukan menggosok) menggunakan kain bersih.'),
          _ItemDetail(title: 'Hindari Area Luka dari Air Berlebih', desc: 'Pada 2 minggu pertama, hindari merendam luka di bak mandi. Mandi shower diperbolehkan dengan hati-hati.'),
          _ItemDetail(title: 'Gunakan Pakaian Berbahan Katun', desc: 'Pilih pakaian longgar berbahan katun 100% untuk mengurangi gesekan dan iritasi pada area luka.'),
          _ItemDetail(title: 'Pantau Tanda Infeksi', desc: 'Segera konsultasi dokter jika luka menjadi panas, bengkak berlebihan, bernanah, berbau tidak sedap, atau demam muncul.'),
        ],
        avoid: [
          'Mengaplikasikan produk apapun (losion, minyak, dll) ke luka yang belum menutup sempurna',
          'Memakai pakaian ketat atau celana dengan pinggang tinggi yang menekan area luka',
          'Beraktivitas berat dalam 4-6 minggu pertama',
          'Paparan sinar matahari langsung pada area luka',
        ],
        tips: 'Posisikan bantal kecil di atas perut saat batuk atau bersin untuk mengurangi tekanan pada luka dan membantu mengurangi rasa nyeri.',
      ),
    },
    {
      'title': 'Perawatan Bekas Luka Sesar',
      'icon': Icons.healing_rounded,
      'color': const Color(0xFF8B5CF6),
      'content': _buildDetailContent(
        overview: 'Setelah luka menutup sempurna (biasanya 6-8 minggu), Ibu bisa mulai perawatan bekas luka sesar untuk meminimalkan keloid, perubahan warna, dan tekstur kulit yang tidak rata.',
        recommendations: [
          _ItemDetail(title: 'Silicone Gel / Sheet', desc: 'Terbukti secara klinis sebagai metode terbaik mengurangi bekas luka. Gunakan silicone sheet 12-24 jam/hari selama minimal 3 bulan setelah luka benar-benar menutup.'),
          _ItemDetail(title: 'Centella Asiatica Oil/Cream', desc: 'Merangsang produksi kolagen normal dan mengurangi inflamasi. Pijat lembut 2x sehari selama 5 menit setelah luka menutup.'),
          _ItemDetail(title: 'Vitamin E Oil', desc: 'Melembabkan area sekitar bekas luka dan membantu mengurangi ketegangan kulit. Oleskan secara melingkar dengan tekanan ringan.'),
          _ItemDetail(title: 'Onion Extract Gel', desc: 'Tersedia dalam produk seperti Contractubex®. Efektif untuk mengurangi jaringan parut dan membantu meratakan tekstur bekas luka.'),
        ],
        avoid: [
          'Menggaruk atau mengelupas kerak pada bekas luka',
          'Paparan sinar matahari tanpa perlindungan penuh (bekas luka sangat mudah hiperpigmentasi)',
          'Menggunakan essential oil murni langsung pada bekas luka',
          'Memulai perawatan sebelum luka benar-benar menutup',
        ],
        tips: 'Pijat bekas luka dengan gerakan melingkar secara bertahap, dengan tekanan yang makin meningkat seiring waktu. Ini membantu memecah jaringan fibrosa dan meningkatkan fleksibilitas kulit.',
      ),
    },
    {
      'title': 'Hiperpigmentasi Pasca Sesar',
      'icon': Icons.brightness_3_rounded,
      'color': const Color(0xFFF59E0B),
      'content': _buildDetailContent(
        overview: 'Selain bekas luka, wanita pasca sesar juga mengalami hiperpigmentasi sama seperti ibu yang lahir normal — terutama linea nigra (garis gelap di perut), melasma di wajah, dan pigmentasi di area ketiak & selangkangan.',
        recommendations: [
          _ItemDetail(title: 'Sunscreen Wajib di Area Bekas Luka', desc: 'Bekas luka yang terkena sinar UV dapat menjadi lebih gelap permanen. Gunakan sunscreen physical (mineral) minimal SPF 50 di area tersebut.'),
          _ItemDetail(title: 'Azelaic Acid untuk Wajah', desc: 'Aman saat menyusui, efektif untuk melasma dan noda gelap. Gunakan konsentrasi 10-20% di malam hari.'),
          _ItemDetail(title: 'Vitamin C + Niacinamide', desc: 'Kombinasi ini membantu mencerahkan noda gelap di seluruh area, aman digunakan pagi hari bersamaan dengan sunscreen.'),
          _ItemDetail(title: 'Liniment Olie/Minyak Khusus Perut', desc: 'Produk berbahan centella atau rosehip untuk area perut dapat membantu memudarkan linea nigra secara bertahap.'),
        ],
        avoid: [
          'Hidroquinon dan Mercury — sangat berbahaya untuk ibu menyusui',
          'Laser/IPL tanpa konsultasi spesialis kulit',
          'Produk pemutih kulit berbahan tidak jelas',
        ],
        tips: 'Linea nigra biasanya memudar sendiri dalam 6-12 bulan pasca melahirkan tanpa perawatan khusus. Konsistensi penggunaan sunscreen adalah langkah paling penting.',
      ),
    },
    {
      'title': 'Stretch Marks Pasca Sesar',
      'icon': Icons.linear_scale_rounded,
      'color': const Color(0xFF10B981),
      'content': _buildDetailContent(
        overview: 'Perawatan stretch marks pada ibu sesar sama dengan ibu lahir normal, namun perlu ekstra hati-hati dalam mengaplikasikan produk di sekitar area luka operasi.',
        recommendations: [
          _ItemDetail(title: 'Fokus pada Area yang Aman', desc: 'Perlakukan stretch marks di area paha, pinggul, dan payudara terlebih dahulu. Hindari area perut dekat luka sampai benar-benar sembuh.'),
          _ItemDetail(title: 'Centella Asiatica Body Butter', desc: 'Aplikasikan pada area stretch marks jauh dari area luka operasi. Massase lembut membantu penyerapan dan sirkulasi.'),
          _ItemDetail(title: 'Peptide-based Serum', desc: 'Serum dengan kandungan peptida seperti Matrixyl atau Argireline merangsang regenerasi kolagen secara aman.'),
          _ItemDetail(title: 'Timing yang Tepat', desc: 'Mulai perawatan stretch marks di area perut hanya setelah luka operasi benar-benar menutup dan tidak ada rasa nyeri (biasanya 8-12 minggu pasca operasi).'),
        ],
        avoid: [
          'AHA/BHA di area dekat luka operasi',
          'Produk dengan alkohol atau parfum kuat di area sensitif',
          'Tekanan atau gosokan keras di area perut dalam 3 bulan pertama',
        ],
        tips: 'Sabar adalah kunci. Fokus pada pemulihan tubuh menyeluruh terlebih dahulu. Stretch marks dan bekas luka membutuhkan waktu, namun dengan perawatan konsisten hasilnya akan terlihat signifikan dalam 6-12 bulan.',
      ),
    },
    {
      'title': 'Kulit Kering & Jerawat Hormonal',
      'icon': Icons.face_rounded,
      'color': const Color(0xFF3B82F6),
      'content': _buildDetailContent(
        overview: 'Perubahan hormon pasca sesar serupa dengan pasca lahir normal. Kulit kering akibat penurunan estrogen dan jerawat hormonal akibat androgen sama-sama perlu diperhatikan.',
        recommendations: [
          _ItemDetail(title: 'Gentle Cleanser', desc: 'Gunakan sabun cuci muka pH 4.5-5.5 tanpa SLS, tanpa pewangi. Bersihkan 2x sehari, tidak lebih, agar skin barrier tetap terjaga.'),
          _ItemDetail(title: 'Hyaluronic Acid + Ceramide', desc: 'Kombinasi terbaik untuk kulit kering pasca melahirkan. HA menarik kelembaban, ceramide mengunci agar tidak menguap.'),
          _ItemDetail(title: 'Niacinamide 5%', desc: 'Multifungsi: mengontrol minyak, mereduksi jerawat hormonal, dan membantu mencerahkan noda bekas jerawat. Aman untuk ibu menyusui.'),
          _ItemDetail(title: 'Zinc Supplement', desc: 'Suplemen zinc dengan dosis aman (konsultasi dokter) dapat membantu mengurangi jerawat hormonal dari dalam.'),
        ],
        avoid: [
          'Adaptasi produk terlalu banyak sekaligus — pilih maksimal 3-4 produk terlebih dahulu',
          'Over-exfoliating — batasi eksfoliasi 1-2x seminggu',
          'Skincare berparfum kuat di area yang bersentuhan dengan bayi',
        ],
        tips: 'Jika menyusui, pastikan produk skincare yang Anda gunakan tidak menempel berlebihan di area payudara/puting. Bersihkan sebelum menyusui jika menggunakan produk di sekitar area tersebut.',
      ),
    },
    {
      'title': 'Rutinitas Perawatan Harian (Sesar)',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFF22C55E),
      'content': _buildRoutineContent(
        morningSteps: [
          'Cuci wajah dengan gentle pH-balanced cleanser',
          'Toner/essence centella asiatica untuk healing',
          'Serum Vitamin C (wajah) + Azelaic Acid (titik gelap)',
          'Pelembab ringan dengan Ceramide',
          'Sunscreen SPF 50 wajah + area bekas luka (setelah menutup)',
        ],
        nightSteps: [
          'Micellar water untuk membersihkan makeup/sunscreen',
          'Sabun lembut tanpa SLS',
          'Niacinamide serum untuk kontrol minyak & jerawat',
          'Pelembab kaya Hyaluronic Acid + Ceramide',
          'Silicone gel pada bekas luka (jika sudah menutup)',
        ],
        bodySteps: [
          'Shower air hangat (bukan panas), maksimal 10-15 menit',
          'Pat dry luka dengan handuk bersih kering',
          'Body lotion pada area tubuh jauh dari luka',
          'Centella oil pada stretch marks (area aman)',
          'Silicone sheet pada bekas luka setelah kering (sesuai panduan dokter)',
        ],
      ),
    },
  ];

  // ─── SHARED WIDGETS ─────────────────────────────────────────────────────────

  Widget _buildIntroCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.3)),
                const SizedBox(height: 10),
                Text(description,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 48),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required int index,
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    final isExpanded = _expandedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isExpanded ? 0.95 : 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isExpanded ? color.withOpacity(0.3) : Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isExpanded ? color.withOpacity(0.1) : Colors.black.withOpacity(0.03),
              blurRadius: isExpanded ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F1235))),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? color : Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Divider(color: color.withOpacity(0.15), height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: content,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent({
    required String overview,
    required List<_ItemDetail> recommendations,
    required List<String> avoid,
    required String tips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1235).withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(overview,
              style: TextStyle(
                  fontSize: 13, height: 1.6, color: const Color(0xFF1F1235).withOpacity(0.75), fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 20),
        _labelText('Rekomendasi Perawatan', const Color(0xFF10B981)),
        const SizedBox(height: 12),
        ...recommendations.map((item) => _buildRecommendItem(item)),
        const SizedBox(height: 16),
        _labelText('Yang Perlu Dihindari', const Color(0xFFEF4444)),
        const SizedBox(height: 10),
        ...avoid.map((a) => _buildAvoidItem(a)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(tips,
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, fontWeight: FontWeight.w500, color: Color(0xFF92400E))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineContent({
    required List<String> morningSteps,
    required List<String> nightSteps,
    required List<String> bodySteps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText('🌅 Rutinitas Pagi', const Color(0xFFF59E0B)),
        const SizedBox(height: 10),
        ...morningSteps.asMap().entries.map((e) => _buildStepItem(e.key + 1, e.value)),
        const SizedBox(height: 16),
        _labelText('🌙 Rutinitas Malam', const Color(0xFF8B5CF6)),
        const SizedBox(height: 10),
        ...nightSteps.asMap().entries.map((e) => _buildStepItem(e.key + 1, e.value)),
        const SizedBox(height: 16),
        _labelText('🛁 Perawatan Tubuh', const Color(0xFF3B82F6)),
        const SizedBox(height: 10),
        ...bodySteps.asMap().entries.map((e) => _buildStepItem(e.key + 1, e.value)),
      ],
    );
  }

  Widget _labelText(String label, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: color, margin: const EdgeInsets.only(right: 8)),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildRecommendItem(_ItemDetail item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F1235))),
            const SizedBox(height: 4),
            Text(item.desc,
                style: TextStyle(fontSize: 12, height: 1.5, color: const Color(0xFF1F1235).withOpacity(0.65))),
          ],
        ),
      ),
    );
  }

  Widget _buildAvoidItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13, height: 1.4, color: const Color(0xFF1F1235).withOpacity(0.7))),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$number',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13, height: 1.4, color: const Color(0xFF1F1235).withOpacity(0.75))),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDetail {
  final String title;
  final String desc;
  const _ItemDetail({required this.title, required this.desc});
}
