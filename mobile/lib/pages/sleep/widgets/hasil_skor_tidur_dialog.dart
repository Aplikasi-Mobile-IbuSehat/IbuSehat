import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF7C3AED);
const _kDark = Color(0xFF1F1235);
const _kGreyText = Color(0xFF6B7280);
const _kAnalysisBg = Color(0xFFF3EEFF);
const _kIconBg = Color(0xFFEDE9FE);

String _sleepDataStr(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return '-';
  return value.toString();
}

int _sleepDataInt(Map<String, dynamic> data, String key) =>
    (data[key] as num?)?.toInt() ?? 0;

/// Menampilkan dialog Hasil Skor Tidur (slide-up) dengan data dari API / hasil hitung.
Future<void> showHasilSkorTidurDialog(
  BuildContext context,
  Map<String, dynamic> data, {
  bool showLihatRiwayatButton = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup dialog hasil skor tidur',
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 350),
    useRootNavigator: true,
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        HasilSkorTidurCard(
      data: data,
      showLihatRiwayatButton: showLihatRiwayatButton,
    ),
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: child,
      );
    },
  );
}

class HasilSkorTidurCard extends StatefulWidget {
  const HasilSkorTidurCard({
    super.key,
    required this.data,
    this.showLihatRiwayatButton = false,
  });

  final Map<String, dynamic> data;
  final bool showLihatRiwayatButton;

  @override
  State<HasilSkorTidurCard> createState() => _HasilSkorTidurCardState();
}

class _HasilSkorTidurCardState extends State<HasilSkorTidurCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    final score = _sleepDataInt(widget.data, 'score');

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: score / 100).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Widget _buildCardSkorUtama() {
    final data = widget.data;
    final score = _sleepDataInt(data, 'score');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, _) {
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: _progressAnim.value,
                          strokeWidth: 7,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sleepDataStr(data, 'category'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _sleepDataStr(data, 'category_message'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required String statusLabel,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: _kPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kDark,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  statusLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 12,
            endIndent: 12,
          ),
      ],
    );
  }

  Widget _buildCardStatistik() {
    final data = widget.data;
    final moodLabel = data['mood_label'] as String?;
    final moodEmoji = data['mood_emoji'] as String?;
    final hasMood = moodLabel != null && moodLabel.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            _buildStatRow(
              icon: Icons.access_time_rounded,
              label: 'Durasi Tidur',
              value: _sleepDataStr(data, 'sleep_duration'),
              statusLabel: _sleepDataStr(data, 'sleep_duration_range'),
              showDivider: true,
            ),
            _buildStatRow(
              icon: Icons.nightlight_round,
              label: 'Konsistensi',
              value: '${_sleepDataInt(data, 'consistency_percent')}%',
              statusLabel: _sleepDataStr(data, 'consistency_label'),
              showDivider: true,
            ),
            _buildStatRow(
              icon: Icons.bedtime_outlined,
              label: 'Terbangun',
              value: '${_sleepDataInt(data, 'night_wakings')} kali',
              statusLabel: _sleepDataStr(data, 'night_wakings_label'),
              showDivider: true,
            ),
            _buildStatRow(
              icon: Icons.trending_up_rounded,
              label: 'Utang Tidur',
              value: _sleepDataStr(data, 'sleep_debt'),
              statusLabel: _sleepDataStr(data, 'sleep_debt_label'),
              showDivider: hasMood,
            ),
            if (hasMood)
              _buildStatRow(
                icon: Icons.sentiment_satisfied_alt_rounded,
                label: 'Mood',
                value: moodEmoji ?? '',
                statusLabel: moodLabel,
                showDivider: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAnalisis() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kAnalysisBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analisis',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _sleepDataStr(widget.data, 'analysis'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kGreyText,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black26,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      color: _kDark,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Hasil Skor Tidur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _kDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCardSkorUtama(),
                      const SizedBox(height: 12),
                      _buildCardStatistik(),
                      const SizedBox(height: 12),
                      _buildCardAnalisis(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (widget.showLihatRiwayatButton) {
                                Navigator.pushNamed(
                                  context,
                                  '/riwayat-tidur',
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.showLihatRiwayatButton
                                  ? 'Lihat Riwayat'
                                  : 'Tutup',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
