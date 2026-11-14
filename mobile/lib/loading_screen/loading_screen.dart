import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:mobile/loading_screen/logo_paths.dart';
import 'package:mobile/services/app_initializer.dart';
import 'package:mobile/pages/auth/auth_page.dart';
import 'package:mobile/pages/onboarding/onboarding_page.dart';
import 'package:mobile/pages/main_page.dart';

const LinearGradient cardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
);

const Color kBackground  = Color(0xFFF5F5F5);
const Color kTextSub     = Color(0xFFB0B0B0);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Line drawing — 3 path berurutan
  late final AnimationController _p1Ctrl, _p2Ctrl, _p3Ctrl;
  late final Animation<double> _p1, _p2, _p3;

  // Brand name fade in
  late final AnimationController _brandCtrl;
  late final Animation<double> _brandOpacity, _brandSlide;

  // Spinner — TIDAK pernah di-reset
  late final AnimationController _spinCtrl;
  late final AnimationController _spinnerFadeCtrl;
  late final Animation<double> _spinnerOpacity;

  // Error visibility
  bool _showError = false;
  bool _retryScheduled = false;

  @override
  void initState() {
    super.initState();

    // Line drawing
    _p1Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _p2Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _p3Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _p1 = CurvedAnimation(parent: _p1Ctrl, curve: Curves.easeInOutCubic);
    _p2 = CurvedAnimation(parent: _p2Ctrl, curve: Curves.easeInOutCubic);
    _p3 = CurvedAnimation(parent: _p3Ctrl, curve: Curves.easeInOutCubic);

    // Brand name
    _brandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _brandOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _brandCtrl, curve: Curves.easeOut),
    );
    _brandSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _brandCtrl, curve: Curves.easeOut),
    );

    // Spinner — repeat terus, tidak pernah stop/reset
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _spinnerFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _spinnerOpacity = CurvedAnimation(
      parent: _spinnerFadeCtrl,
      curve: Curves.easeIn,
    );

    _runSequence();
  }

  void _navigateTo(InitialRoute initialRoute) {
    if (!mounted) return;

    Widget destination;
    if (initialRoute == InitialRoute.login) {
      destination = const AuthPage();
    } else if (initialRoute == InitialRoute.onboarding) {
      destination = const OnboardingPage();
    } else {
      destination = const MainPage();
    }

    // Langsung push tanpa fade out
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, a1, a2) =>
            FadeTransition(opacity: a1, child: destination),
      ),
    );
  }

  // Retry HANYA panggil backend — animasi tidak diulang sama sekali
  Future<void> _retryInit() async {
    if (!mounted) return;

    setState(() {
      _showError = false;
      _retryScheduled = false;
    });

    try {
      final initialRoute = await AppInitializer.initialize();
      if (!mounted) return;
      _navigateTo(initialRoute);
    } catch (_) {
      if (!mounted) return;
      setState(() => _showError = true);
      _scheduleAutoRetry();
    }
  }

  void _scheduleAutoRetry() {
    if (_retryScheduled) return;
    _retryScheduled = true;

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (!_showError) return;
      _retryInit();
    });
  }

  // Sequence pertama kali: jalankan animasi + init paralel
  Future<void> _runSequence() async {
    setState(() {
      _showError = false;
      _retryScheduled = false;
    });

    final visualSequence = () async {
      await Future.delayed(const Duration(milliseconds: 200));

      // Spinner fade in bersamaan dengan drawing
      _spinnerFadeCtrl.forward();

      // Line drawing berurutan
      await _p1Ctrl.forward();
      await _p2Ctrl.forward();
      await _p3Ctrl.forward();

      // Brand name
      _brandCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 600));

      // Tahan sebentar
      await Future.delayed(const Duration(milliseconds: 800));
    }();

    final initTask = AppInitializer.initialize();

    try {
      final results = await Future.wait([visualSequence, initTask]);
      final initialRoute = results[1] as InitialRoute;
      _navigateTo(initialRoute);
    } catch (_) {
      if (!mounted) return;
      setState(() => _showError = true);
      _scheduleAutoRetry();
    }
  }

  @override
  void dispose() {
    _p1Ctrl.dispose();
    _p2Ctrl.dispose();
    _p3Ctrl.dispose();
    _brandCtrl.dispose();
    _spinCtrl.dispose();
    _spinnerFadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _p1, _p2, _p3,
          _brandOpacity, _brandSlide,
          _spinCtrl, _spinnerOpacity,
        ]),
        builder: (context, _) {
          return Stack(
            children: [

              // ── Konten utama — TIDAK pernah bergeser ──────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Logo
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: LineDrawingPainter(
                              progress1: _p1.value,
                              progress2: _p2.value,
                              progress3: _p3.value,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Brand name
                    Opacity(
                      opacity: _brandOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _brandSlide.value),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  cardGradient.createShader(bounds),
                              child: const Text(
                                'IbuSehat',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'PENDAMPING KESEHATAN IBU\nPASCA MELAHIRKAN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 3,
                                color: kTextSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Spinner — selalu ada di sini, tidak bergeser
                    Opacity(
                      opacity: _spinnerOpacity.value,
                      child: _GradientSpinner(progress: _spinCtrl.value),
                    ),
                  ],
                ),
              ),

              // ── Error zone — FIXED di bawah, tidak geser layout ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: AnimatedOpacity(
                  opacity: _showError ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  // IgnorePointer saat tidak terlihat agar tidak menangkap tap
                  child: IgnorePointer(
                    ignoring: !_showError,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tidak dapat terhubung ke server',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mencoba kembali otomatis...',
                          style: TextStyle(
                            color: kTextSub,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CustomPainter: Line drawing 3 path (tidak berubah)
// ─────────────────────────────────────────────────────────────
class LineDrawingPainter extends CustomPainter {
  final double progress1, progress2, progress3;

  const LineDrawingPainter({
    required this.progress1,
    required this.progress2,
    required this.progress3,
  });

  static const _gradColors = [Color(0xFFA855F7), Color(0xFFEC4899)];
  static const double _scale = 220 / 1024;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(_scale, _scale);

    _drawPath(canvas, parseSvgPathData(kLogoPath1), progress1,
        Alignment.topLeft, Alignment.bottomRight, 4.0 / _scale);
    _drawPath(canvas, parseSvgPathData(kLogoPath2), progress2,
        Alignment.topRight, Alignment.bottomLeft, 3.0 / _scale);
    _drawPath(canvas, parseSvgPathData(kLogoPath3), progress3,
        Alignment.topCenter, Alignment.bottomCenter, 2.5 / _scale);
  }

  void _drawPath(Canvas canvas, Path path, double progress,
      Alignment gradBegin, Alignment gradEnd, double strokeWidth) {
    if (progress <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final metric in path.computeMetrics()) {
      final extracted = metric.extractPath(0, metric.length * progress);
      final bounds = extracted.getBounds().inflate(8);
      paint.shader = LinearGradient(
        colors: _gradColors,
        begin: gradBegin,
        end: gradEnd,
      ).createShader(bounds);
      canvas.drawPath(extracted, paint);
    }
  }

  @override
  bool shouldRepaint(LineDrawingPainter old) =>
      old.progress1 != progress1 ||
      old.progress2 != progress2 ||
      old.progress3 != progress3;
}

// ─────────────────────────────────────────────────────────────
// Spinner gradient (tidak berubah)
// ─────────────────────────────────────────────────────────────
class _GradientSpinner extends StatelessWidget {
  final double progress;
  const _GradientSpinner({required this.progress});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(48, 48), painter: _SpinPainter(progress));
}

class _SpinPainter extends CustomPainter {
  final double p;
  _SpinPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFA855F7).withValues(alpha: 0.12)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    final startAngle = p * 2 * math.pi - math.pi / 2;
    canvas.drawArc(
      rect,
      startAngle,
      1.9,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: const [Color(0xFFA855F7), Color(0xFFEC4899)],
          transform: GradientRotation(startAngle),
        ).createShader(rect)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SpinPainter old) => old.p != p;
}