import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/models/recording_session_result.dart';
import 'package:mobile/screens/activity_summary_screen.dart';
import 'package:mobile/services/location_service.dart';
import 'package:mobile/services/tracking_notifications.dart';
import 'package:mobile/widgets/stats_panel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const String _kDarkTileUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

/// Minimum horizontal GPS movement to record a new point (meters).
const double _kMinMoveMeters = 5;

/// Ignore fixes worse than this accuracy (meters).
const double _kMaxAccuracyMeters = 20;

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();

  final List<LatLng> _route = [];
  LatLng? _lastLatLng;

  bool _hasLocationPermission = false;
  /// True after first accurate fresh fix ([_initLocationFast] step 2).
  bool _gpsReady = false;
  bool _recording = false;
  bool _hasStarted = false;

  double _distanceKm = 0;
  DateTime? _sessionStart;

  /// Wall-clock recording segments (keeps correct elapsed when app is backgrounded).
  DateTime? _recordingWallSegmentStart;
  int _completedRecordingSeconds = 0;

  /// Synced with start/stop of recording segments (per user spec).
  final Stopwatch _stopwatch = Stopwatch();

  StreamSubscription<Position>? _positionSubscription;

  /// Drives UI refresh every second while recording.
  Timer? _uiTickTimer;

  /// Updates Android notification every 5s while recording.
  Timer? _notificationUpdateTimer;

  int _modeIndex = 0;

  static const _apiTypes = ['running', 'walking', 'cycling'];
  static const _labels = ['Berlari', 'Berjalan', 'Bersepeda'];
  /// Default map center when no position yet (Batam, Indonesia).
  static const _fallbackCenter = LatLng(1.1301, 104.0529);
  static const _followZoom = 16.0;

  LocationSettings get _positionStreamSettings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
  }

  int get _elapsedSeconds {
    var sec = _completedRecordingSeconds;
    if (_recording && _recordingWallSegmentStart != null) {
      sec += DateTime.now().difference(_recordingWallSegmentStart!).inSeconds;
    }
    return sec;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationFast();
    });
  }

  void _safeMoveMap(LatLng center, {double zoom = _followZoom}) {
    try {
      _mapController.move(center, zoom);
    } catch (e, st) {
      debugPrint('TrackingScreen._safeMoveMap: $e\n$st');
    }
  }

  /// Fast map: last known immediately, then fresh fix with [LocationAccuracy.bestForNavigation].
  Future<void> _initLocationFast() async {
    await LocationService.requestTrackingPermissions();
    final ok = await LocationService.ensureLocationReady();
    if (!mounted) return;
    setState(() {
      _hasLocationPermission = ok;
      if (!ok) _gpsReady = false;
    });
    if (!ok) return;

    setState(() => _gpsReady = false);

    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        final ll = LatLng(lastKnown.latitude, lastKnown.longitude);
        setState(() {
          _lastLatLng = ll;
          _route
            ..clear()
            ..add(ll);
        });
        _safeMoveMap(ll);
      }

      final fresh = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;

      final ll = LatLng(fresh.latitude, fresh.longitude);
      setState(() {
        _lastLatLng = ll;
        _route
          ..clear()
          ..add(ll);
        _gpsReady = true;
      });
      _safeMoveMap(ll);
    } on TimeoutException catch (e) {
      debugPrint('TrackingScreen._initLocationFast timeout: $e');
      if (!mounted) return;
      if (lastKnown != null) {
        setState(() => _gpsReady = true);
      }
    } catch (e, st) {
      debugPrint('TrackingScreen._initLocationFast: $e\n$st');
      if (!mounted) return;
      if (lastKnown != null) {
        setState(() => _gpsReady = true);
      }
    }
  }

  Future<bool> _ensureLocationForRecording() async {
    final phOk = await LocationService.requestTrackingPermissions();
    if (!phOk) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi diperlukan')),
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Izin lokasi'),
            content: const Text(
              'Izin lokasi ditolak permanen. Buka Pengaturan untuk mengaktifkannya.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Geolocator.openAppSettings();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak')),
        );
      }
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi nonaktif')),
        );
      }
      return false;
    }

    if (mounted) setState(() => _hasLocationPermission = true);
    return true;
  }

  void _beginRecordingSegment() {
    _recordingWallSegmentStart = DateTime.now();
    _stopwatch.start();
  }

  void _endRecordingSegment() {
    _stopwatch.stop();
    if (_recordingWallSegmentStart != null) {
      _completedRecordingSeconds +=
          DateTime.now().difference(_recordingWallSegmentStart!).inSeconds;
      _recordingWallSegmentStart = null;
    }
  }

  Future<void> _requestPostNotificationsIfNeeded() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      debugPrint('notification permission: $status');
    }
  }

  String _trackingNotificationBody() {
    return '⏱ ${_timeText()} | 📍 ${_distanceText()} km | ⚡ ${_paceText()} /km';
  }

  Future<void> _showTrackingNotification() async {
    await TrackingNotifications.showOrUpdate(
      title: 'IbuSehat - Sedang Tracking',
      body: _trackingNotificationBody(),
    );
  }

  Future<void> _startTracking() async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _uiTickTimer?.cancel();
      _notificationUpdateTimer?.cancel();

      await WakelockPlus.enable();
      await _requestPostNotificationsIfNeeded();
      await _showTrackingNotification();

      _notificationUpdateTimer =
          Timer.periodic(const Duration(seconds: 5), (_) async {
        if (!_recording || !mounted) return;
        await TrackingNotifications.showOrUpdate(
          title: 'IbuSehat - Sedang Tracking',
          body: _trackingNotificationBody(),
        );
      });

      _uiTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_recording) return;
        setState(() {});
      });

      _positionSubscription =
          Geolocator.getPositionStream(locationSettings: _positionStreamSettings)
              .listen(
        (position) {
          if (!_recording || !mounted) return;
          _tryAppendGpsReading(position);
        },
        onError: (Object e) => debugPrint('Position stream error: $e'),
      );
    } catch (e, stackTrace) {
      debugPrint('START TRACKING ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _stopTrackingTimers() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _uiTickTimer?.cancel();
    _uiTickTimer = null;
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = null;
    await TrackingNotifications.cancel();
    try {
      await WakelockPlus.disable();
    } catch (e, st) {
      debugPrint('WakelockPlus.disable: $e\n$st');
    }
  }

  @override
  void dispose() {
    _uiTickTimer?.cancel();
    _notificationUpdateTimer?.cancel();
    unawaited(_positionSubscription?.cancel());
    unawaited(TrackingNotifications.cancel());
    unawaited(WakelockPlus.disable());
    _mapController.dispose();
    super.dispose();
  }

  void _tryAppendGpsReading(Position position) {
    if (!_recording) return;
    if (position.accuracy > _kMaxAccuracyMeters) return;

    final lat = position.latitude;
    final lng = position.longitude;
    if (!lat.isFinite || !lng.isFinite) return;

    if (_lastLatLng != null) {
      final meters = Geolocator.distanceBetween(
        _lastLatLng!.latitude,
        _lastLatLng!.longitude,
        lat,
        lng,
      );
      if (meters < _kMinMoveMeters) return;
    }

    final point = LatLng(lat, lng);
    if (_route.isNotEmpty) {
      final prev = _route.last;
      _distanceKm += LocationService.haversineKm(
        prev.latitude,
        prev.longitude,
        lat,
        lng,
      );
    }
    setState(() {
      _route.add(point);
      _lastLatLng = point;
    });
    _safeMoveMap(point);
  }

  Future<void> _onPlayPause() async {
    try {
      if (!_hasLocationPermission || _lastLatLng == null) {
        await _initLocationFast();
      }

      final locOk = await _ensureLocationForRecording();
      if (!locOk) return;

      if (_lastLatLng == null) {
        await _initLocationFast();
      }
      if (_lastLatLng == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menunggu sinyal GPS…')),
        );
        return;
      }

      if (!_hasStarted) {
        _sessionStart = DateTime.now();
        _completedRecordingSeconds = 0;
        _stopwatch.reset();
        setState(() {
          _hasStarted = true;
          _recording = true;
        });
        _beginRecordingSegment();
        await _startTracking();
        return;
      }

      if (_recording) {
        _endRecordingSegment();
        setState(() => _recording = false);
        await _stopTrackingTimers();
      } else {
        setState(() => _recording = true);
        _beginRecordingSegment();
        await _startTracking();
      }
    } catch (e, st) {
      debugPrint('_onPlayPause: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai tracking: $e')),
        );
      }
    }
  }

  void _confirmFinishDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Akhiri Sesi?'),
        content: const Text(
          'Apakah kamu yakin ingin mengakhiri sesi ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _finishSession();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  String _timeText() {
    final total = _elapsedSeconds;
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _paceText() {
    if (_distanceKm < 0.0001 || _elapsedSeconds == 0) return '--:--';
    final totalMin = _elapsedSeconds / 60.0;
    final paceMinPerKm = totalMin / _distanceKm;
    final pm = paceMinPerKm.floor();
    final ps = ((paceMinPerKm - pm) * 60).round().clamp(0, 59);
    return '$pm:${ps.toString().padLeft(2, '0')}';
  }

  String _paceForApi() {
    final t = _paceText();
    return t == '--:--' ? '0:00' : t;
  }

  String _distanceText() {
    final f = NumberFormat.decimalPattern('id_ID');
    f.minimumFractionDigits = 2;
    f.maximumFractionDigits = 2;
    return f.format(_distanceKm);
  }

  int _calories() {
    return (_distanceKm * 60).round();
  }

  Future<void> _finishSession() async {
    final durationSeconds = _elapsedSeconds;

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _uiTickTimer?.cancel();
    _uiTickTimer = null;
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = null;
    _endRecordingSegment();
    await TrackingNotifications.cancel();
    try {
      await WakelockPlus.disable();
    } catch (e, st) {
      debugPrint('WakelockPlus.disable: $e\n$st');
    }

    final ended = DateTime.now();
    final started = _sessionStart ?? ended;
    final result = RecordingSessionResult(
      apiType: _apiTypes[_modeIndex],
      route: List<LatLng>.from(_route),
      durationSeconds: durationSeconds,
      distanceKm: _distanceKm,
      calories: _calories(),
      startedAt: started,
      endedAt: ended,
      paceDisplay: _paceForApi(),
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ActivitySummaryScreen(session: result),
      ),
    );
  }

  IconData _modeIcon() {
    switch (_modeIndex) {
      case 1:
        return Icons.directions_walk;
      case 2:
        return Icons.directions_bike;
      default:
        return Icons.directions_run;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gpsStripReady = _hasLocationPermission && _gpsReady;
    final mapCenter = _lastLatLng ?? _fallbackCenter;
    final playPauseEnabled = _hasStarted || _gpsReady;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 16;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    backgroundColor: const Color(0xFF111827),
                    initialCenter: mapCenter,
                    initialZoom: 15,
                    onMapReady: () {
                      if (_lastLatLng != null) {
                        _safeMoveMap(_lastLatLng!);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _kDarkTileUrl,
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.mobile',
                      retinaMode:
                          MediaQuery.devicePixelRatioOf(context) > 1.0,
                    ),
                    if (_route.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: List<LatLng>.from(_route),
                            strokeWidth: 5,
                            color: const Color(0xFFFF6B00),
                          ),
                        ],
                      ),
                    if (_lastLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _lastLatLng!,
                            width: 22,
                            height: 22,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_hasLocationPermission && !_gpsReady)
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mencari lokasi...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              color: const Color(0xFF0F172A),
              elevation: 8,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomPad),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      StatsPanel(
                        gpsAcquired: gpsStripReady,
                        timeText: _timeText(),
                        paceText: _paceText(),
                        distanceText: _distanceText(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Material(
                                  color: const Color(0xFF422006),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      setState(() {
                                        _modeIndex = (_modeIndex + 1) % 3;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        _modeIcon(),
                                        color: const Color(0xFFFFA726),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _labels[_modeIndex],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Tooltip(
                                  message: playPauseEnabled
                                      ? ((_hasStarted && _recording)
                                          ? 'Jeda'
                                          : 'Mulai')
                                      : 'Menunggu GPS...',
                                  child: Opacity(
                                    opacity: playPauseEnabled ? 1 : 0.45,
                                    child: GestureDetector(
                                      onTap: playPauseEnabled
                                          ? _onPlayPause
                                          : null,
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF6B35),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          (!_hasStarted || !_recording)
                                              ? Icons.play_arrow_rounded
                                              : Icons.pause_rounded,
                                          color: Colors.white,
                                          size: 38,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  (!_hasStarted || !_recording)
                                      ? 'Mulai'
                                      : 'Jeda',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFF6B35),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _hasStarted
                                ? Column(
                                    children: [
                                      Material(
                                        color: Colors.red.shade700,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: _confirmFinishDialog,
                                          child: const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Icon(
                                              Icons.stop_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Selesai',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.red.shade200,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Material(
                                        color: const Color(0xFF1E293B),
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Tambah rute — segera hadir',
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Icon(
                                              Icons.route,
                                              color: Colors.white70,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Tambah Rute',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
