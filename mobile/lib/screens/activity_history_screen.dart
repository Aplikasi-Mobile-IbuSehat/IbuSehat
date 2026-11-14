import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/models/activity_model.dart';
import 'package:mobile/screens/activity_detail_screen.dart';
import 'package:mobile/services/activity_service.dart';
import 'package:mobile/theme/app_colors.dart';

// ─── Brand colors ──────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF7C3AED);
const _kChipBgLight = Color(0xFFEDE9FE);
const _kChipBgDark = Color(0xFF2A1F45);
const _kAmber = Color(0xFFF59E0B);
const _kOrange = Color(0xFFF97316);

// ─── Month helper ──────────────────────────────────────────────────────────
const _monthNames = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const _monthFull = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

class _MonthYear {
  final int month;
  final int year;
  const _MonthYear(this.month, this.year);

  String get shortLabel => _monthNames[month];
  String get fullLabel => _monthFull[month];

  @override
  bool operator ==(Object other) =>
      other is _MonthYear && other.month == month && other.year == year;
  @override
  int get hashCode => month.hashCode ^ year.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════════
class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  List<ActivityModel> _allActivities = const [];
  bool _loading = true;
  String? _errorMessage;

  late List<_MonthYear> _tabs;
  int _selectedTabIndex = -1; // -1 means "Semua"
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _buildTabs();
    // Default: select the current month tab (last in list)
    _selectedTabIndex = _tabs.length - 1;
    _fetchActivities();
  }

  void _buildTabs() {
    final now = DateTime.now();
    _tabs = List.generate(3, (i) {
      final d = DateTime(now.year, now.month - (2 - i));
      return _MonthYear(d.month, d.year);
    });
  }

  String get _subtitleRange {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);
    return '${_monthFull[prev.month]} – ${_monthFull[now.month]} ${now.year}';
  }

  // ─── Data ──────────────────────────────────────────────────────────────
  Future<void> _fetchActivities() async {
    setState(() { _loading = true; _errorMessage = null; });
    try {
      final activities = await ActivityService.fetchActivities();
      if (!mounted) return;
      setState(() { _allActivities = activities; _loading = false; });
    } on LangkahSummaryError catch (e) {
      if (!mounted) return;
      setState(() {
        _allActivities = const [];
        _errorMessage = e.userMessage == 'Belum login'
            ? 'Silakan login terlebih dahulu'
            : e.userMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allActivities = const [];
        _errorMessage = 'Tidak ada koneksi';
        _loading = false;
      });
    }
  }

  List<ActivityModel> get _filtered {
    if (_showAll || _selectedTabIndex < 0) return _allActivities;
    final tab = _tabs[_selectedTabIndex];
    return _allActivities
        .where((a) => a.startedAt.month == tab.month && a.startedAt.year == tab.year)
        .toList();
  }

  // ─── Formatters ────────────────────────────────────────────────────────
  String _fmtKm(double km) => km >= 10 ? km.toStringAsFixed(1) : km.toStringAsFixed(1);

  String _fmtDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m}m ${sec.toString().padLeft(2, '0')}s';
  }

  String _fmtDate(DateTime dt) => DateFormat('d MMM yyyy · HH:mm').format(dt);

  IconData _typeIcon(String t) {
    switch (t) {
      case 'walking': return Icons.directions_walk;
      case 'cycling': return Icons.directions_bike;
      default: return Icons.directions_run;
    }
  }

  // ─── Navigate to detail screen ─────────────────────────────────────────
  void _showDetails(ActivityModel a) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activity: a),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;
    final chipBg = isDark ? _kChipBgDark : _kChipBgLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _fetchActivities,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(textPrimary, textSecondary),
              ),
              SliverToBoxAdapter(
                child: _buildMonthTabs(
                  surface: surface,
                  border: border,
                  textSecondary: textSecondary,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_loading)
                _buildLoadingSliver(surface, chipBg)
              else if (_errorMessage != null)
                _buildErrorSliver(textSecondary)
              else if (_filtered.isEmpty)
                _buildEmptySliver(textSecondary)
              else
                _buildListSliver(
                  surface: surface,
                  chipBg: chipBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  border: border,
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Riwayat Aktivitas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              _subtitleRange,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthTabs({
    required Color surface,
    required Color border,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = !_showAll && _selectedTabIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() { _selectedTabIndex = i; _showAll = false; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? _kPrimary : surface,
                          borderRadius: BorderRadius.circular(24),
                          border: active ? null : Border.all(color: border),
                        ),
                        child: Text(
                          _tabs[i].shortLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() { _showAll = true; _selectedTabIndex = -1; }),
            child: Text(
              'Semua >',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _showAll ? _kPrimary : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildLoadingSliver(Color surface, Color chipBg) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShimmerCard(surface: surface, chipBg: chipBg),
          )),
        ),
      ),
    );
  }

  SliverFillRemaining _buildErrorSliver(Color textSecondary) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchActivities,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('Muat ulang', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  SliverFillRemaining _buildEmptySliver(Color textSecondary) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.directions_run_rounded, size: 64, color: _kPrimary.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            'Belum ada aktivitas',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textSecondary),
          ),
        ]),
      ),
    );
  }

  SliverPadding _buildListSliver({
    required Color surface,
    required Color chipBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final items = _filtered;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ActivityCard(
              activity: items[i],
              typeIcon: _typeIcon(items[i].type),
              fmtKm: _fmtKm,
              fmtDuration: _fmtDuration,
              fmtDate: _fmtDate,
              onDetailTap: () => _showDetails(items[i]),
              surface: surface,
              chipBg: chipBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              border: border,
            ),
          ),
          childCount: items.length,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Activity Card
// ═══════════════════════════════════════════════════════════════════════════
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.typeIcon,
    required this.fmtKm,
    required this.fmtDuration,
    required this.fmtDate,
    required this.onDetailTap,
    required this.surface,
    required this.chipBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  final ActivityModel activity;
  final IconData typeIcon;
  final String Function(double) fmtKm;
  final String Function(int) fmtDuration;
  final String Function(DateTime) fmtDate;
  final VoidCallback onDetailTap;
  final Color surface;
  final Color chipBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onDetailTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left section: icon + info + chips
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Purple circle icon
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: chipBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(typeIcon, color: _kPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fmtDate(activity.startedAt),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
                            ),
                          ],
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 2x2 stat chips
                    Row(children: [
                      _StatChipInline(
                        icon: Icons.location_on_outlined,
                        iconColor: _kPrimary,
                        text: '${fmtKm(activity.distanceKm)} km',
                        chipBg: chipBg,
                        textPrimary: textPrimary,
                      ),
                      const SizedBox(width: 8),
                      _StatChipInline(
                        icon: Icons.bolt,
                        iconColor: _kAmber,
                        text: activity.pace?.isNotEmpty == true ? '${activity.pace} /km' : '- /km',
                        chipBg: chipBg,
                        textPrimary: textPrimary,
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _StatChipInline(
                        icon: Icons.access_time_rounded,
                        iconColor: _kPrimary,
                        text: fmtDuration(activity.durationSeconds),
                        chipBg: chipBg,
                        textPrimary: textPrimary,
                      ),
                      const SizedBox(width: 8),
                      _StatChipInline(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: _kOrange,
                        text: '${activity.calories} kal',
                        chipBg: chipBg,
                        textPrimary: textPrimary,
                      ),
                    ]),
                  ],
                )),
                const SizedBox(width: 10),
                // Right: route preview thumbnail
                _RoutePreview(coordinates: activity.coordinates),
              ],
            ),
          ),
          // Bottom: "Lihat detail rute"
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: border)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(Icons.north_east_rounded, size: 14, color: textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Lihat detail rute',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
              ]),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}

