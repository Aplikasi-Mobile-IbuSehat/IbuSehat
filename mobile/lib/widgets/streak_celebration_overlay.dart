import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class StreakCelebrationOverlay extends StatefulWidget {
  final int streakActive;
  final int streakLongest;
  final VoidCallback onDismiss;

  const StreakCelebrationOverlay({
    super.key,
    required this.streakActive,
    required this.streakLongest,
    required this.onDismiss,
  });

  @override
  State<StreakCelebrationOverlay> createState() => _StreakCelebrationOverlayState();
}

class _StreakCelebrationOverlayState extends State<StreakCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _fireController;
  late AnimationController _numberController;
  late AnimationController _buttonController;
  late ConfettiController _confettiController;

  late Animation<double> _backgroundOpacity;
  late Animation<double> _cardScale;
  late Animation<double> _fireScale;
  late Animation<int> _numberCount;
  late Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _numberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Initialize animations
    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeIn),
    );

    _cardScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _fireScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _fireController, curve: Curves.easeInOut),
    );

    _numberCount = IntTween(begin: 0, end: widget.streakActive).animate(
      CurvedAnimation(parent: _numberController, curve: Curves.easeOut),
    );

    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeIn),
    );

    // Start animation sequence
    _startAnimationSequence();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _startAnimationSequence() async {
    // 1. Background fade in (0ms - 300ms)
    await _backgroundController.forward();

    // 2. Card scale up with bounce (200ms - 600ms)
    await Future.delayed(const Duration(milliseconds: 200));
    _cardController.forward();

    // 3. Fire icon pulse (600ms - ongoing)
    await Future.delayed(const Duration(milliseconds: 400));
    _fireController.repeat(reverse: true);

    // 4. Number count up (600ms - 1200ms)
    _numberController.forward();

    // 5. Confetti burst (700ms)
    await Future.delayed(const Duration(milliseconds: 100));
    _confettiController.play();

    // 6. Button fade in (1200ms - 1500ms)
    await Future.delayed(const Duration(milliseconds: 500));
    _buttonController.forward();
  }

  void _dismiss() {
    _confettiController.stop();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _fireController.dispose();
    _numberController.dispose();
    _buttonController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dark semi-transparent background
          AnimatedBuilder(
            animation: _backgroundOpacity,
            builder: (context, child) {
              return Container(
                color: Colors.black.withOpacity(0.75 * _backgroundOpacity.value),
              );
            },
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Down
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Color(0xFF6C4DFF),
                Color(0xFF8B5CF6),
                Color(0xFFF472B6),
                Color(0xFFFBBF24),
                Color(0xFF22C55E),
              ],
            ),
          ),

          // Main card
          Center(
            child: AnimatedBuilder(
              animation: _cardScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _cardScale.value,
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C4DFF).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated fire icon with glow
                    AnimatedBuilder(
                      animation: _fireScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _fireScale.value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF6C4DFF).withOpacity(0.2),
                                  Color(0xFF8B5CF6).withOpacity(0.1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C4DFF).withOpacity(0.4),
                                  blurRadius: 32 * _fireScale.value,
                                  spreadRadius: 8 * _fireScale.value,
                                ),
                              ],
                            ),
                            child: const Text(
                              '🔥',
                              style: TextStyle(fontSize: 80),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // "Streak Hidup!" text
                    const Text(
                      'Streak Hidup!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Animated number
                    AnimatedBuilder(
                      animation: _numberCount,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C4DFF), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_numberCount.value} Hari',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Konsisten selama ${widget.streakActive} hari berturut-turut!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Longest streak badge (if applicable)
                    if (widget.streakActive >= widget.streakLongest && widget.streakActive > 1)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFBBF24),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              'Rekor Baru!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Lanjutkan button
                    AnimatedBuilder(
                      animation: _buttonOpacity,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _buttonOpacity.value,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C4DFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Lanjutkan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
