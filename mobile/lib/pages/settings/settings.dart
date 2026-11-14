import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/pages/auth/auth_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/pages/settings/edit_health_data_page.dart';
import 'package:mobile/pages/skincare/skincare_page.dart';
import 'package:mobile/pages/settings/bmi_calculator/bmi_calculator_page.dart';
import 'package:mobile/pages/payments/premium_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  bool _isNotificationEnabled = false;
  AuthUser? _user;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen perubahan user dari AuthService (misal: setelah pembayaran premium)
    // sehingga UI langsung rebuild tanpa perlu reload manual.
    AuthService.instance.userNotifier.addListener(_onUserChanged);
    _loadUser();
    _checkNotificationPermission();
  }

  void _onUserChanged() {
    final updatedUser = AuthService.instance.userNotifier.value;
    if (!mounted || updatedUser == null) return;
    setState(() {
      _user = updatedUser;
      _profileLoading = false;
    });
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _isNotificationEnabled = status.isGranted;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  @override
  void dispose() {
    AuthService.instance.userNotifier.removeListener(_onUserChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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

    if (await AuthService.instance.isLoggedIn) {
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

  bool get _isPremium => _user?.isPremium ?? false;

  String _avatarUrl() {
    final u = _user;
    if (u?.avatarUrl != null && u!.avatarUrl!.isNotEmpty) {
      return u.avatarUrl!;
    }
    final name = Uri.encodeComponent(u?.name ?? 'User');
    return 'https://ui-avatars.com/api/?name=$name&background=E5E7EB&color=374151&size=256';
  }

  Future<bool?> _showLogoutBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(bottom: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 8),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: isDark ? Colors.redAccent.shade100 : Colors.red,
                  size: 28,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Keluar dari akun?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Kamu akan keluar dari sesi ini. Data dan progres kamu tetap tersimpan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Divider(
                height: 0.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),

              const SizedBox(height: 20),

              // Tombol keluar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Ya, keluar sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tombol batal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white60 : Colors.black54,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);

    final confirmed = await _showLogoutBottomSheet();

    if (confirmed != true) return;
    if (!mounted) return;

    await AuthService.instance.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final borderColor = isDark ? darkBorder : lightBorder;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
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
                  if (!_profileLoading && !_isPremium) ...[
                    const SizedBox(height: 32),
                    _buildPremiumCard(context),
                  ],
                  const SizedBox(height: 40),
                  _buildSectionTitle('Lainnya'),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    icon: Icons.face_retouching_natural_rounded,
                    title: 'Skincare',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SkincarePage(),
                      ),
                    ),
                  ),
                  _buildMenuTile(
                    icon: Icons.calculate_outlined,
                    title: 'Kalkulator Ideal',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BMICalculatorPage(),
                      ),
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
                      MaterialPageRoute(
                        builder: (context) => const EditHealthDataPage(),
                      ),
                    ),
                  ),
                  
                  _buildToggleTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifikasi',
                    value: _isNotificationEnabled,
                    onChanged: (val) async {
                      if (val && !_isNotificationEnabled) {
                        // Minta izin
                        final result = await Permission.notification.request();
                        if (result.isGranted) {
                          setState(() => _isNotificationEnabled = true);
                        } else if (result.isPermanentlyDenied) {
                          await AppSettings.openAppSettings(type: AppSettingsType.notification);
                        }
                      } else if (!val && _isNotificationEnabled) {
                        // Buka pengaturan karena kita tidak bisa revoke secara programatis
                        await AppSettings.openAppSettings(type: AppSettingsType.notification);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildThemeSelector(
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 48),
                  _buildLogoutButton(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
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
      toolbarHeight: 20,
    );
  }

  Widget _buildProfileHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    if (_profileLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              'Memuat profil…',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
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
              child: const Icon(
                Icons.person_rounded,
                size: 40,
                color: Color(0xFF8B5CF6),
              ),
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              if (_isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
              color: const Color(0xFF9333EA).withValues(alpha: 0.3),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
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
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: isDark ? darkTextPrimary : lightTextPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final iconColor = isDark ? darkIcon : lightIcon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? darkTextSecondary : lightTextSecondary,
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
    required ValueChanged<bool>? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final iconColor = isDark ? darkIcon : lightIcon;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const Spacer(),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              activeTrackColor: const Color(0xFFA855F7),
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector({
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? darkIcon : lightIcon;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.palette_outlined, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Text(
            'Mode Tampilan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _themeIcon(Icons.light_mode_rounded, AppThemePreference.light),
                _themeIcon(Icons.dark_mode_rounded, AppThemePreference.dark),
                _themeIcon(
                  Icons.phone_android_rounded,
                  AppThemePreference.system,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeIcon(IconData icon, AppThemePreference pref) {
    final isSelected = appThemeController.preference == pref;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        await appThemeController.setPreference(pref);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA855F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : (isDark ? darkIcon : lightIcon),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: _handleLogout,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            SizedBox(width: 16),
            Text(
              'Keluar Akun',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
