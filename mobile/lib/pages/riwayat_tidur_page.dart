import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/sleep_history_item.dart';
import 'package:mobile/pages/sleep/widgets/hasil_skor_tidur_dialog.dart';
import 'package:mobile/services/sleep_service.dart';
import 'package:mobile/theme/app_colors.dart';

const _kPrimary = Color(0xFF7C3AED);

class RiwayatTidurPage extends StatefulWidget {
  const RiwayatTidurPage({super.key});

  @override
  State<RiwayatTidurPage> createState() => _RiwayatTidurPageState();
}

class _RiwayatTidurPageState extends State<RiwayatTidurPage> {
  final _sleepService = SleepService();

  List<SleepHistoryItem> _items = [];
  bool _loading = true;
  String? _error;
  bool _weeklyOnly = true;
  bool _deleteMode = false;
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _sleepService.fetchHistory(
        period: _weeklyOnly ? 'weekly' : 'all',
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on SleepServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat riwayat tidur';
        _loading = false;
      });
    }
  }

  void _togglePeriod() {
    setState(() => _weeklyOnly = !_weeklyOnly);
    _loadHistory();
  }

  Future<void> _confirmAndDelete(SleepHistoryItem item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus riwayat?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        content: Text(
          'Riwayat tidur ${item.date} (${item.sleepDuration}) akan dihapus permanen.',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = item.id);

    try {
      await _sleepService.deleteSleepLog(item.id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((i) => i.id == item.id);
        _deletingId = null;
        _deleteMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Riwayat tidur dihapus',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on SleepServiceException catch (e) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus riwayat tidur')),
      );
    }
  }

  void _onCardTap(SleepHistoryItem item) {
    if (_deleteMode) {
      _confirmAndDelete(item);
    } else {
      _openDetail(item.id);
    }
  }

  Future<void> _openDetail(int logId) async {
    if (logId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data riwayat tidak valid')),
      );
      return;
    }

    BuildContext? loadingContext;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        loadingContext = dialogContext;
        return const PopScope(
          canPop: false,
          child:
              Center(child: CircularProgressIndicator(color: _kPrimary)),
        );
      },
    );

    await Future<void>.delayed(Duration.zero);

    try {
      final result = await _sleepService.fetchSleepLogDetail(logId);
      if (loadingContext?.mounted ?? false) {
        Navigator.of(loadingContext!).pop();
      }
      if (!mounted) return;
      await showHasilSkorTidurDialog(context, result.toDataMap());
    } on SleepServiceException catch (e) {
      if (loadingContext?.mounted ?? false) {
        Navigator.of(loadingContext!).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, st) {
      debugPrint('RiwayatTidurPage._openDetail: $e\n$st');
      if (loadingContext?.mounted ?? false) {
        Navigator.of(loadingContext!).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat detail tidur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: textPrimary),
        ),
        centerTitle: true,
        title: Text(
          'Riwayat Tidur',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          // Delete toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: (_items.isEmpty || _loading)
                  ? null
                  : () {
                      setState(() => _deleteMode = !_deleteMode);
                      if (_deleteMode) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ketuk riwayat untuk menghapus'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              icon: Icon(
                _deleteMode
                    ? Icons.delete_rounded
                    : Icons.delete_outline_rounded,
                color: _deleteMode
                    ? const Color(0xFFEF4444)
                    : textSecondary,
                size: 22,
              ),
            ),
          ),

          // Period toggle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _togglePeriod,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _weeklyOnly ? 'Mingguan' : 'Semua',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.swap_horiz_rounded,
                        size: 14, color: _kPrimary),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: border),
        ),
      ),
      body: _buildBody(
        isDark: isDark,
        bg: bg,
        surface: surface,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        border: border,
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required Color bg,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _kPrimary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: textSecondary),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadHistory,
                style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Belum ada riwayat tidur',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _HistoryCard(
          item: item,
          isDeleting: _deletingId == item.id,
          deleteMode: _deleteMode,
          isDark: isDark,
          surface: surface,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          border: border,
          onTap: () => _onCardTap(item),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.onTap,
    required this.isDeleting,
    required this.deleteMode,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  final SleepHistoryItem item;
  final VoidCallback onTap;
  final bool isDeleting;
  final bool deleteMode;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final activeBorder =
        deleteMode ? const Color(0xFFEF4444) : border;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: activeBorder),
          ),
          child: Row(
            children: [
              // Date & Duration
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.sleepDuration,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Score
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      '${item.score}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    Text(
                      'skor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Status
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        item.statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
