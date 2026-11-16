import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/pages/chatbot/chatbot_page.dart';
import 'package:mobile/widgets/health_gate.dart';

// ---------------------------------------------------------------------------
// AppHeaderActions
// Tombol chatbot di header halaman utama.
// Chatbot memakai data kesehatan; jika belum lengkap → popup akses fitur
// lalu halaman Data Kesehatan.
// ---------------------------------------------------------------------------
class AppHeaderActions extends StatelessWidget {
  const AppHeaderActions({
    super.key,
    required this.titleColor,
    this.showChatbot = true,
  });

  final Color titleColor;
  final bool showChatbot;

  @override
  Widget build(BuildContext context) {
    if (!showChatbot) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: SvgPicture.asset(
          'assets/icons/message_circle.svg',
          colorFilter: ColorFilter.mode(titleColor, BlendMode.srcIn),
          width: 24,
          height: 24,
        ),
        onPressed: () => HealthGate.open(context, (_) => const ChatbotPage()),
      ),
    );
  }
}
