import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile/pages/workout/workout_storage.dart';

class RunningTrackerPage extends StatefulWidget {
  const RunningTrackerPage({super.key});

  @override
  State<RunningTrackerPage> createState() => _RunningTrackerPageState();
}

class _RunningTrackerPageState extends State<RunningTrackerPage> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;
  Timer? _elapsedTimer;

  final List<LatLng> _routePoints = [];
  double _totalDistanceMeters = 0;
  int _elapsedSeconds = 0;
  bool _isTracking = false; // sedang berjalan
  bool _hasStarted = false; // sudah pernah mulai

  // Mode aktivitas: lari, jalan, sepeda
  String _mode = 'run'; // 'run' | 'walk' | 'bike'

  @override
  void initState() {
    super.initState();
    // Halaman dibuka dalam kondisi belum mulai tracking.
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi diperlukan untuk melacak lari')),
      );
      setState(() {
        _isTracking = false;
      });
      return;
    }

    setState(() {
      _hasStarted = true;
      _isTracking = true;
      _routePoints.clear();
      _totalDistanceMeters = 0;
      _elapsedSeconds = 0;
    });

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isTracking) return;
      setState(() {
        _elapsedSeconds++;
      });
    });

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5, // meter
    );

    _positionSub?.cancel();
    _positionSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (position) {
        final point = LatLng(position.latitude, position.longitude);

        setState(() {
          if (_routePoints.isNotEmpty) {
            final prev = _routePoints.last;
            _totalDistanceMeters += Geolocator.distanceBetween(
              prev.latitude,
              prev.longitude,
              point.latitude,
              point.longitude,
            );
          }
          _routePoints.add(point);
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(point),
        );
      },
    );
  }

  Future<void> _pauseTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    setState(() {
      _isTracking = false;
    });
    _elapsedTimer?.cancel();
  }

  Future<void> _resumeTracking() async {
    // Jangan reset data, hanya lanjutkan stream & timer
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    setState(() {
      _hasStarted = true;
      _isTracking = true;
    });

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isTracking) return;
      setState(() {
        _elapsedSeconds++;
      });
    });

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      final point = LatLng(position.latitude, position.longitude);

      setState(() {
        if (_routePoints.isNotEmpty) {
          final prev = _routePoints.last;
          _totalDistanceMeters += Geolocator.distanceBetween(
            prev.latitude,
            prev.longitude,
            point.latitude,
            point.longitude,
          );
        }
        _routePoints.add(point);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(point),
      );
    });
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Duration get _elapsed {
    return Duration(seconds: _elapsedSeconds);
  }

  double get _distanceKm => _totalDistanceMeters / 1000.0;

  double get _avgSpeedKmh {
    final seconds = _elapsed.inSeconds;
    if (seconds == 0) return 0;
    final hours = seconds / 3600.0;
    return _distanceKm / hours;
  }

  // Pace rata-rata dalam menit/km
  String get _avgPacePerKmText {
    if (_distanceKm <= 0 || _elapsedSeconds == 0) {
      return '0:00';
    }
    final totalMinutes = _elapsedSeconds / 60.0;
    final pace = totalMinutes / _distanceKm; // menit per km
    final paceMinutes = pace.floor();
    final paceSeconds = ((pace - paceMinutes) * 60).round().clamp(0, 59);
    return '${paceMinutes.toString()}:${paceSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool canShowMap = defaultTargetPlatform == TargetPlatform.android;
    final currentCamera = _routePoints.isNotEmpty
        ? CameraPosition(target: _routePoints.last, zoom: 17)
        : const CameraPosition(target: LatLng(-6.200000, 106.816666), zoom: 13);

    final bool hasGpsFix = _routePoints.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen map / placeholder
          Positioned.fill(
            child: canShowMap
                ? GoogleMap(
                    initialCameraPosition: currentCamera,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    polylines: {
                      if (_routePoints.length > 1)
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: _routePoints,
                          color: const Color(0xFF7C3AED),
                          width: 5,
                        ),
                    },
                    onMapCreated: (c) => _mapController = c,
                  )
                : Container(
                    color: const Color(0xFF020617),
                    child: const Center(
                      child: Text(
                        'Map hanya tersedia di Android.\nTracking tetap dihitung via GPS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          ),

          // Back button dan judul di atas
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tracking Lari',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet seperti contoh Strava
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GPS status bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasGpsFix
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              hasGpsFix ? 'GPS Didapat' : 'Mencari GPS...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _distanceKm.toStringAsFixed(2) + ' km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row: Waktu - Pace - Jarak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statItem(
                        label: 'WAKTU',
                        value: _formatDuration(_elapsed),
                        unit: '',
                      ),
                      _statItem(
                        label: 'PACE rata2',
                        value: _avgPacePerKmText,
                        unit: '/km',
                      ),
                      _statItem(
                        label: 'JARAK',
                        value: _distanceKm.toStringAsFixed(2),
                        unit: 'km',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Route text (ringkas)
                  SizedBox(
                    height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: _routePoints.isEmpty
                          ? const Text(
                              'Rute akan muncul di sini setelah kamu mulai bergerak.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _routePoints.length,
                              itemBuilder: (context, index) {
                                final p = _routePoints[index];
                                return Text(
                                  '${index + 1}. ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF4B5563),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom controls: big start button
                  Row(
                    children: [
                      // Tombol mode (tap untuk ganti run/walk/bike)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_mode == 'run') {
                              _mode = 'walk';
                            } else if (_mode == 'walk') {
                              _mode = 'bike';
                            } else {
                              _mode = 'run';
                            }
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _mode == 'run'
                                  ? Icons.directions_run
                                  : _mode == 'walk'
                                      ? Icons.directions_walk
                                      : Icons.directions_bike,
                              color: const Color(0xFF6B7280),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _mode == 'run'
                                  ? 'Lari'
                                  : _mode == 'walk'
                                      ? 'Jalan'
                                      : 'Sepeda',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Big middle button
                      GestureDetector(
                        onTap: () {
                          if (!_hasStarted) {
                            _startTracking();
                          } else if (_isTracking) {
                            _pauseTracking();
                          } else {
                            _resumeTracking();
                          }
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFB923C),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            !_hasStarted
                                ? Icons.play_arrow_rounded
                                : _isTracking
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Selesai
                      TextButton(
                        onPressed: () async {
                          final elapsed = _elapsed;
                          final session = WorkoutSession(
                            mode: _mode,
                            startTime: DateTime.now().subtract(elapsed),
                            duration: elapsed,
                            distanceKm: _distanceKm,
                            avgSpeedKmh: _avgSpeedKmh.isNaN ? 0 : _avgSpeedKmh,
                          );

                          await WorkoutStorage.saveSession(session);

                          final text = StringBuffer()
                            ..writeln('Aku baru saja menyelesaikan lari!')
                            ..writeln(
                                'Jarak : ${_distanceKm.toStringAsFixed(2)} km')
                            ..writeln('Durasi: ${_formatDuration(elapsed)}')
                            ..writeln(
                                'Kecepatan rata-rata: ${(_avgSpeedKmh.isNaN ? 0 : _avgSpeedKmh).toStringAsFixed(1)} km/j')
                            ..writeln('#IbuSehat #Workout');

                          await Share.share(text.toString());

                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'SELESAI',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1235),
          ),
        ),
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

