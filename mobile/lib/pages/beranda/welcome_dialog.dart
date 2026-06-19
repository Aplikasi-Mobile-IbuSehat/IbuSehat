import 'package:flutter/material.dart';

class WelcomeDialog extends StatelessWidget {
  const WelcomeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85, 
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BAGIAN HEADER
            Container(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Icon Hati & Tombol Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFA855F7), // purple-500
                              Color(0xFFF472B6), // pink-400
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.favorite, color: Colors.white, size: 26),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6), // gray-100
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20, color: Color(0xFF4B5563)), // gray-600
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Yuk, mulai langkah penting untuk menjaga kesehatan ibu setelah melahirkan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Temukan panduan lengkap untuk pemulihan pasca melahirkan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280), // gray-500
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.grey.shade200,
              thickness: 1,
              height: 1,
            ),
            
            // BAGIAN KONTEN (SCROLLABLE LIST KARTU)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildFeatureCard(
                        icon: Icons.show_chart_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        bgColor: const Color(0xFFF5F3FF),
                        title: 'Olahraga',
                        description: 'Aktivitas fisik ringan membantu pemulihan pasca melahirkan. Mulai dengan gerakan sederhana dan tingkatkan intensitas secara bertahap.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        icon: Icons.restaurant_menu_rounded,
                        iconColor: const Color(0xFFF43F5E),
                        bgColor: const Color(0xFFFFF1F2),
                        title: 'Nutrisi & Diet',
                        description: 'Kebutuhan kalori harian sekitar 2300-2500 kkal untuk mendukung pemulihan dan menyusui. Fokus pada protein, zat besi, kalsium, dan hidrasi.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        icon: Icons.spa_rounded,
                        iconColor: const Color(0xFFD946EF),
                        bgColor: const Color(0xFFFDF4FF),
                        title: 'Perawatan Kulit',
                        description: 'Perubahan hormon mempengaruhi kondisi kulit. Gunakan produk yang aman dan jaga kelembaban kulit Anda.',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: const Color(0xFFF43F5E),
                        bgColor: const Color(0xFFFFF1F2),
                        title: 'Asisten Chatbot',
                        description: 'Fitur untuk bertanya dan mendapat panduan berguna kapan saja. Konsultasi kesehatan Anda dengan mudah.',
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            
            // BAGIAN TOMBOL BAWAH
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _buildGradientButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1), // Warna ungu-biru solid dari gambar
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha:0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mulai Perjalanan Sehat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.favorite, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    Color? iconColor,
    Gradient? iconGradient,
    required Color bgColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconGradient == null ? iconColor : null,
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (iconColor != null)
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1235),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
