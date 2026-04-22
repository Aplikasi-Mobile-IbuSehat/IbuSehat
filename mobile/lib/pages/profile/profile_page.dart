import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/pages/auth/auth_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/widgets/app_background.dart';
import 'package:mobile/pages/profile/edit_health_data_page.dart';
import 'package:mobile/pages/profile/language_settings_page.dart';
import 'package:mobile/pages/skincare/skincare_page.dart';
import 'package:mobile/pages/calculator/bmi_calculator_page.dart';
import 'package:mobile/pages/profile/premium_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isNotificationEnabled = true;
  bool _isDarkMode = false;
  AuthUser? _user;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final cachedUser = await AuthService.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _user = cachedUser;
      _profileLoading = false;
    });

    final avatar = _avatarUrl();
    if (avatar.isNotEmpty) {
      unawaited(precacheImage(NetworkImage(avatar), context));
    }

    if (cachedUser == null && await AuthService.instance.isLoggedIn) {
      await AuthService.instance.syncUserFromApi();
      final freshUser = await AuthService.instance.currentUser;
      if (!mounted || freshUser == null) return;
      setState(() {
        _user = freshUser;
      });
      final freshAvatar = _avatarUrl();
      if (freshAvatar.isNotEmpty) {
        unawaited(precacheImage(NetworkImage(freshAvatar), context));
      }
    }
  }

  String _avatarUrl() {
    final u = _user;
    if (u?.avatarUrl != null && u!.avatarUrl!.isNotEmpty) {
      return u.avatarUrl!;
    }
    final name = Uri.encodeComponent(u?.name ?? 'User');
    return 'https://ui-avatars.com/api/?name=$name&background=8B5CF6&color=fff&size=256';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(),
                    const SizedBox(height: 32),
                    _buildPremiumCard(context),
                    const SizedBox(height: 40),
                    _buildSectionTitle('Lainnya'),
                    const SizedBox(height: 16),
                    _buildMenuTile(
                      icon: Icons.face_retouching_natural_rounded,
                      title: 'Skincare',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SkincarePage()),
                      ),
                    ),
                    _buildMenuTile(
                      icon: Icons.calculate_outlined,
                      title: 'Kalkulator Ideal',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BMICalculatorPage()),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Pengaturan Akun'),
                    const SizedBox(height: 16),
                    _buildMenuTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Data Kesehatan',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditHealthDataPage()),
                      ),
                    ),
                    _buildMenuTile(
                      icon: Icons.language_rounded,
                      title: 'Bahasa',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LanguageSettingsPage()),
                      ),
                    ),
                    _buildToggleTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifikasi',
                      value: _isNotificationEnabled,
                      onChanged: (val) => setState(() => _isNotificationEnabled = val),
                    ),
                    _buildToggleTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Tema',
                      value: _isDarkMode,
                      onChanged: (val) => setState(() => _isDarkMode = val),
                    ),
                    const SizedBox(height: 48),
                    _buildLogoutButton(),
                    const SizedBox(height: 120), // Space for navbar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return const SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false, 
      toolbarHeight: 20, // Small height since we don't have a title
    );
  }

  Widget _buildProfileHeader() {
    if (_profileLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Text(
              'Memuat profil…',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1235),
              ),
            ),
          ),
        ],
      );
    }

    final displayName = _user?.name ?? 'Pengguna';
    final email = _user?.email ?? '—';

    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            _avatarUrl(),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            cacheWidth: 320,
            cacheHeight: 320,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFE9D5FF),
              child: const Icon(Icons.person_rounded, size: 40, color: Color(0xFF8B5CF6)),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1235),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF1F1235).withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Premium Member',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Assistant Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Dapatkan Akses Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SvgPicture.asset(
              'assets/icons/sparkles_premium.svg',
              width: 60,
              height: 60,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDataList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          _buildHealthItem('Target Berat', '55 Kg', isFirst: true),
          _buildHealthItem('Berat Saat Ini', '65 Kg'),
          _buildHealthItem('Umur', '28 Tahun'),
          _buildHealthItem('Tinggi Badan', '162 Cm'),
          _buildHealthItem('Terakhir Melahirkan', '12 Jan 2026', isLast: true),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String label, String value, {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1235).withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1235),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1F1235),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1F1235).withOpacity(0.7), size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1235),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF1F1235).withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1F1235).withOpacity(0.7), size: 22),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1235),
            ),
          ),
          const Spacer(),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              activeColor: const Color(0xFF8B5CF6),
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Keluar Akun'),
            content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Keluar'),
                onPressed: () async {
                  Navigator.pop(context);
                  await AuthService.instance.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.red.withOpacity(0.05),
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: const Center(
          child: Text(
            'Keluar Akun',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
