import 'package:flutter/material.dart';

/// Shared aurora background — apply with [AppBackground] widget.
/// Wrap any page body in this widget to get the soft purple aurora effect.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Aurora background (fills entire screen)
        Positioned.fill(
          child: CustomPaint(painter: _AuroraPainter()),
        ),
        // Page content on top
        child,
      ],
    );
  }
}

// ── Aurora Painter ────────────────────────────────────────────────────────────
class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // White base
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

    // Fade to white overlay so content below is readable
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
