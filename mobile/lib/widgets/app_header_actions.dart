import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/pages/chatbot/chatbot_page.dart';
import 'package:mobile/pages/payments/premium_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_colors.dart';

/// Tombol premium + chatbot di header halaman utama.
/// Chatbot hanya untuk premium; non-premium diarahkan ke [PremiumPage].
class AppHeaderActions extends StatefulWidget {
  const AppHeaderActions({
    super.key,
    required this.titleColor,
  });

  final Color titleColor;

  @override
  State<AppHeaderActions> createState() => _AppHeaderActionsState();
}

class _AppHeaderActionsState extends State<AppHeaderActions> {
  late bool _isPremium;
  late bool _statusLoaded;

  @override
  void initState() {
    super.initState();
    final cached = AuthService.instance.cachedUserSync;
    _statusLoaded = cached != null;
    _isPremium = cached?.isPremium ?? false;

    if (!_statusLoaded) {
      _loadFromCache();
    }
    _syncPremiumInBackground();
  }

  Future<void> _loadFromCache() async {
    final user = await AuthService.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _isPremium = user?.isPremium ?? false;
      _statusLoaded = true;
    });
  }

  Future<void> _syncPremiumInBackground() async {
    if (!await AuthService.instance.isLoggedIn) return;
    await AuthService.instance.syncUserFromApi();
    final user = await AuthService.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _isPremium = user?.isPremium ?? false;
      _statusLoaded = true;
    });
  }

  void _openChatbot() {
    final route = _isPremium
        ? MaterialPageRoute(builder: (_) => const ChatbotPage())
        : MaterialPageRoute(builder: (_) => const PremiumPage());
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    final showPremiumIcon = _statusLoaded && !_isPremium;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        children: [
          if (showPremiumIcon) ...[
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PremiumPage()),
                );
                if (mounted) {
                  final user = AuthService.instance.cachedUserSync;
                  if (user != null) {
                    setState(() {
                      _isPremium = user.isPremium;
                      _statusLoaded = true;
                    });
                  }
                  _syncPremiumInBackground();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return buttonGradient.createShader(bounds);
                  },
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
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/message_circle.svg',
              colorFilter: ColorFilter.mode(
                widget.titleColor,
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
            onPressed: _openChatbot,
          ),
        ],
      ),
    );
  }
}

/// Ikon sparkles inline (mis. di judul AppBar chatbot).
/// Disembunyikan jika user sudah premium.
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
    if (AuthService.instance.isPremiumSync) return const SizedBox.shrink();

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
  }
}
