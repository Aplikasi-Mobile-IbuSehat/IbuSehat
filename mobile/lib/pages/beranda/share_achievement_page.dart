import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile/theme/app_colors.dart';

const _kPrimary = Color(0xFF6C4DFF);
const _kSecondary = Color(0xFF8B5CF6);
const _kAccent = Color(0xFF7C3AED);

const _kShareCardWidth = 360.0;

class ShareAchievementPage extends StatefulWidget {
  final int streakDays;

  const ShareAchievementPage({super.key, required this.streakDays});

  @override
  State<ShareAchievementPage> createState() => _ShareAchievementPageState();
}

class _ShareAchievementPageState extends State<ShareAchievementPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isProcessing = false;

  int get _effectiveStreakDays =>
      widget.streakDays > 0 ? widget.streakDays : 5;

  String get _shareCaption =>
      'Aku konsisten $_effectiveStreakDays hari penuh menjaga kesehatan di IbuSehat! '
      '#IbuSehat #SehatBahagiaKeluarga';

  Widget _buildShareCardWidget({required double width}) {
    return SizedBox(
      width: width,
      child: _AchievementShareCard(streakDays: _effectiveStreakDays),
    );
  }

  Future<Uint8List?> _captureShareImage() async {
    setState(() => _isProcessing = true);
    try {
      final image = await _screenshotController.captureFromWidget(
        _buildShareCardWidget(width: _kShareCardWidth),
        delay: const Duration(milliseconds: 500),
        pixelRatio: 3.0,
        context: context,
      );
      return image;
    } catch (e, st) {
      debugPrint('ShareAchievementPage._captureShareImage: $e\n$st');
      return null;
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _saveCapturedImageToTemp(Uint8List image) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/ibusehat_streak_$_effectiveStreakDays.png';
      final file = File(imagePath);
      await file.writeAsBytes(image);
      return imagePath;
    } catch (e) {
      debugPrint('ShareAchievementPage._saveCapturedImageToTemp: $e');
      return null;
    }
  }

  Future<bool> _ensureGallerySavePermission() async {
    if (!Platform.isAndroid) return true;

    int sdkInt = 29;
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      sdkInt = androidInfo.version.sdkInt;
    } catch (e) {
      debugPrint(
        'ShareAchievementPage._ensureGallerySavePermission: $e',
      );
    }

    if (sdkInt > 28) return true;

    final storage = await Permission.storage.status;
    if (storage.isGranted) return true;
    if (storage.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    return false;
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
        _showSnack('Izin galeri diperlukan untuk menyimpan gambar.', isError: true);
        return;
      }

      final image = await _captureShareImage();
      if (image == null) {
        _showSnack('Gagal membuat gambar pencapaian.', isError: true);
        return;
      }

      final result = await ImageGallerySaverPlus.saveImage(
        image,
        quality: 100,
        name: 'IbuSehat_Streak_$_effectiveStreakDays',
      );

      final success = result is Map &&
          (result['isSuccess'] == true || result['isSuccess'] == 'true');
      _showSnack(
        success ? 'Berhasil disimpan ke Galeri!' : 'Gagal menyimpan ke galeri.',
        isError: !success,
      );
    } on MissingPluginException {
      _showSnack(
        'Fitur galeri belum siap. Jalankan ulang aplikasi.',
        isError: true,
      );
    } catch (e) {
      debugPrint('ShareAchievementPage._saveToGallery: $e');
      _showSnack('Gagal menyimpan ke galeri.', isError: true);
    }
  }

  Future<void> _shareImage({String? text}) async {
    final image = await _captureShareImage();
    if (image == null) {
      _showSnack('Gagal membuat gambar pencapaian.', isError: true);
      return;
    }

    final imagePath = await _saveCapturedImageToTemp(image);
    if (imagePath == null) {
      _showSnack('Gagal menyiapkan gambar.', isError: true);
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath, mimeType: 'image/png')],
        text: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bagikan Pencapaian',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width - 40,
                    child: Screenshot(
                      controller: _screenshotController,
                      child: _AchievementShareCard(
                        streakDays: _effectiveStreakDays,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildShareSection(
                surface: surface,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                border: border,
              ),
              const SizedBox(height: 16),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareSection({
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Bagikan ke Media Sosial',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih platform favoritmu',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                icon: FontAwesomeIcons.instagram,
                label: 'Instagram',
                color: const Color(0xFFE1306C),
                textSecondary: textSecondary,
                onTap: () => _shareImage(),
              ),
              _buildSocialButton(
                icon: FontAwesomeIcons.whatsapp,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                textSecondary: textSecondary,
                onTap: () => _shareImage(text: _shareCaption),
              ),
              _buildSocialButton(
                icon: FontAwesomeIcons.facebookF,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                textSecondary: textSecondary,
                onTap: () => _shareImage(),
              ),
              _buildSocialButton(
                icon: FontAwesomeIcons.xTwitter,
                label: 'X',
                color: textPrimary,
                textSecondary: textSecondary,
                onTap: () => _shareImage(),
              ),
              _buildSocialButton(
                icon: Icons.more_horiz_rounded,
                label: 'Lainnya',
                color: textSecondary,
                textSecondary: textSecondary,
                onTap: () => _shareImage(text: _shareCaption),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: _isProcessing ? 0.5 : 1,
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPrimary, _kSecondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: _isProcessing ? null : _saveToGallery,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Simpan ke Galeri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementShareCard extends StatelessWidget {
  const _AchievementShareCard({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    const trophySize = 140.0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF8B5CF6),
            Color(0xFFA78BFA),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -40,
            right: -30,
            child: _GlowOrb(size: 140, opacity: 0.18),
          ),
          const Positioned(
            bottom: -50,
            left: -40,
            child: _GlowOrb(size: 160, opacity: 0.14),
          ),
          const Positioned(
            top: 72,
            left: 12,
            child: _ConfettiDot(color: Color(0xFFFFD700), size: 7),
          ),
          const Positioned(
            top: 36,
            right: 28,
            child: _ConfettiDot(color: Color(0xFFEC4899), size: 6),
          ),
          const Positioned(
            top: 110,
            right: 16,
            child: _ConfettiDot(color: Color(0xFF34D399), size: 5),
          ),
          const Positioned(
            bottom: 88,
            left: 20,
            child: _ConfettiDot(color: Color(0xFFFBBF24), size: 6),
          ),
          const Positioned(
            bottom: 120,
            right: 36,
            child: _ConfettiDot(color: Color(0xFF60A5FA), size: 5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBrandPill(),
                const SizedBox(height: 20),
                _buildHeadline(),
                const SizedBox(height: 8),
                _buildSubtitle(),
                const SizedBox(height: 22),
                _buildTrophySection(trophySize),
                const SizedBox(height: 18),
                _buildStreakBadge(),
                const SizedBox(height: 18),
                _buildQuote(),
                const SizedBox(height: 14),
                _buildHashtags(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 6),
          Text(
            'IbuSehat',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Aku Konsisten',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
            height: 1.1,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Text(
            '🔥',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text(
      '$streakDays hari penuh menjaga kesehatan',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.88),
        height: 1.35,
      ),
    );
  }

  Widget _buildTrophySection(double trophySize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: _TrophyWithStreak(
          streakDays: streakDays,
          trophySize: trophySize,
        ),
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$streakDays Hari Aktif',
            style: const TextStyle(
              color: _kAccent,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuote() {
    return Text(
      'Sedikit demi sedikit,\nhasil luar biasa akan datang.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.78),
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        height: 1.5,
      ),
    );
  }

  Widget _buildHashtags() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        _HashtagChip(label: '#IbuSehat'),
        _HashtagChip(label: '#SehatBahagiaKeluarga'),
      ],
    );
  }
}

class _HashtagChip extends StatelessWidget {
  const _HashtagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _TrophyWithStreak extends StatelessWidget {
  const _TrophyWithStreak({
    required this.streakDays,
    required this.trophySize,
  });

  final int streakDays;
  final double trophySize;

  @override
  Widget build(BuildContext context) {
    final glowSize = trophySize + 28;
    final iconSize = trophySize * 0.88;
    final fontSize = streakDays >= 100
        ? trophySize * 0.22
        : streakDays >= 10
            ? trophySize * 0.28
            : trophySize * 0.34;

    return SizedBox(
      width: glowSize,
      height: glowSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: glowSize,
            height: glowSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
          ),
          Container(
            width: glowSize - 16,
            height: glowSize - 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.28),
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.2, 0.6, 1.0],
              ),
            ),
          ),
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFF8DC),
                      Color(0xFFFFD700),
                      Color(0xFFE6A800),
                    ],
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: iconSize * 0.14),
                  child: Text(
                    '$streakDays',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                      shadows: const [
                        Shadow(
                          color: Color(0x99000000),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                        Shadow(
                          color: Color(0x66B8860B),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  const _ConfettiDot({required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 7,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