// ── Stat chip (inline, inside card) ──────────────────────────────────────
class _StatChipInline extends StatelessWidget {
  const _StatChipInline({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.chipBg,
    required this.textPrimary,
  });
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color chipBg;
  final Color textPrimary;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Route preview thumbnail dengan FlutterMap ────────────────────────────
class _RoutePreview extends StatefulWidget {
  const _RoutePreview({required this.coordinates});
  final List<ActivityCoordinate> coordinates;

  @override
  State<_RoutePreview> createState() => _RoutePreviewState();
}

class _RoutePreviewState extends State<_RoutePreview> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fitMapBounds();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitMapBounds() {
    if (widget.coordinates.length < 2) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final points = widget.coordinates
            .map((c) => LatLng(c.lat, c.lng))
            .where((p) => p.latitude != 0.0 || p.longitude != 0.0)
            .toList();

        if (points.length < 2) return;

        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(8),
          ),
        );
      } catch (e) {
        debugPrint('_RoutePreview._fitMapBounds: $e');
      }
    });
  }

  LatLng get _mapCenter {
    if (widget.coordinates.isEmpty) return const LatLng(-6.2, 106.8);
    if (widget.coordinates.length == 1) {
      return LatLng(widget.coordinates.first.lat, widget.coordinates.first.lng);
    }
    double lat = 0, lng = 0;
    for (final c in widget.coordinates) {
      lat += c.lat;
      lng += c.lng;
    }
    return LatLng(lat / widget.coordinates.length, lng / widget.coordinates.length);
  }

  List<LatLng> get _routePoints {
    return widget.coordinates
        .map((c) => LatLng(c.lat, c.lng))
        .where((p) => p.latitude != 0.0 || p.longitude != 0.0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? _kChipBgDark
            : _kChipBgLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: widget.coordinates.length >= 2
            ? FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.ibusehat.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 3,
                        color: _kPrimary,
                      ),
                    ],
                  ),
                ],
              )
            : const Center(
                child: Icon(Icons.map_rounded, color: _kPrimary, size: 28),
              ),
      ),
    );
  }
}

// ─── CustomPainter sudah tidak digunakan lagi ────────────────────────────
// Dihapus: _RoutePainter class

// ── Shimmer loading card ─────────────────────────────────────────────────
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.surface, required this.chipBg});

  final Color surface;
  final Color chipBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _shimmerBox(40, 40, isCircle: true),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(120, 14),
                const SizedBox(height: 6),
                _shimmerBox(80, 10),
              ],
            )),
            _shimmerBox(80, 80, radius: 14),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _shimmerBox(double.infinity, 28, radius: 10)),
            const SizedBox(width: 8),
            Expanded(child: _shimmerBox(double.infinity, 28, radius: 10)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _shimmerBox(double.infinity, 28, radius: 10)),
            const SizedBox(width: 8),
            Expanded(child: _shimmerBox(double.infinity, 28, radius: 10)),
          ]),
        ],
      ),
    );
  }

  Widget _shimmerBox(double w, double h, {double radius = 6, bool isCircle = false}) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: chipBg.withValues(alpha: 0.5),
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}


