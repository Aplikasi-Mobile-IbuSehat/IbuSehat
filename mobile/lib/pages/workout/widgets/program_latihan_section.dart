import 'package:flutter/material.dart';
import 'package:mobile/models/workout_program_model.dart';
import 'package:mobile/pages/payments/premium_page.dart';
import 'package:mobile/pages/workout/widgets/workout_program_card.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/workout_program_service.dart';
import 'package:mobile/theme/app_colors.dart';

class ProgramLatihanSection extends StatefulWidget {
  const ProgramLatihanSection({super.key});

  @override
  State<ProgramLatihanSection> createState() => _ProgramLatihanSectionState();
}

class _ProgramLatihanSectionState extends State<ProgramLatihanSection> {
  late Future<List<WorkoutProgramModel>> _futurePrograms;
  bool _isPremium = false;
  bool _statusLoaded = false;

  void _loadPrograms() {
    setState(() {
      _futurePrograms = WorkoutProgramService.fetchPrograms();
    });
  }

  @override
  void initState() {
    super.initState();
    _futurePrograms = WorkoutProgramService.fetchPrograms();

    // Baca nilai awal dari cache.
    final cached = AuthService.instance.cachedUserSync;
    _isPremium = cached?.isPremium ?? false;
    _statusLoaded = cached != null;

    // Dengarkan perubahan user (mis. setelah pembayaran premium).
    AuthService.instance.userNotifier.addListener(_onUserChanged);

    // Sync ke API di background untuk memastikan status premium fresh.
    _syncPremiumInBackground();
  }

  void _onUserChanged() {
    if (!mounted) return;
    final user = AuthService.instance.userNotifier.value;
    final newPremium = user?.isPremium ?? false;
    setState(() {
      _isPremium = newPremium;
      _statusLoaded = true;
    });
  }

  Future<void> _syncPremiumInBackground() async {
    if (!await AuthService.instance.isLoggedIn) {
      if (mounted) setState(() => _statusLoaded = true);
      return;
    }
    await AuthService.instance.syncUserFromApi();
    // _onUserChanged dipanggil otomatis oleh listener di atas.
    if (!mounted) return;
    // Pastikan statusLoaded juga true jika listener belum dipanggil.
    if (!_statusLoaded) setState(() => _statusLoaded = true);
  }

  @override
  void dispose() {
    AuthService.instance.userNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Program Latihan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        if (!_statusLoaded)
          _buildLoadingState(isDark)
        else if (!_isPremium)
          _buildPremiumLockState(isDark, surface, border, textSecondary)
        else
          FutureBuilder<List<WorkoutProgramModel>>(
            future: _futurePrograms,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(isDark);
              }

              if (snapshot.hasError) {
                debugPrint('ProgramLatihanSection: error=${snapshot.error}');
                return _buildErrorState(snapshot.error, isDark, surface, border, textSecondary);
              }

              final programs = snapshot.data ?? [];
              if (programs.isEmpty) {
                return Text(
                  'Belum ada program',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                );
              }

              return ListView.builder(
                itemCount: programs.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) =>
                    WorkoutProgramCard(program: programs[index]),
              );
            },
          ),
      ],
    );
  }

  Widget _buildErrorState(
    Object? error,
    bool isDark,
    Color surface,
    Color border,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gagal memuat program latihan.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadPrograms,
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF7C3AED), size: 16),
              label: const Text(
                'Coba lagi',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    final shimmer = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    return ListView.separated(
      itemCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? darkSurface : lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? darkBorder : const Color(0xFFF0F0F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: 140,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: 80,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumLockState(
    bool isDark,
    Color surface,
    Color border,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4C1D95).withOpacity(0.3) : const Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF8B5CF6),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Fitur Premium',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? darkTextPrimary : lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tingkatkan ke Premium untuk mengakses\nsemua program latihan eksklusif.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PremiumPage()),
                );
                // Setelah kembali dari PremiumPage, sync ulang status premium.
                // userNotifier listener akan memperbarui _isPremium otomatis.
                if (mounted) _syncPremiumInBackground();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Upgrade Sekarang',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
