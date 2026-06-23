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

    if (err != null && err.isEmpty) return;

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

    await AuthService.instance.syncUserFromApi();

    final user = await AuthService.instance.currentUser;
    if (!mounted) return;

    final isDone = user?.isOnboardingDone ?? false;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isDone
            ? const MainPage()
            : const OnboardingPage(),
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
          Positioned.fill(
            child: CustomPaint(painter: _AuroraPainter()),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/logo/ibusehat_logo_transparent.webp',
                      width: 100,
                      height: 100,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Welcome to IbuSehat',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1235),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Pendamping kesehatan ibu pasca melahirkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 40),

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
                          : Image.asset('assets/icons/google.webp', height: 20),
                      label: Text(_busy ? 'Memproses...' : 'Continue with Google'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
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

// Aurora background

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
          const Color(0xFFD4AAFF).withValues(alpha: 0.75),
          const Color(0xFFE8CCFF).withValues(alpha: 0.0),
        ]);
    _drawBlob(canvas,
        center: Offset(w * 0.82, h * 0.05),
        radiusX: w * 0.40,
        radiusY: h * 0.20,
        colors: [
          const Color(0xFFF4AAEE).withValues(alpha: 0.65),
          const Color(0xFFFCDDFF).withValues(alpha: 0.0),
        ]);
    _drawBlob(canvas,
        center: Offset(w * 0.15, h * 0.08),
        radiusX: w * 0.36,
        radiusY: h * 0.18,
        colors: [
          const Color(0xFFAADDFF).withValues(alpha: 0.55),
          const Color(0xFFCCEEFF).withValues(alpha: 0.0),
        ]);
    _drawBlob(canvas,
        center: Offset(w * 0.48, h * 0.16),
        radiusX: w * 0.26,
        radiusY: h * 0.13,
        colors: [
          const Color(0xFFBB88FF).withValues(alpha: 0.55),
          const Color(0xFFCC99FF).withValues(alpha: 0.0),
        ]);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.88),
          ],
          stops: const [0.2, 0.5],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  void _drawBlob(Canvas canvas,
      {required Offset center,
      required double radiusX,
      required double radiusY,
      required List<Color> colors}) {
    final paint = Paint()
      ..shader = RadialGradient(colors: colors)
          .createShader(Rect.fromCenter(
        center: center,
        width: radiusX * 2,
        height: radiusY * 2,
      ));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, radiusY / radiusX);
    canvas.drawCircle(Offset.zero, radiusX, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
