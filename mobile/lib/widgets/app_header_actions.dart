import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/pages/chatbot/chatbot_page.dart';
import 'package:mobile/pages/payments/premium_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Helper internal: ikon sparkles yang bisa di-tap untuk membuka PremiumPage.
// Tidak perlu State sendiri — cukup GestureDetector di dalam ValueListenableBuilder.
// ---------------------------------------------------------------------------
Widget _buildSparklesIcon(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(right: 8.0),
    child: GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumPage()),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ShaderMask(
          shaderCallback: (Rect bounds) => buttonGradient.createShader(bounds),
          child: SvgPicture.asset(
            'assets/icons/sparkles_premium.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// AppHeaderPremiumIcon
// Ditampilkan di pojok kanan header; hilang otomatis ketika user jadi premium.
// ---------------------------------------------------------------------------
class AppHeaderPremiumIcon extends StatelessWidget {
  const AppHeaderPremiumIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) {
        // Sembunyikan jika sudah premium atau data belum dimuat.
        final isPremium = user?.isPremium ?? AuthService.instance.isPremiumSync;
        if (isPremium) return const SizedBox.shrink();

        return _buildSparklesIcon(context);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// AppHeaderActions
// Tombol premium + chatbot di header halaman utama.
// Chatbot hanya untuk premium; non-premium diarahkan ke PremiumPage.
// ---------------------------------------------------------------------------
class AppHeaderActions extends StatelessWidget {
  const AppHeaderActions({
    super.key,
    required this.titleColor,
    this.showChatbot = true,
  });

  final Color titleColor;
  final bool showChatbot;

  void _openChatbot(BuildContext context, bool isPremium) {
    final route = isPremium
        ? MaterialPageRoute(builder: (_) => const ChatbotPage())
        : MaterialPageRoute(builder: (_) => const PremiumPage());
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) {
        final isPremium = user?.isPremium ?? AuthService.instance.isPremiumSync;
        final showPremiumIcon = !isPremium;

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            children: [
              if (showPremiumIcon) ...[
                _buildSparklesIcon(context),
                if (showChatbot) const SizedBox(width: 8),
              ],
              if (showChatbot)
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/message_circle.svg',
                    colorFilter: ColorFilter.mode(
                      titleColor,
                      BlendMode.srcIn,
                    ),
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () => _openChatbot(context, isPremium),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PremiumSparklesInlineIcon
// Ikon sparkles inline (mis. di judul AppBar chatbot).
// Disembunyikan jika user sudah premium.
// ---------------------------------------------------------------------------
class PremiumSparklesInlineIcon extends StatelessWidget {
  const PremiumSparklesInlineIcon({
    super.key,
    this.size = 16,
    this.color = const Color(0xFF8B5CF6),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: AuthService.instance.userNotifier,
      builder: (context, user, _) {
        final isPremium = user?.isPremium ?? AuthService.instance.isPremiumSync;
        if (isPremium) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/sparkles_premium.svg',
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
