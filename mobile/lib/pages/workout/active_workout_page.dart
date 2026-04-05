import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

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
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _isError = false;
  
  // Mengambil daftar playlist dari parent widget
  late final List<String> _videoPlaylist = widget.playlist;

  // Workout state changes
  int _currentStep = 0; // Mulai dari video pertama (index 0)
  late final int _totalSteps = _videoPlaylist.length; // Otomatis menyesuaikan jumlah video
  
  // Timers
  Timer? _workoutTimer;
  int _elapsedSeconds = 0; 
  int _currentExerciseSeconds = 30; 
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startTimers();
  }
  
  void _initializeVideo() {
    setState(() {
      _isVideoInitialized = false;
      _isError = false;
    });

    _controller = VideoPlayerController.asset(_videoPlaylist[_currentStep])
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.play();
        _controller.setLooping(true);
      }).catchError((error) {
        if (!mounted) return;
        setState(() {
          _isError = true;
        });
      });
  }

  void _startTimers() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
    final oldController = _controller;
    // Jeda 1 frame sebelum dispose yang lama (menghindari memory leak & error)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
    });
    _initializeVideo();
  }

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false, 
        child: Column(
          children: [
            // Video Section (Top Half)
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _isError
                      ? Container(
                          color: Colors.black87,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                "Video '${_videoPlaylist[_currentStep].split('/').last}' Gagal Dimuat / Format Rusak.\n\nJika aplikasi sudah di-Run ulang tapi masih error, artinya format video ini tidak didukung Android/iOS.\nSilakan re-export video ini di aplikasi edit video.",
                                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      : _isVideoInitialized
                          ? SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover, // Video kembali dikembalikan ke cover untuk menutupi layar
                                child: SizedBox(
                                  width: _controller.value.size.width,
                                  height: _controller.value.size.height,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator(color: Colors.purple)),
                            ),
                            
                  // Back Button Top Left
                  Positioned(
                    top: 50,
                    left: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom UI Section
            Expanded(
              flex: 5,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Scrollable content area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step indicators — orange gradient pills
                            Row(
                              children: List.generate(_totalSteps, (index) {
                                final bool isActive = index <= _currentStep;
                                final bool isCurrent = index == _currentStep;
                                return Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    height: isCurrent ? 8 : 6,
                                    decoration: BoxDecoration(
                                      gradient: isActive
                                          ? const LinearGradient(
                                              colors: [Color(0xFFFF8C42), Color(0xFFFFB347)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            )
                                          : null,
                                      color: isActive ? null : const Color(0xFFEDE9F6),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: isCurrent
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFFF8C42).withOpacity(0.45),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                  ),
                                );
                              }),
                            ),

                            // Category chips — rata kiri, scrollable
                            if (widget.exerciseDetails.isNotEmpty &&
                                _currentStep < widget.exerciseDetails.length &&
                                widget.exerciseDetails[_currentStep].categories.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: widget.exerciseDetails[_currentStep].categories.map((cat) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3EEFF),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFFD4BBFF), width: 1),
                                        ),
                                        child: Text(
                                          cat,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6A35FF),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Left: Duration
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatTime(_elapsedSeconds),
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87),
                                    ),
                                    const Text(
                                      "DURASI",
                                      style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                                
                                // Center: Timer Big
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: Colors.black12, width: 1.5),
                                      right: BorderSide(color: Colors.black12, width: 1.5),
                                    ),
                                  ),
                                  child: Column(
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
                                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w600, height: 1.0, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Right: Calories
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: const [
                                    Text(
                                      "0",
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87),
                                    ),
                                    Text(
                                      "KKAL",
                                      style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Show Expandable Info Card
                            if (widget.exerciseDetails.isNotEmpty && _currentStep < widget.exerciseDetails.length) ...[
                              const SizedBox(height: 24),
                              _InfoCard(data: widget.exerciseDetails[_currentStep]),
                            ],

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Fixed Bottom Buttons — selalu terlihat, tidak ikut scroll
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _prevStep,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                side: const BorderSide(color: Colors.black12, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "SEBELUMNYA",
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    "BERIKUTNYA",
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 18),
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
}

class _InfoCard extends StatefulWidget {
  final ExerciseData data;
  const _InfoCard({required this.data});

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5D5FF), width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          onExpansionChanged: (val) {
            setState(() { _isExpanded = val; });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A35FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tentang Latihan Ini',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2E1A66)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.data.description,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6A35FF), height: 1.4, fontWeight: FontWeight.w600),
                      maxLines: _isExpanded ? null : 2,
                      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('💡', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Text(
                          'Tips Penting:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6A35FF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.data.tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildTip(tip),
                        )).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6.0),
          child: Icon(Icons.circle, size: 4, color: Color(0xFF2E1A66)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A68), height: 1.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
