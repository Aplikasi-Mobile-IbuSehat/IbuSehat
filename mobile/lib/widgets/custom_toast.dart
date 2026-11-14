import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/pages/main_page.dart';

class ToastData {
  final String message;
  final bool isError;
  final DateTime timestamp; // Untuk memastikan update selalu ter-trigger meskipun pesan sama

  ToastData({
    required this.message,
    this.isError = false,
  }) : timestamp = DateTime.now();
}

class CustomToast {
  static OverlayEntry? _currentEntry;
  static final ValueNotifier<ToastData?> toastNotifier = ValueNotifier(null);

  static void show(BuildContext context, String message, {bool isError = false}) {
    // Cek apakah MainPage ada di ancestor widget tree, atau context ini sendiri adalah MainPage
    final hasMainPageAncestor = context.widget is MainPage || 
                                context.findAncestorWidgetOfExactType<MainPage>() != null;

    if (hasMainPageAncestor) {
      // Jika di dalam MainPage, kirim data via notifier agar MainPage yang menampilkan di belakang navbar
      toastNotifier.value = ToastData(message: message, isError: isError);
    } else {
      // Jika di luar MainPage (misal ChatbotPage, PremiumPage), tampilkan via Overlay
      _currentEntry?.remove();
      _currentEntry = null;

      final overlay = Overlay.of(context);
      
      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 97, // Tampil mengambang di atas area navbar
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: CustomToastWidget(
              message: message,
              isError: isError,
              onDismissed: () {
                if (_currentEntry == overlayEntry) {
                  _currentEntry?.remove();
                  _currentEntry = null;
                }
              },
            ),
          ),
        ),
      );

      _currentEntry = overlayEntry;
      overlay.insert(overlayEntry);
    }
  }
}

class CustomToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismissed;

  const CustomToastWidget({
    super.key,
    required this.message,
    this.isError = false,
    required this.onDismissed,
  });

  @override
  State<CustomToastWidget> createState() => _CustomToastWidgetState();
}

class _CustomToastWidgetState extends State<CustomToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _controller.forward();

    // Auto dismiss setelah 2.5 detik
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Warna dasar mengikuti tema, dengan slight alpha
    Color bgColor = (isDark ? darkSurface : lightSurface).withValues(alpha: 0.9);
    
    // Jika error, gunakan warna merah sebagai background
    if (widget.isError) {
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.9);
    }

    final textColor = widget.isError 
        ? Colors.white 
        : (isDark ? darkTextPrimary : lightTextPrimary);

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.5), // Animasi muncul dari bawah
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isError 
                  ? Colors.redAccent.withValues(alpha: 0.5)
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (widget.isError) ...[
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
