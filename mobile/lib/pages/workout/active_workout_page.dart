import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/services/streak_service.dart';
import 'package:mobile/widgets/streak_celebration_overlay.dart';

class ExerciseData {
  final String title;
  final String description;
  final List<String> tips;
  final List<String> categories;

  const ExerciseData({
    required this.title,
    required this.description,
    required this.tips,
    this.categories = const [],
  });
}

const _purple = Color(0xFF8B5CF6);

class ActiveWorkoutPage extends StatefulWidget {
  final List<String> playlist; // Cloudinary video URLs
  final List<ExerciseData> exerciseDetails;
  final int? workoutId;

  const ActiveWorkoutPage({
    super.key,
    required this.playlist,
    this.exerciseDetails = const [],
    this.workoutId,
  });

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _isError = false;
  bool _hasCompletedWorkout = false;
  bool _isDurationSaved = false;

  Future<void> _saveWorkoutDuration({required bool isCompleted}) async {
    if (_isDurationSaved) return;
    final durationSeconds = _elapsedSeconds;
    if (durationSeconds < 60) return;

    _isDurationSaved = true;
    try {
      await StreakService().completeWorkout(
        widget.workoutId,
        durationSeconds: durationSeconds,
        isCompleted: isCompleted,
      );
      debugPrint('🎉 Saved workout duration: $durationSeconds seconds, isCompleted: $isCompleted');
    } catch (e) {
      debugPrint('🔴 Failed to save workout duration: $e');
    }
  }
  
  late final List<String> _videoPlaylist = widget.playlist;

  int _currentStep = 0;
  late final int _totalSteps = _videoPlaylist.length;
  
  // Timers
  Timer? _initialTimer;
  bool _isInitialCountdown = true;
  int _initialCountdownSeconds = 5;

  Timer? _transitionTimer;
  bool _isTransitionCountdown = false;
  int _transitionCountdownSeconds = 5;
  int _transitionTargetStep = 0;

  static const _kCountdownDuration = 5;

  Timer? _workoutTimer;
  int _elapsedSeconds = 0; 
  int _currentExerciseSeconds = 20; 
  
  @override
  void initState() {
    super.initState();
    _initializeVideo(); // Initialize first video
    _startInitialCountdown();
  }

