import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:mobile/theme/app_colors.dart';

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

class ActiveWorkoutPage extends StatefulWidget {
  final List<String> playlist;
  final List<ExerciseData> exerciseDetails;

  const ActiveWorkoutPage({
    super.key,
    required this.playlist,
    this.exerciseDetails = const [],
  });

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  static const _purple = Color(0xFF7C3AED);

  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _isError = false;

  late final List<String> _videoPlaylist = widget.playlist;
  int _currentStep = 0;
  late final int _totalSteps = _videoPlaylist.length;

  Timer? _initialTimer;
  bool _isInitialCountdown = true;
  int _initialCountdownSeconds = 5;

  Timer? _workoutTimer;
  int _elapsedSeconds = 0;
  int _currentExerciseSeconds = 30;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startInitialCountdown();
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
          if (_isVideoInitialized && !_isError) {
            _controller.play();
          }
          _startTimers();
        }
      });
    });
  }

  final Map<String, String> _networkFallback = {
    "assets/videos/vid_1.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "assets/videos/vid_3.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    "assets/videos/vid_4.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    "assets/videos/vid_5.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
    "assets/videos/vid_6.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
    "assets/videos/vid_7.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
    "assets/videos/vid_8.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
    "assets/videos/vid_9.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
    "assets/videos/dumble/1.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
    "assets/videos/dumble/2.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    "assets/videos/dumble/3.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "assets/videos/dumble/4.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    "assets/videos/dumble/5.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
    "assets/videos/dumble/6.mp4":
        "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
  };

  void _initializeVideo({bool useFallback = false}) {
    if (!mounted) return;

    setState(() {
      _isVideoInitialized = false;
      _isError = false;
    });

    final String videoPath = _videoPlaylist[_currentStep];

    if (useFallback && _networkFallback.containsKey(videoPath)) {
      _controller = VideoPlayerController.networkUrl(
          Uri.parse(_networkFallback[videoPath]!));
    } else {
      _controller = VideoPlayerController.asset(videoPath);
    }

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isVideoInitialized = true;
        _isError = false;
      });
      if (!_isInitialCountdown) {
        _controller.play();
      }
      _controller.setLooping(true);
    }).catchError((error) {
      if (!mounted) return;
      if (!useFallback && _networkFallback.containsKey(videoPath)) {
        _initializeVideo(useFallback: true);
      } else {
        debugPrint("Video Player Error: $error");
        setState(() {
          _isError = true;
        });
      }
    });
  }

  void _startTimers() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!_isVideoInitialized && !_isError) return;

      setState(() {
        _elapsedSeconds++;
        if (_currentExerciseSeconds > 0) {
          _currentExerciseSeconds--;
        } else {
          _nextStep();
        }
      });
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _currentExerciseSeconds = 30;
      });
      _switchVideo();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _currentExerciseSeconds = 30;
      });
      _switchVideo();
    }
  }

  void _switchVideo() {
    _controller.pause();
    final oldController = _controller;
    setState(() {
      _isVideoInitialized = false;
      _isError = false;
    });
    _initializeVideo();
    Future.delayed(const Duration(milliseconds: 200), () {
      oldController.dispose();
    });
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
    _workoutTimer?.cancel();
    _controller.dispose();
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
    final bg = isDark ? darkBackground : lightBackground;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Video Section ──────────────────────────────
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video / loading / error
                  _isError
                      ? _buildVideoError(surface)
                      : _isVideoInitialized
                          ? SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _controller.value.size.width,
                                  height: _controller.value.size.height,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white54,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),

                  // Countdown overlay
                  if (_isInitialCountdown)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Bersiap',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$_initialCountdownSeconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 80,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Back button
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
                            // Step progress bar
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                                // Countdown big
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Selanjutnya',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '0:${_currentExerciseSeconds.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w700,
                                        height: 1.0,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),

                                // Calories
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '0',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'KKAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Navigation buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _prevStep,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                    color: border, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: textPrimary,
                              ),
                              child: Text(
                                'SEBELUMNYA',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _purple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'BERIKUTNYA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoError(Color surface) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.orangeAccent, size: 44),
              const SizedBox(height: 16),
              Text(
                "Gagal memuat '${_videoPlaylist[_currentStep].split('/').last}'",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Format tidak didukung atau file belum di-download (Git LFS).",
                style: TextStyle(
                    color: Colors.white60, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _initializeVideo,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Muat Ulang'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: const Text('Lewati'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
