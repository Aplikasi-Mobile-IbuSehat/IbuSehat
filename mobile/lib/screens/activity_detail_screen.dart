import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:mobile/models/activity_model.dart';

// ─── Colors ────────────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF7C3AED);
const _kBlue       = Color(0xFF3B82F6);
const _kAmber      = Color(0xFFF59E0B);
const _kOrange     = Color(0xFFF97316);
const _kGrey       = Color(0xFF9CA3AF);
const _kDark       = Color(0xFF1F1235);
const _kChipBg     = Color(0xFFEDE9FE);
const _kCardShadow = Color(0x14000000);

// ═══════════════════════════════════════════════════════════════════════════
class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key, required this.activity});
  final ActivityModel activity;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {

  // ── Helpers ──────────────────────────────────────────────────────────────
  ActivityModel get _a => widget.activity;

  List<LatLng> get _pts => _a.coordinates
      .map((c) => LatLng(c.lat, c.lng))
      .where((p) => p.latitude != 0.0 || p.longitude != 0.0)
      .toList();

  String _fmtDate(DateTime dt) =>
      DateFormat('d MMM yyyy · HH:mm').format(dt);

  String _fmtDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _fmtKm(double km) => km.toStringAsFixed(1);

  // ── KM Splits ────────────────────────────────────────────────────────────
  // Returns list of {label, pace, splitTime} for each ~1 km segment
  List<_KmSplit> _computeSplits() {
    final pts = _pts;
    if (pts.length < 2) return [];

    const distCalc = Distance();
    final splits = <_KmSplit>[];
    double accumulated = 0;
    double segStart = 0; // accumulated distance at last split boundary
    int splitIndex = 1;

    // We don't have per-point timestamps from the API, so we'll spread
    // duration evenly across total distance to estimate split paces.
    final totalDist = _a.distanceKm * 1000; // metres
    final totalSecs = _a.durationSeconds.toDouble();

    for (int i = 1; i < pts.length; i++) {
      final d = distCalc(pts[i - 1], pts[i]);
      accumulated += d;

      while (accumulated - segStart >= 1000) {
        final kmDist = 1000.0;
        // proportional seconds for this km
        final secs = totalDist > 0 ? (kmDist / totalDist * totalSecs).round() : 0;
        final paceStr = secs > 0
            ? '${(secs ~/ 60).toString().padLeft(1, '0')}:${(secs % 60).toString().padLeft(2, '0')} /km'
            : '-';
        final splitStr = secs > 0
            ? '${(secs ~/ 60).toString().padLeft(1, '0')}:${(secs % 60).toString().padLeft(2, '0')}'
            : '-';
        splits.add(_KmSplit(
          index: splitIndex,
          label: '$splitIndex km',
          pace: paceStr,
          split: splitStr,
        ));
        splitIndex++;
        segStart += kmDist;
      }
    }

    // Last partial km
    final lastDist = accumulated - segStart;
    if (lastDist > 1) {
      final secs = totalDist > 0
          ? (lastDist / totalDist * totalSecs).round()
          : 0;
      final splitStr = secs > 0
          ? '${(secs ~/ 60).toString().padLeft(1, '0')}:${(secs % 60).toString().padLeft(2, '0')}'
          : '-';
      final paceStr = (secs > 0 && lastDist > 0)
          ? () {
              final secPerKm = (secs / (lastDist / 1000)).round();
              return '${(secPerKm ~/ 60).toString().padLeft(1, '0')}:${(secPerKm % 60).toString().padLeft(2, '0')} /km';
            }()
          : '-';
      splits.add(_KmSplit(
        index: splitIndex,
        label: '${_fmtKm(_a.distanceKm)} km',
        pace: paceStr,
        split: splitStr,
      ));
    }

    return splits;
  }

  // ── Map centre ───────────────────────────────────────────────────────────
  LatLng? get _mapCenter {
    final pts = _pts;
    if (pts.isEmpty) return null;
    if (pts.length == 1) return pts.first;
    double lat = 0, lng = 0;
    for (final p in pts) { lat += p.latitude; lng += p.longitude; }
    return LatLng(lat / pts.length, lng / pts.length);
  }

  // mid-point for distance label
  LatLng? get _midPoint {
    final pts = _pts;
    if (pts.isEmpty) return null;
    return pts[pts.length ~/ 2];
  }

  // ── Zoom to fit ──────────────────────────────────────────────────────────
  double _fitZoom() {
    final pts = _pts;
    if (pts.length < 2) return 14;
    double minLat = pts.first.latitude, maxLat = minLat;
    double minLng = pts.first.longitude, maxLng = minLng;
    for (final p in pts) {
      minLat = min(minLat, p.latitude); maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude); maxLng = max(maxLng, p.longitude);
    }
    final span = max(maxLat - minLat, maxLng - minLng);
    if (span < 0.002) return 16;
    if (span < 0.005) return 15;
    if (span < 0.01)  return 14;
    if (span < 0.03)  return 13;
    return 12;
  }

  // ── Share ────────────────────────────────────────────────────────────────
  void _share() {
    final text =
        '🏃 ${_a.title}\n'
        '📍 ${_fmtKm(_a.distanceKm)} km  ⚡ ${_a.pace ?? '-'} /km\n'
        '⏱ ${_fmtDuration(_a.durationSeconds)}  🔥 ${_a.calories} kal\n'
        '📅 ${_fmtDate(_a.startedAt)}\n'
        '\nDibagikan via IbuSehat 💜';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final pts  = _pts;
    final center = _mapCenter ?? const LatLng(-6.2, 106.8);
    final mid  = _midPoint;
    final splits = _computeSplits();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full screen scroll ──────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── MAP section ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      // Flutter map
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: _fitZoom(),
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.mobile',
                          ),
                          if (pts.length >= 2)
                            PolylineLayer(polylines: [
                              Polyline(
                                points: pts,
                                strokeWidth: 4.5,
                                color: _kBlue,
                              ),
                            ]),
                          MarkerLayer(markers: [
                            // Start marker
                            if (pts.isNotEmpty)
                              Marker(
                                point: pts.first,
                                width: 60,
                                height: 30,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Start',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            // End marker
                            if (pts.length >= 2)
                              Marker(
                                point: pts.last,
                                width: 18,
                                height: 18,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            // Distance label mid-route
                            if (mid != null)
                              Marker(
                                point: mid,
                                width: 90,
                                height: 28,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: _kCardShadow,
                                          blurRadius: 8,
                                          offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: _kBlue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_fmtKm(_a.distanceKm)} km',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _kDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ]),
                        ],
                      ),
                      // ── AppBar overlay ──────────────────────────────────
                      Positioned(
                        top: 0, left: 0, right: 0,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                // Back button
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      shape: BoxShape.circle,
                                      boxShadow: const [
                                        BoxShadow(
                                            color: _kCardShadow,
                                            blurRadius: 6),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 16,
                                        color: _kDark),
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Detail Aktivitas',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Share icon
                                GestureDetector(
                                  onTap: _share,
                                  child: Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      shape: BoxShape.circle,
                                      boxShadow: const [
                                        BoxShadow(
                                            color: _kCardShadow,
                                            blurRadius: 6),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.share_rounded,
                                        size: 17,
                                        color: _kDark),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Finish pill
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: _kCardShadow,
                                            blurRadius: 6),
                                      ],
                                    ),
                                    child: const Text(
                                      'Finish',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
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
                ),
              ),

              // ── WHITE CONTENT ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Activity title header ──────────────────────────
                        Text(
                          _a.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text(
                            '${_fmtDate(_a.startedAt)} · GPS Terverifikasi',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _kGrey,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 20),

                        // ── 2×2 Stats grid ────────────────────────────────
                        Row(children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.navigation_rounded,
                              iconColor: _kBlue,
                              value: _fmtKm(_a.distanceKm),
                              unit: 'km',
                              label: 'Jarak',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.bolt_rounded,
                              iconColor: _kAmber,
                              value: _a.pace?.isNotEmpty == true
                                  ? _a.pace!
                                  : '-',
                              unit: '/km',
                              label: 'Pace',
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.access_time_rounded,
                              iconColor: _kPrimary,
                              value: _fmtDuration(_a.durationSeconds),
                              unit: 'mnt',
                              label: 'Waktu',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: _kOrange,
                              value: '${_a.calories}',
                              unit: 'kal',
                              label: 'Kalori',
                            ),
                          ),
                        ]),

                        // ── KM Splits ─────────────────────────────────────
                        if (splits.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Row(children: const [
                            Icon(Icons.access_time_rounded,
                                size: 18, color: _kPrimary),
                            SizedBox(width: 8),
                            Text(
                              'Waktu per KM',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kDark,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: _kCardShadow,
                                  blurRadius: 12,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: List.generate(splits.length, (i) {
                                final s = splits[i];
                                return Column(
                                  children: [
                                    _KmSplitRow(split: s),
                                    if (i < splits.length - 1)
                                      const Divider(
                                          height: 1,
                                          thickness: 1,
                                          indent: 56,
                                          endIndent: 16,
                                          color: Color(0xFFF3F4F6)),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed bottom "Bagikan Aktivitas" button ─────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _share,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Bagikan Aktivitas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Stat Card
// ═══════════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                  height: 1,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kGrey.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KM Split data model + row widget
// ═══════════════════════════════════════════════════════════════════════════
class _KmSplit {
  const _KmSplit({
    required this.index,
    required this.label,
    required this.pace,
    required this.split,
  });
  final int index;
  final String label;
  final String pace;
  final String split;
}

class _KmSplitRow extends StatelessWidget {
  const _KmSplitRow({required this.split});
  final _KmSplit split;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // KM number circle
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              color: _kChipBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${split.index}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Text(
              split.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kGrey,
              ),
            ),
          ),
          // Pace
          Text(
            split.pace,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kGrey,
            ),
          ),
          const SizedBox(width: 16),
          // Split time
          SizedBox(
            width: 36,
            child: Text(
              split.split,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
