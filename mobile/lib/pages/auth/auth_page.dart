import 'package:flutter/material.dart';
import 'package:mobile/pages/main_page.dart';
import 'package:mobile/pages/onboarding/onboarding_page.dart';
import 'package:mobile/services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _busy = false;

  Future<void> _onGooglePressed() async {
    if (_busy) return;
    setState(() => _busy = true);

    final err = await AuthService.instance.signInWithGoogle();

    if (!mounted) return;
    setState(() => _busy = false);

    // '' = user batal → diam saja
    if (err != null && err.isEmpty) return;

    // string error → tampilkan SnackBar
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // null = sukses → cek apakah sudah pernah onboarding
    final onboardingDone = await AuthService.instance.isOnboardingDone;
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            onboardingDone ? const MainPage() : const OnboardingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // ── Aurora Background ──
          Positioned.fill(
            child: CustomPaint(painter: _AuroraPainter()),
          ),

          // ── Konten ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB084F5).withOpacity(0.25),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: const Center(
                        // Ganti dengan: Image.asset('assets/icons/logo.png', ...)
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 60,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Welcome to Ibu Sehat',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1235),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Pendamping kesehatan ibu pasca melahirkan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // ── Tombol Google ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _onGooglePressed,
                      icon: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Image.asset(
                              'assets/icons/google.webp',
                              height: 20,
                            ),
                      label: Text(
                        _busy ? 'Memproses...' : 'Continue with Google',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.withOpacity(0.25)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Aurora Painter ─────────────────────────────────────────────────────────────
class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final w = size.width;
    final h = size.height;

    _drawBlob(canvas,
        center: Offset(w * 0.5, h * 0.10),
        radiusX: w * 0.55,
        radiusY: h * 0.25,
        colors: [
          const Color(0xFFD4AAFF).withOpacity(0.75),
          const Color(0xFFE8CCFF).withOpacity(0.0),
        ]);
    _drawBlob(canvas,
        center: Offset(w * 0.82, h * 0.05),
        radiusX: w * 0.40,
        radiusY: h * 0.20,
        colors: [
          const Color(0xFFF4AAEE).withOpacity(0.65),
          const Color(0xFFFCDDFF).withOpacity(0.0),
        ]);
    _drawBlob(canvas,
        center: Offset(w * 0.15, h * 0.08),
        radiusX: w * 0.36,
        radiusY: h * 0.18,
        colors: [
          const Color(0xFFAADDFF).withOpacity(0.55),
          const Color(0xFFCCEEFF).withOpacity(0.0),
        ]);
    _drawBlob(canvas,
        center: Offset(w * 0.48, h * 0.16),
        radiusX: w * 0.26,
        radiusY: h * 0.13,
        colors: [
          const Color(0xFFBB88FF).withOpacity(0.55),
          const Color(0xFFCC99FF).withOpacity(0.0),
        ]);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.88),
          ],
          stops: const [0.20, 0.50],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  void _drawBlob(Canvas canvas,
      {required Offset center,
      required double radiusX,
      required double radiusY,
      required List<Color> colors}) {
    final paint = Paint()
      ..shader = RadialGradient(colors: colors, stops: const [0.0, 1.0])
          .createShader(Rect.fromCenter(
              center: center, width: radiusX * 2, height: radiusY * 2));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, radiusY / radiusX);
    canvas.drawCircle(Offset.zero, radiusX, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => false;
}