import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Brightness, Colors, RefreshIndicatorMode, Theme;

/// Pull-to-refresh di bawah [SliverAppBar], di atas konten.
class ModernSliverRefreshControl extends StatelessWidget {
  const ModernSliverRefreshControl({
    super.key,
    required this.onRefresh,
  });

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
      refreshTriggerPullDistance: 72,
      refreshIndicatorExtent: 48,
      builder: (
        BuildContext context,
        RefreshIndicatorMode refreshState,
        double pulledExtent,
        double refreshTriggerPullDistance,
        double refreshIndicatorExtent,
      ) {
        final pull = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
        final spinning = refreshState == RefreshIndicatorMode.armed ||
            refreshState == RefreshIndicatorMode.refresh;

        return SizedBox(
          height: pulledExtent,
          child: Center(
            child: Opacity(
              opacity: pull,
              child: Transform.scale(
                scale: 0.65 + (0.35 * pull),
                child: _ModernRefreshIndicator(
                  pull: pull,
                  spinning: spinning,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModernRefreshIndicator extends StatefulWidget {
  const _ModernRefreshIndicator({
    required this.pull,
    required this.spinning,
  });

  final double pull;
  final bool spinning;

  @override
  State<_ModernRefreshIndicator> createState() => _ModernRefreshIndicatorState();
}

class _ModernRefreshIndicatorState extends State<_ModernRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant _ModernRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  void _syncSpin() {
    if (widget.spinning) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFF8B5CF6).withValues(alpha: 0.14);

    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(22, 22),
          painter: _ArcSpinnerPainter(
            sweep: widget.spinning ? 0.72 : widget.pull.clamp(0.0, 1.0) * 0.65,
            rotation: widget.spinning ? _spin.value * 2 * math.pi : -math.pi / 2,
            trackColor: track,
            gradientColors: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
        );
      },
    );
  }
}

class _ArcSpinnerPainter extends CustomPainter {
  _ArcSpinnerPainter({
    required this.sweep,
    required this.rotation,
    required this.trackColor,
    required this.gradientColors,
  });

  final double sweep;
  final double rotation;
  final Color trackColor;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (sweep <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: rotation,
        endAngle: rotation + 2 * math.pi,
      ).createShader(rect);

    canvas.drawArc(rect, rotation, sweep * 2 * math.pi, false, arc);
  }

  @override
  bool shouldRepaint(covariant _ArcSpinnerPainter oldDelegate) {
    return oldDelegate.sweep != sweep ||
        oldDelegate.rotation != rotation ||
        oldDelegate.trackColor != trackColor;
  }
}
