import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:mobile/models/activity_model.dart';
import 'package:mobile/pages/payments/premium_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

// ─── Colors ────────────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF7C3AED);
const _kBlue       = Color(0xFF3B82F6);
const _kAmber      = Color(0xFFF59E0B);
const _kOrange     = Color(0xFFF97316);
const _kChipBg     = Color(0xFFEDE9FE);
const _kShareDarkTileUrl =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
const _kShareCardWidth = 400.0;
const _kShareCardHeight = 600.0;

// ═══════════════════════════════════════════════════════════════════════════
class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key, required this.activity});
  final ActivityModel activity;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final MapController _mapController = MapController();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _shareBusy = false;
  LatLng? _lastKnownPosition;

  @override
  void initState() {
    super.initState();
    _prepareFallbackLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── Prepare fallback location for activities without coordinates ───────────
  Future<void> _prepareFallbackLocation() async {
    if (_pts.isEmpty) {
      try {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null && mounted) {
          setState(() {
            _lastKnownPosition = LatLng(pos.latitude, pos.longitude);
          });
        }
      } catch (e) {
        debugPrint('ActivityDetailScreen._prepareFallbackLocation: $e');
        // Silently fail, will use default Batam coordinates
      }
    }
  }

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

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(int splitDurationSeconds, {double? segmentKm}) {
    final km = segmentKm ?? 1.0;
    if (km <= 0 || splitDurationSeconds <= 0) return '- /km';
    final paceSeconds = (splitDurationSeconds / km).round();
    return '${_formatTime(paceSeconds)} /km';
  }

  // ── KM Splits ────────────────────────────────────────────────────────────
  List<_KmSplit> _calculateKmSplits() {
    final coordinates = _pts;
    if (coordinates.length < 2) return [];

    final splits = <_KmSplit>[];
    double accumulatedDistance = 0;
    int splitNumber = 1;
    final totalDurationSeconds = _a.durationSeconds;
    final totalDistanceKm = _a.distanceKm;
    if (totalDistanceKm <= 0 || totalDurationSeconds <= 0) return [];

    for (int i = 1; i < coordinates.length; i++) {
      final segmentDistance = Geolocator.distanceBetween(
            coordinates[i - 1].latitude,
            coordinates[i - 1].longitude,
            coordinates[i].latitude,
            coordinates[i].longitude,
          ) /
          1000;

      accumulatedDistance += segmentDistance;

      while (splitNumber <= totalDistanceKm.floor() &&
          accumulatedDistance >= splitNumber) {
        final splitFraction = splitNumber / totalDistanceKm;
        final splitSeconds =
            (splitFraction * totalDurationSeconds).round();
        final prevFraction = (splitNumber - 1) / totalDistanceKm;
        final prevSeconds =
            (prevFraction * totalDurationSeconds).round();
        final splitDuration = splitSeconds - prevSeconds;

        splits.add(_KmSplit(
          number: splitNumber,
          distanceLabel: '$splitNumber km',
          pacePerKm: _formatPace(splitDuration),
          splitTime: _formatTime(splitDuration),
        ));
        splitNumber++;
      }
    }

    final remainingKm = totalDistanceKm - (splitNumber - 1);
    if (remainingKm > 0.05) {
      final remainingFraction = remainingKm / totalDistanceKm;
      final remainingSeconds =
          (remainingFraction * totalDurationSeconds).round();
      splits.add(_KmSplit(
        number: splitNumber,
        distanceLabel: '${_fmtKm(totalDistanceKm)} km',
        pacePerKm: _formatPace(remainingSeconds, segmentKm: remainingKm),
        splitTime: _formatTime(remainingSeconds),
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

  // ── Map fit ──────────────────────────────────────────────────────────────
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
              padding: const EdgeInsets.fromLTRB(40, 56, 40, 32),
            ),
          );
        } else {
          _mapController.move(pts.first, 15);
        }
      } catch (e, st) {
        debugPrint('ActivityDetailScreen._fitRouteToMap: $e\n$st');
      }
    });
  }

  // ── Share ────────────────────────────────────────────────────────────────
  Widget _buildShareCard() {
    return SizedBox(
      width: _kShareCardWidth,
      height: _kShareCardHeight,
      child: _ActivityShareCard(
        activity: _a,
        points: _pts,
        lastKnownPosition: _lastKnownPosition,
        fmtDate: _fmtDate,
        fmtDuration: _fmtDuration,
        fmtKm: _fmtKm,
      ),
    );
  }

  Future<Uint8List?> _captureShareImage() async {
    setState(() => _shareBusy = true);
    try {
      // Wait for map tiles to fully load before capturing
      final image = await _screenshotController.captureFromWidget(
        _buildShareCard(),
        delay: const Duration(milliseconds: 800),
        pixelRatio: 3.0,
        context: context,
      );
      return image;
    } catch (e, st) {
      debugPrint('ActivityDetailScreen._captureShareImage: $e\n$st');
      return null;
    } finally {
      if (mounted) setState(() => _shareBusy = false);
    }
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (!Platform.isAndroid) return true;

    int sdkInt = 29;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      sdkInt = androidInfo.version.sdkInt;
    } catch (e) {
      // Hot reload does not register native plugins — assume Android 10+.
      debugPrint(
        'ActivityDetailScreen._ensureGallerySavePermission: '
        'cannot read SDK ($e), assuming API 29+',
      );
    }

    if (sdkInt > 28) {
      // Android 10+ uses scoped storage — save directly, no permission needed.
      return true;
    }

    // Android 9 and below — request WRITE_EXTERNAL_STORAGE only.
    final storage = await Permission.storage.status;
    if (storage.isGranted) return true;
    if (storage.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }

    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: const Text(
          'Izin akses galeri diperlukan untuk menyimpan gambar aktivitas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    try {
      final permitted = await _ensureGallerySavePermission();
      if (!permitted) {
        if (mounted) _showPermissionDeniedDialog();
        return;
      }

      final image = await _captureShareImage();
      if (image == null) {
        _showSnack('Gagal membuat gambar aktivitas.', isError: true);
        return;
      }

      final safeName = _a.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final fileName = 'aktivitas_${safeName.isEmpty ? _a.id : safeName}';
      final result = await ImageGallerySaverPlus.saveImage(
        image,
        name: fileName,
        quality: 100,
      );

      final success = result is Map &&
          (result['isSuccess'] == true || result['isSuccess'] == 'true');
      _showSnack(
        success ? 'Berhasil disimpan ke galeri!' : 'Gagal menyimpan ke galeri.',
        isError: !success,
      );
    } on MissingPluginException catch (e) {
      debugPrint('ActivityDetailScreen._saveToGallery plugin error: $e');
      _showSnack(
        'Fitur galeri belum siap. Stop lalu jalankan ulang app (flutter run).',
        isError: true,
      );
    } catch (e, st) {
      debugPrint('ActivityDetailScreen._saveToGallery: $e\n$st');
      _showSnack('Gagal menyimpan ke galeri.', isError: true);
    }
  }

  Future<void> _shareToSocial() async {
    final image = await _captureShareImage();
    if (image == null) {
      _showSnack('Gagal membuat gambar aktivitas.', isError: true);
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/aktivitas_${_a.id}.png');
      await file.writeAsBytes(image);

      final pace = _a.pace?.isNotEmpty == true ? _a.pace! : '-';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text:
              '${_a.title} - ${_fmtKm(_a.distanceKm)} km in ${_fmtDuration(_a.durationSeconds)} · $pace /km',
        ),
      );
    } catch (e) {
      debugPrint('ActivityDetailScreen._shareToSocial: $e');
      _showSnack('Gagal membagikan aktivitas.', isError: true);
    }
  }

  // ── Premium gate for share ──────────────────────────────────────────────
  void _handleShareWithPremiumCheck() {
    final isPremium = AuthService.instance.isPremiumSync;
    if (!isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumPage()),
      );
      return;
    }
    _showShareSheet();
  }

  void _showShareSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final previewHeight = MediaQuery.sizeOf(sheetCtx).height * 0.38;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bagikan Aktivitas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: previewHeight,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildShareCard(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _shareBusy
                        ? null
                        : () async {
                            Navigator.pop(sheetCtx);
                            await _saveToGallery();
                          },
                    icon: const Icon(Icons.save_alt_rounded, size: 20),
                    label: const Text(
                      'Simpan ke Galeri',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? darkBackground : lightBackground,
                      foregroundColor: textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: border),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _shareBusy
                        ? null
                        : () async {
                            Navigator.pop(sheetCtx);
                            await _shareToSocial();
                          },
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text(
                      'Bagikan ke Sosmed',
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
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text(
                    'Tutup',
                    style: TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final pts  = _pts;
    final center = _mapCenter ?? const LatLng(-6.2, 106.8);
    final splits = _calculateKmSplits();
    final hasRouteData = _pts.length >= 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;

    return Scaffold(
      backgroundColor: surface,
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
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 14,
                          minZoom: 10,
                          maxZoom: 18,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.pinchZoom |
                                InteractiveFlag.doubleTapZoom |
                                InteractiveFlag.drag,
                          ),
                          onMapReady: () => _fitRouteToMap(pts),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ibusehat.app',
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
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: textPrimary,
                                    size: 20,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Detail Aktivitas',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 36),
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
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _a.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text(
                            '${_fmtDate(_a.startedAt)} · GPS Terverifikasi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
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

                        const SizedBox(height: 28),
                        Row(children: [
                          const Icon(Icons.timer, size: 18, color: _kPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Waktu per KM',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? darkBackground : lightBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border),
                          ),
                          child: !hasRouteData || splits.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                  child: Text(
                                    'Data rute tidak tersedia',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: List.generate(splits.length, (i) {
                                    final s = splits[i];
                                    return Column(
                                      children: [
                                        _KmSplitRow(split: s),
                                        if (i < splits.length - 1)
                                          Divider(
                                            height: 1,
                                            thickness: 1,
                                            indent: 56,
                                            endIndent: 16,
                                            color: border,
                                          ),
                                      ],
                                    );
                                  }),
                                ),
                        ),
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
              color: surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _ShareActivityButton(
                    busy: _shareBusy,
                    onTap: _handleShareWithPremiumCheck,
                  ),
                ),
              ),
            ),
          ),

          if (_shareBusy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: _kPrimary),
                        const SizedBox(height: 14),
                        Text(
                          'Menyiapkan gambar...',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: lightTextPrimary,
                          ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Share Activity Button — premium-gated
// ═══════════════════════════════════════════════════════════════════════════
class _ShareActivityButton extends StatelessWidget {
  const _ShareActivityButton({
    required this.busy,
    required this.onTap,
  });

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPremium = AuthService.instance.isPremiumSync;

    if (isPremium) {
      // ── Premium user: tombol share biasa ────────────────────────────────
      return ElevatedButton.icon(
        onPressed: busy ? null : onTap,
        icon: const Icon(Icons.share_rounded, size: 18),
        label: const Text(
          'Bagikan Aktivitas',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      );
    }

    // ── Non-premium: tombol terkunci dengan badge Premium ──────────────────
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Bagikan Aktivitas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            // Badge "Premium" di pojok kanan
            Positioned(
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Share card (400×600 portrait)
// ═══════════════════════════════════════════════════════════════════════════
// Share card (400×600 portrait) dengan proper FlutterMap
// ═══════════════════════════════════════════════════════════════════════════
class _ActivityShareCard extends StatefulWidget {
  const _ActivityShareCard({
    required this.activity,
    required this.points,
    required this.fmtDate,
    required this.fmtDuration,
    required this.fmtKm,
    this.lastKnownPosition,
  });

  final ActivityModel activity;
  final List<LatLng> points;
  final LatLng? lastKnownPosition;
  final String Function(DateTime) fmtDate;
  final String Function(int) fmtDuration;
  final String Function(double) fmtKm;

  @override
  State<_ActivityShareCard> createState() => _ActivityShareCardState();
}

class _ActivityShareCardState extends State<_ActivityShareCard> {
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
    if (widget.points.length < 2) {
      return;
    }

    // Wait for widget to be built before fitting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final bounds = LatLngBounds.fromPoints(widget.points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(40),
          ),
        );
      } catch (e) {
        debugPrint('_ActivityShareCard._fitMapBounds: $e');
      }
    });
  }

  IconData get _typeIcon {
    switch (widget.activity.type) {
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'cycling':
        return Icons.directions_bike_rounded;
      default:
        return Icons.directions_run_rounded;
    }
  }

  LatLng get _mapCenter {
    // Fallback chain: coordinates → lastKnownPosition → Batam default
    if (widget.points.isNotEmpty) {
      if (widget.points.length == 1) return widget.points.first;
      // Calculate center from all points
      double lat = 0, lng = 0;
      for (final p in widget.points) {
        lat += p.latitude;
        lng += p.longitude;
      }
      return LatLng(lat / widget.points.length, lng / widget.points.length);
    } else if (widget.lastKnownPosition != null) {
      return widget.lastKnownPosition!;
    } else {
      // Default fallback: Batam, Indonesia
      return const LatLng(1.1301, 104.0529);
    }
  }

  double get _initialZoom {
    // Use closer zoom when there's no route (just showing location)
    return widget.points.length >= 2 ? 14.0 : 15.0;
  }

  Color get _routeColor {
    switch (widget.activity.type) {
      case 'walking':
        return _kOrange;
      case 'cycling':
        return _kBlue;
      default:
        return _kBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pace = widget.activity.pace?.isNotEmpty == true 
        ? widget.activity.pace! 
        : '-';

    return Container(
      width: _kShareCardWidth,
      height: _kShareCardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-size map as background
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _initialZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _kShareDarkTileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.ibusehat.app',
              ),
              // Show polyline if there are 2+ points
              if (widget.points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.points,
                      strokeWidth: 5,
                      color: _routeColor,
                    ),
                  ],
                ),
              // Show marker if there's exactly 1 point
              if (widget.points.length == 1)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.points.first,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _routeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // 2. Gradient overlay at bottom for text readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000), // fully transparent
                    Color(0x00000000), // fully transparent
                    Color(0x66000000), // ~40% black
                    Color(0xAA000000), // ~67% black
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          // 3. Text content overlaid on top of gradient
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row: icon + app name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _typeIcon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Text(
                      'IbuSehat',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  widget.activity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.fmtDate(widget.activity.startedAt),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ShareStatCell(
                        value: '${widget.fmtKm(widget.activity.distanceKm)} km',
                        label: 'Jarak',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ShareStatCell(
                        value: '$pace /km',
                        label: 'Pace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ShareStatCell(
                        value: widget.fmtDuration(widget.activity.durationSeconds),
                        label: 'Waktu',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ShareStatCell(
                        value: '${widget.activity.calories} kal',
                        label: 'Kalori',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareStatCell extends StatelessWidget {
  const _ShareStatCell({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
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
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
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
                    color: textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
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
    required this.number,
    required this.distanceLabel,
    required this.pacePerKm,
    required this.splitTime,
  });
  final int number;
  final String distanceLabel;
  final String pacePerKm;
  final String splitTime;
}

class _KmSplitRow extends StatelessWidget {
  const _KmSplitRow({required this.split});
  final _KmSplit split;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final chipBg = isDark ? const Color(0xFF2A1F45) : _kChipBg;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: chipBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${split.number}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              split.distanceLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              split.pacePerKm,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              split.splitTime,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
