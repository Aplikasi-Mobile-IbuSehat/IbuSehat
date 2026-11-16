import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/pages/main_page.dart';
import 'package:mobile/pages/onboarding/onboarding_page.dart';
import 'package:mobile/services/auth_service.dart';

import 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button_web.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _busy = false;

  // ── WEB (aktif) ───────────────────────────────────────────────────────
  // Di browser tombol login dirender oleh Google Identity Services, dan
  // hasilnya datang lewat stream event — bukan lewat onPressed biasa.
  bool _googleReady = false;
  String? _googleInitError;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _initGoogleWeb();
  }

  @override
  void dispose() {
    _googleSub?.cancel();
    super.dispose();
  }

  Future<void> _initGoogleWeb() async {
    try {
      await AuthService.instance.initGoogleSignInWeb();
    } catch (e) {
      if (!mounted) return;
      setState(() => _googleInitError = 'Gagal menyiapkan Google Sign-In.');
      debugPrint('Google Sign-In init error: $e');
      return;
    }

    _googleSub = AuthService.instance.googleAuthEvents.listen(
      _onGoogleAuthEvent,
      onError: _onGoogleAuthError,
    );

    if (mounted) setState(() => _googleReady = true);
  }

  Future<void> _onGoogleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    if (_busy || !mounted) return;
    setState(() => _busy = true);

    final result = await AuthService.instance.signInWithGoogleAccount(
      event.user,
    );

    if (!mounted) return;
    await _handleAuthResult(result);
  }

  void _onGoogleAuthError(Object error) {
    if (!mounted) return;
    final cancelled = error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled;
    _handleAuthResult(
      cancelled
          ? const AuthCancelled()
          : const AuthFailure('Google Sign-In gagal. Coba lagi.'),
    );
  }

  Future<void> _handleAuthResult(AuthResult result) async {
    switch (result) {
      case AuthCancelled():
        setState(() => _busy = false);
        return;

      case AuthFailure(:final message):
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;

      case AuthSuccess():
        await AuthService.instance.syncUserFromApi();
        final user = await AuthService.instance.currentUser;
        if (!mounted) return;

        setState(() => _busy = false);

        final isDone = user?.isOnboardingDone ?? false;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => isDone ? const MainPage() : const OnboardingPage(),
          ),
        );
        return;
    }
  }

  Widget _buildGoogleButton() {
    if (!kIsWeb) {
      return Center(
        child: Text(
          'Login Google untuk mobile sedang dinonaktifkan.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      );
    }

    if (_googleInitError != null) {
      return Center(
        child: Text(
          _googleInitError!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.red.shade700),
        ),
      );
    }

    if (_busy || !_googleReady) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F1F1F)),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Lebar tombol Google dibatasi 200–400 px oleh Google.
        final width = constraints.maxWidth.clamp(200.0, 400.0);
        return Center(child: buildGoogleWebButton(minimumWidth: width));
      },
    );
  }

  // ── MOBILE (Android/iOS) — dinonaktifkan sementara, JANGAN DIHAPUS ────
  // Untuk mengaktifkan lagi: buka komentar method ini, tombol MOBILE di
  // build(), dan AuthService.signInWithGoogle().
  //
  // Future<void> _onGooglePressed() async {
  //   if (_busy) return;
  //   setState(() => _busy = true);
  //
  //   final result = await AuthService.instance.signInWithGoogle();
  //
  //   if (!mounted) return;
  //
  //   switch (result) {
  //     case AuthCancelled():
  //       setState(() => _busy = false);
  //       return;
  //
  //     case AuthFailure(:final message):
  //       setState(() => _busy = false);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(message),
  //           backgroundColor: Colors.red.shade700,
  //           behavior: SnackBarBehavior.floating,
  //         ),
  //       );
  //       return;
  //
  //     case AuthSuccess():
  //       await AuthService.instance.syncUserFromApi();
  //       final user = await AuthService.instance.currentUser;
  //       if (!mounted) return;
  //
  //       setState(() => _busy = false);
  //
  //       final isDone = user?.isOnboardingDone ?? false;
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => isDone ? const MainPage() : const OnboardingPage(),
  //         ),
  //       );
  //       return;
  //   }
  // }

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
          Positioned.fill(child: CustomPaint(painter: _AuroraPainter())),
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
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 40),
                  // ── WEB (aktif): tombol resmi Google Identity Services ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _buildGoogleButton(),
                  ),
                  // ── MOBILE (Android/iOS) — dinonaktifkan sementara,
                  //    JANGAN DIHAPUS. Tombol asli login Google mobile. ──
                  //
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 54,
                  //   child: OutlinedButton.icon(
                  //     onPressed: _busy ? null : _onGooglePressed,
                  //     style: OutlinedButton.styleFrom(
                  //       backgroundColor: Colors.white,
                  //       foregroundColor: const Color(
                  //         0xFF1F1F1F,
                  //       ),
                  //       side: BorderSide(color: Colors.grey.shade300, width: 1),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(30),
                  //       ),
                  //       overlayColor: Colors.grey.shade200,
                  //       elevation: 0,
                  //       textStyle: const TextStyle(
                  //         fontSize: 15,
                  //         fontWeight: FontWeight.w500,
                  //         fontFamily:
                  //             'Roboto',
                  //       ),
                  //     ),
                  //     icon: _busy
                  //         ? const SizedBox(
                  //             width: 20,
                  //             height: 20,
                  //             child: CircularProgressIndicator(
                  //               strokeWidth: 2,
                  //               valueColor: AlwaysStoppedAnimation<Color>(
                  //                 Color(0xFF1F1F1F),
                  //               ),
                  //             ),
                  //           )
                  //         : Image.asset('assets/icons/google.webp', height: 20),
                  //     label: Text(
                  //       _busy ? 'Memproses...' : 'Continue with Google',
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 16),
                  Text(
                    'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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

class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    final w = size.width;
    final h = size.height;

    _drawBlob(
      canvas,
      center: Offset(w * 0.5, h * 0.10),
      radiusX: w * 0.55,
      radiusY: h * 0.25,
      colors: [
        const Color(0xFFD4AAFF).withValues(alpha: 0.75),
        const Color(0xFFE8CCFF).withValues(alpha: 0.0),
      ],
    );
    _drawBlob(
      canvas,
      center: Offset(w * 0.82, h * 0.05),
      radiusX: w * 0.40,
      radiusY: h * 0.20,
      colors: [
        const Color(0xFFF4AAEE).withValues(alpha: 0.65),
        const Color(0xFFFCDDFF).withValues(alpha: 0.0),
      ],
    );
    _drawBlob(
      canvas,
      center: Offset(w * 0.15, h * 0.08),
      radiusX: w * 0.36,
      radiusY: h * 0.18,
      colors: [
        const Color(0xFFAADDFF).withValues(alpha: 0.55),
        const Color(0xFFCCEEFF).withValues(alpha: 0.0),
      ],
    );
    _drawBlob(
      canvas,
      center: Offset(w * 0.48, h * 0.16),
      radiusX: w * 0.26,
      radiusY: h * 0.13,
      colors: [
        const Color(0xFFBB88FF).withValues(alpha: 0.55),
        const Color(0xFFCC99FF).withValues(alpha: 0.0),
      ],
    );

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

  void _drawBlob(
    Canvas canvas, {
    required Offset center,
    required double radiusX,
    required double radiusY,
    required List<Color> colors,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(colors: colors).createShader(
        Rect.fromCenter(
          center: center,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
      );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, radiusY / radiusX);
    canvas.drawCircle(Offset.zero, radiusX, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}