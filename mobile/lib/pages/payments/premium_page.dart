import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/pages/payments/midtrans_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/api_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  // index 0 = 1 Bulan, index 1 = 11 Bulan (default terpilih: paling hemat)
  int _selectedPlanIndex = 1;
  bool _isProcessing = false;

  final ApiService _apiService = ApiService();

  final List<Map<String, dynamic>> _plans = [
    {
      'type': '1M',
      'title': '1 Bulan',
      'price': 'Rp 39.000',
      'period': '/bulan',
      'badge': null,
      'subtitle': 'Nikmati semua fitur premium selama 30 hari',
    },
    {
      'type': '11M',
      'title': '11 Bulan',
      'price': 'Rp 349.000',
      'period': '/11 bulan',
      'badge': 'Hemat 2 Bulan',
      'subtitle': 'Setara Rp 31.700/bulan',
    },
  ];

  final List<Map<String, dynamic>> _benefits = [
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'AI Chatbot',
      'desc': 'Akses asisten AI canggih, Catat makanan & suplement otomatis lewat chat',
    },
    {
      'icon': Icons.fitness_center_rounded,
      'title': 'Program latihan khusus',
      'desc': 'Akses penuh koleksi video olahraga',
    },
    {
      'icon': Icons.share_rounded,
      'title': 'Share Tracking',
      'desc': 'Bagikan aktivitas dan pencapaian kesehatan Anda dengan mudah',
    },
  ];

  Future<void> _handlePayment() async {
    final token = await AuthService.instance.token;

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi habis, silakan login ulang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedPlan = _plans[_selectedPlanIndex];
    final planType = selectedPlan['type'] as String;

    setState(() => _isProcessing = true);

    try {
      // Backend menentukan harga & durasi berdasarkan plan_type (audit trail
      // tercatat di tabel payments), Flutter tidak mengirim nominal manual.
      final tx = await _apiService.createPremiumTransaction(planType);

      if (!mounted) return;

      final snapToken = tx['snap_token'] as String;
      final clientKey = tx['client_key'] as String;

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            snapToken: snapToken,
            clientKey: clientKey,
          ),
        ),
      );

      if (!mounted) return;

      switch (result) {
        case 'success':
          await AuthService.instance.syncUserFromApi();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil! Terima kasih telah berlangganan.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          break;
        case 'pending':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran sedang diproses'),
              backgroundColor: Colors.orange,
            ),
          );
          break;
        case 'error':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran gagal, coba lagi'),
              backgroundColor: Colors.red,
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ibusehat Premium',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero badge
                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.asset(
                          'assets/logo/ibusehat_logo_transparent.webp',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Jadi Member Premium',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dirancang untuk mendukung setiap langkah pemulihan pasca melahirkan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Pricing cards (side by side, gaya app membership)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(_plans.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 8,
                              right: index == _plans.length - 1 ? 0 : 8,
                            ),
                            child: _buildPricingCard(
                              index: index,
                              plan: _plans[index],
                              isSelected: _selectedPlanIndex == index,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 36),

                    // Benefits
                    Text(
                      'Benefit yang Kamu Dapatkan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: List.generate(_benefits.length, (i) {
                          final b = _benefits[i];
                          return _buildBenefitItem(
                            icon: b['icon'] as IconData,
                            title: b['title'] as String,
                            desc: b['desc'] as String,
                            isLast: i == _benefits.length - 1,
                          );
                        }),
                      ),
                    ),

                  ],
                ),
              ),

              // Sticky CTA di bawah (Floating)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  color: Colors.transparent,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _handlePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Lanjutkan • ${_plans[_selectedPlanIndex]['price']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String desc,
    required bool isLast,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: border.withValues(alpha: 0.6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required int index,
    required Map<String, dynamic> plan,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;
    final badge = plan['badge'] as String?;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0x228B5CF6) : const Color(0xFFF5F3FF))
                  : surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6))
                    : border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? (isDark ? const Color(0x2A8B5CF6) : const Color(0xFF8B5CF6).withValues(alpha: 0.15))
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isSelected ? 16 : 6,
                  offset: Offset(0, isSelected ? 8 : 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6))
                            : textSecondary,
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6))
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6))
                              : (isDark ? darkBorder : Colors.grey.shade300),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  plan['price'] as String,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  plan['period'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Badge "Hemat 2 Bulan" - posisi melayang di atas card
          if (badge != null)
            Positioned(
              top: -10,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}