import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/models/recording_session_result.dart';
import 'package:mobile/pages/main_page.dart';
import 'package:mobile/services/activity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/auth_service.dart';

const String _kDarkTileUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

class ActivitySummaryScreen extends StatefulWidget {
  const ActivitySummaryScreen({super.key, required this.session});

  final RecordingSessionResult session;

  @override
  State<ActivitySummaryScreen> createState() => _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen> {
  final MapController _mapController = MapController();
  String _userName = 'Pengguna';
  String? _avatarUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString('user_name') ?? prefs.getString('name');
    if (!mounted) return;
    if (n != null && n.isNotEmpty) {
      setState(() => _userName = n);
    }
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _userName = (user?.name.isNotEmpty ?? false) ? user!.name : 'Pengguna';
      _avatarUrl = user?.avatarUrl;
    });
  }

  String _activityTitle() {
    final h = widget.session.startedAt.hour;
    final period =
        h < 12 ? 'Morning' : (h < 17 ? 'Afternoon' : 'Evening');
    final period = h < 12 ? 'Morning' : (h < 17 ? 'Afternoon' : 'Evening');
    switch (widget.session.apiType) {
      case 'walking':
        return '$period Walk';
      case 'cycling':
        return '$period Ride';
      default:
        return '$period Run';
    }
  }

  IconData _typeIcon() {
    switch (widget.session.apiType) {
      case 'walking':
        return Icons.directions_walk;
      case 'cycling':
        return Icons.directions_bike;
      default:
        return Icons.directions_run;
    }
  }

  String _subtitleLine() {
    final df = DateFormat('MMMM d, y · h:mm a', 'en');
    return '${df.format(widget.session.startedAt)} · Luar ruangan';
  }

  String _durationHuman() {
    final s = widget.session.durationSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m}m ${r}s';
  }

  String _paceDisplay() {
    final p = widget.session.paceDisplay;
    return p == '0:00' ? '—' : '$p /km';
  }

  void _fitRouteToMap(List<LatLng> pts) {
    if (pts.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (pts.length >= 2) {
          final bounds = LatLngBounds.fromPoints(pts);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(48),
            ),
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
          );
        } else {
          _mapController.move(pts.first, 14);
        }
      } catch (e, st) {
        debugPrint('ActivitySummaryScreen._fitRouteToMap: $e\n$st');
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ActivityService.saveActivity(
        widget.session.toApiJson(title: _activityTitle()),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const MainPage(initialIndex: 1),
          builder: (_) => MainPage(
            initialIndex: 1,
            progressRefreshToken: DateTime.now().microsecondsSinceEpoch,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _discard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const MainPage(initialIndex: 3),
      ),
      MaterialPageRoute<void>(builder: (_) => const MainPage(initialIndex: 3)),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final km = widget.session.distanceKm;
    final kmStr = km.toStringAsFixed(2);
    final pts = widget.session.route;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF334155),
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(_typeIcon(), color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _subtitleLine(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _activityTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _statCol('Distance', '$kmStr km'),
                  _statCol('Pace', _paceDisplay()),
                  _statCol('Time', _durationHuman()),
                  _statCol('Calories', '${widget.session.calories}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: pts.isEmpty
                  ? Container(
                      color: const Color(0xFF111827),
                      child: const Center(
                        child: Text(
                          'Tidak ada titik rute',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        backgroundColor: const Color(0xFF111827),
                        initialCenter: pts.first,
                        initialZoom: 14,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                        onMapReady: () => _fitRouteToMap(pts),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _kDarkTileUrl,
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.example.mobile',
                          retinaMode:
                              MediaQuery.devicePixelRatioOf(context) > 1.0,
                        ),
                        if (pts.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: pts,
                                strokeWidth: 5,
                                color: const Color(0xFFFF6B00),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _discard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Buang'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Simpan Aktivitas'),
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

  Widget _statCol(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : '?';
    final avatarUrl = _avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: const Color(0xFF7C3AED),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF7C3AED),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
