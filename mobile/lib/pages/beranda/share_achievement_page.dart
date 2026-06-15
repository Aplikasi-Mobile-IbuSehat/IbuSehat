import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const _kPrimary = Color(0xFF6C4DFF);
const _kSecondary = Color(0xFF8B5CF6);
const _kBg = Color(0xFFFAFAFC);
const _kCard = Color(0xFFFFFFFF);

class ShareAchievementPage extends StatefulWidget {
  final int streakDays;

  const ShareAchievementPage({super.key, required this.streakDays});

  @override
  State<ShareAchievementPage> createState() => _ShareAchievementPageState();
}

class _ShareAchievementPageState extends State<ShareAchievementPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isProcessing = false;

  Future<String?> _captureImage() async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/streak_${widget.streakDays}_hari.png';
      
      final image = await _screenshotController.capture();
      if (image == null) return null;

      final file = File(imagePath);
      await file.writeAsBytes(image);
      return imagePath;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _isProcessing = true);
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        await ImageGallerySaverPlus.saveImage(
          image,
          quality: 100,
          name: "IbuSehat_Streak_${widget.streakDays}",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berhasil disimpan ke Galeri!')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _shareToPlatform(String platform, {String? text}) async {
    setState(() => _isProcessing = true);
    try {
      final imagePath = await _captureImage();
      if (imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: text,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bagikan Pencapaian',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    _buildShareCard(),
                    const SizedBox(height: 32),
                    const Text(
                      'Bagikan ke media sosial',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSocialButtons(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _saveToGallery,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isProcessing 
                    ? const SizedBox(
                        width: 24, height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text(
                        'Simpan ke Galeri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF4EEFF),
              Color(0xFFE9DDFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          children: [
            // Confetti decoration
            Positioned(
              top: 20,
              left: 20,
              child: _buildConfetti(const Color(0xFF6C4DFF)),
            ),
            Positioned(
              top: 40,
              right: 30,
              child: _buildConfetti(const Color(0xFFEC4899)),
            ),
            Positioned(
              bottom: 120,
              left: 40,
              child: _buildConfetti(const Color(0xFFFBBF24)),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'IbuSehat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aku konsisten!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _kPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.streakDays} hari penuh menjaga kesehatan 💜',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Trophy
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6DAFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 90,
                        color: Color(0xFFFFD700),
                      ),
                      Positioned(
                        bottom: 30,
                        child: Text(
                          '${widget.streakDays}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: -10),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.streakDays} Hari Aktif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Sedikit demi sedikit,\nhasil luar biasa akan datang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '#IbuSehat\n#SehatBahagiaKeluarga',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _kPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Character illustration
                  Image.asset(
                    'assets/images/ibu_character.png',
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIconButton(
          icon: FontAwesomeIcons.instagram,
          color: const Color(0xFFE1306C),
          onTap: () => _shareToPlatform('Instagram'),
        ),
        const SizedBox(width: 20),
        _buildIconButton(
          icon: FontAwesomeIcons.whatsapp,
          color: const Color(0xFF25D366),
          onTap: () => _shareToPlatform('WhatsApp', text: 'Lihat pencapaian ${widget.streakDays} hari berturut-turut di aplikasi IbuSehat! #IbuSehat'),
        ),
        const SizedBox(width: 20),
        _buildIconButton(
          icon: FontAwesomeIcons.facebookF,
          color: const Color(0xFF1877F2),
          onTap: () => _shareToPlatform('Facebook'),
        ),
        const SizedBox(width: 20),
        _buildIconButton(
          icon: FontAwesomeIcons.xTwitter,
          color: Colors.black,
          onTap: () => _shareToPlatform('Twitter', text: 'Lihat pencapaian ${widget.streakDays} hari berturut-turut di aplikasi IbuSehat! #IbuSehat'),
        ),
        const SizedBox(width: 20),
        _buildIconButton(
          icon: Icons.more_horiz,
          color: Colors.grey.shade700,
          onTap: () => _shareToPlatform('Lainnya'),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