  void _initializeVideo({int? stepIndex, bool autoPlay = false}) async {
    if (!mounted) return;

    final step = stepIndex ?? _currentStep;
    final String videoUrl = _videoPlaylist[step];

    debugPrint('=== INIT VIDEO: step=$step, url=$videoUrl');

    // Dispose old controller
    final oldController = _controller;
    if (oldController != null) {
      oldController.pause();
      await Future.delayed(const Duration(milliseconds: 100));
      oldController.dispose();
    }

    setState(() {
      _isVideoInitialized = false;
      _isError = false;
    });

    // Create new controller with network URL
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
      ),
    );

    try {
      await _controller!.initialize();
      
      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
        _isError = false;
      });

      _controller!.setLooping(false);
      _hasCompletedWorkout = false;

      // CRITICAL: Only play if autoPlay is true AND no countdown is active
      if (autoPlay && !_isInitialCountdown && !_isTransitionCountdown) {
        debugPrint('=== AUTO PLAYING VIDEO');
        _controller!.play();
      } else {
        debugPrint('=== VIDEO LOADED BUT PAUSED (waiting for countdown)');
      }
    } catch (error) {
      if (!mounted) return;
      debugPrint('🔴 Video Error: $error');
      setState(() {
        _isError = true;
        _isVideoInitialized = false;
      });
    }
  }

  void _startInitialCountdown() {
    _initialTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_initialCountdownSeconds > 1) {
          _initialCountdownSeconds--;
        } else {
          _isInitialCountdown = false;
          _initialTimer?.cancel();
          // Now start playing the video
          if (_isVideoInitialized && !_isError) {
            _controller?.play();
          }
          _startTimers();
        }
      });
    });
  }

  void _startTimers() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_isInitialCountdown || _isTransitionCountdown) return;
      
      if (!_isVideoInitialized && !_isError) return;

      final newElapsed = _elapsedSeconds + 1;
      final newExerciseSeconds = _currentExerciseSeconds > 0 ? _currentExerciseSeconds - 1 : 0;
      
      final shouldComplete = newExerciseSeconds <= 0;
      final isLastVideo = _currentStep >= _totalSteps - 1;

      setState(() {
        _elapsedSeconds = newElapsed;
        _currentExerciseSeconds = newExerciseSeconds;
      });

      if (shouldComplete) {
        if (isLastVideo) {
          if (!_hasCompletedWorkout) {
            _hasCompletedWorkout = true;
            _workoutTimer?.cancel();
            Future.microtask(() => _completeWorkout());
          }
        } else {
          _nextStep();
        }
      }
    });
  }

  void _beginTransitionToNext() {
    if (_currentStep >= _totalSteps - 1) return;

    _workoutTimer?.cancel();
    _controller?.pause(); // Pause current video

    setState(() {
      _transitionTargetStep = _currentStep + 1;
      _isTransitionCountdown = true;
      _transitionCountdownSeconds = _kCountdownDuration;
    });

    // Load next video but don't play it yet (will show first frame)
    _initializeVideo(stepIndex: _transitionTargetStep, autoPlay: false);
    
    _startTransitionCountdown();
  }

  void _startTransitionCountdown() {
    _transitionTimer?.cancel();
    _transitionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_transitionCountdownSeconds > 1) {
          _transitionCountdownSeconds--;
        } else {
          _completeTransition();
        }
      });
    });
  }

  void _restartTransitionCountdown() {
    _transitionTimer?.cancel();
    setState(() {
      _transitionCountdownSeconds = _kCountdownDuration;
    });
    _startTransitionCountdown();
  }

  void _completeTransition() {
    _transitionTimer?.cancel();
    setState(() {
      _currentStep = _transitionTargetStep;
      _currentExerciseSeconds = 20;
      _isTransitionCountdown = false;
      _transitionCountdownSeconds = _kCountdownDuration;
    });
    
    // Start playing the video that was loaded during countdown
    if (_isVideoInitialized && !_isError) {
      _controller?.play();
    }
    
    _startTimers();
  }
  
  void _nextStep() {
    if (_isTransitionCountdown) {
      if (_transitionTargetStep >= _totalSteps - 1) {
        _completeTransition();
        return;
      }
      setState(() {
        _transitionTargetStep++;
      });
      _restartTransitionCountdown();
      return;
    }

    debugPrint('=== VIDEO PROGRESS: ${_currentStep + 1} of $_totalSteps');
    
    if (_currentStep >= _totalSteps - 1) {
      debugPrint('=== CALLING COMPLETE WORKOUT with id: ${widget.workoutId}');
      _completeWorkout();
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      _beginTransitionToNext();
    }
  }

  Future<void> _completeWorkout() async {
    if (!mounted) return;
    
    debugPrint('🎉 DEBUG workout completed - workoutId: ${widget.workoutId}');
    
    _workoutTimer?.cancel();
    _transitionTimer?.cancel();
    _initialTimer?.cancel();

    if (!mounted) return;

    int streakCount = 1;
    int longestStreak = 1;
    
    if (widget.workoutId != null) {
      try {
        final result = await StreakService().completeWorkout(
          widget.workoutId,
          durationSeconds: _elapsedSeconds,
          isCompleted: true,
        );
        _isDurationSaved = true; // Mark as saved so PopScope doesn't log it again
        streakCount = result.streakActive;
        longestStreak = result.streakLongest;
        debugPrint('🎉 [WORKOUT] Streak result: active=$streakCount, longest=$longestStreak');
      } catch (e) {
        debugPrint('🔴 Streak save failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan streak: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakCelebrationOverlay(
        streakActive: streakCount,
        streakLongest: longestStreak,
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _prevStep() {
    if (_isTransitionCountdown) {
      _transitionTimer?.cancel();
      setState(() {
        _isTransitionCountdown = false;
        _transitionCountdownSeconds = _kCountdownDuration;
        _currentExerciseSeconds = 20;
      });
      // Reload current video
      _initializeVideo(autoPlay: true);
      _startTimers();
      return;
    }

    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _currentExerciseSeconds = 20;
      });
      // Load previous video and start playing
      _initializeVideo(autoPlay: true);
    }
  }

  bool get _showCountdownOverlay =>
      _isInitialCountdown || _isTransitionCountdown;

  int get _activeCountdownSeconds => _isInitialCountdown
      ? _initialCountdownSeconds
      : _transitionCountdownSeconds;

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bersiap",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "$_activeCountdownSeconds",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoPopup(BuildContext context) {
    if (widget.exerciseDetails.isEmpty ||
        _currentStep >= widget.exerciseDetails.length) return;
    final data = widget.exerciseDetails[_currentStep];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.35,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? darkBorder : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.6,
                    ),
                  ),
                  if (data.tips.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Tips',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...data.tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 7),
                              decoration: const BoxDecoration(
                                color: _purple,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _initialTimer?.cancel();
    _transitionTimer?.cancel();
    _workoutTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : lightBorder;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveWorkoutDuration(isCompleted: false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false, 
          child: Column(
            children: [
              // Video Section (Top Half)
              Expanded(
                flex: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video Player (Cloudinary)
                    _isError
                        ? Container(
                            color: Colors.black87,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 48),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Video gagal dimuat",
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Periksa koneksi internet kamu.",
                                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () => _initializeVideo(),
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text("Muat Ulang"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white24,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : _isVideoInitialized && _controller != null
                            ? SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _controller?.value.size.width ?? 1,
                                    height: _controller?.value.size.height ?? 1,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.purple),
                                ),
                              ),
                    
                    // Countdown Overlay
                    if (_showCountdownOverlay) _buildCountdownOverlay(),
                              
                    // Back Button Top Left
                    Positioned(
                      top: 50,
                      left: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1A1A2E), size: 18),
                      ),
                    ),
                  ),

                  // Info button
                  if (widget.exerciseDetails.isNotEmpty &&
                      _currentStep < widget.exerciseDetails.length)
                    Positioned(
                      top: 50,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => _showInfoPopup(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: Color(0xFF1A1A2E), size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Bottom Panel ───────────────────────────────
            Expanded(
              flex: 4,
              child: Container(
                color: surface,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step indicators
                            Row(
                              children: List.generate(_totalSteps, (index) {
                                final bool isActive = index <= _currentStep;
                                final bool isCurrent = index == _currentStep;
                                return Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    height: isCurrent ? 5 : 4,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? _purple
                                          : border,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),

                            // Category chips
                            if (widget.exerciseDetails.isNotEmpty &&
                                _currentStep <
                                    widget.exerciseDetails.length &&
                                widget.exerciseDetails[_currentStep].categories
                                    .isNotEmpty) ...[
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: widget
                                      .exerciseDetails[_currentStep].categories
                                      .map((cat) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _purple.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          cat,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _purple,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Stats row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Elapsed
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatTime(_elapsedSeconds),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'DURASI',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Center: Timer Big
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Selanjutnya Dalam",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "0:${_currentExerciseSeconds.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w600,
                                        height: 1.0,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Navigation button (only Sebelumnya)
                            OutlinedButton.icon(
                              onPressed: _currentStep > 0 ? _prevStep : null,
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text("Sebelumnya"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                foregroundColor: const Color(0xFF8B5CF6),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
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
