import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/sleep_history_item.dart';
import 'package:mobile/pages/sleep/widgets/hasil_skor_tidur_dialog.dart';
import 'package:mobile/services/sleep_service.dart';

const _kPrimary = Color(0xFF7C3AED);
const _kDark = Color(0xFF1F1235);
const _kGrey = Color(0xFF9CA3AF);
const _kBg = Color(0xFFF8F9FB);
const _kChipBg = Color(0xFFEDE9FE);

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus riwayat?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _kDark,
          ),
        ),
        content: Text(
          'Riwayat tidur ${item.date} (${item.sleepDuration}) akan dihapus permanen.',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _kGrey,
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
          backgroundColor: _kDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } on SleepServiceException catch (e) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
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
          child: Center(
            child: CircularProgressIndicator(color: _kPrimary),
          ),
        );
      },
    );

    // Tunggu dialog benar-benar ada di navigator sebelum fetch selesai.
    await Future<void>.delayed(Duration.zero);

    try {
      final result = await _sleepService.fetchSleepLogDetail(logId);
      if (loadingContext?.mounted ?? false) {
        Navigator.of(loadingContext!).pop();
      }
      if (!mounted) return;
      await showHasilSkorTidurDialog(
        context,
        result.toDataMap(),
      );
    } on SleepServiceException catch (e) {
      if (loadingContext?.mounted ?? false) {
        Navigator.of(loadingContext!).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
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
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _kDark,
        ),
        centerTitle: true,
        title: const Text(
          'Riwayat Tidur',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _kDark,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: _deleteMode ? const Color(0xFFEF4444) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: (_items.isEmpty || _loading)
                        ? null
                        : () {
                            setState(() => _deleteMode = !_deleteMode);
                            if (_deleteMode) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pilih riwayat yang ingin dihapus'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: _deleteMode ? Colors.white : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: _kChipBg,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _togglePeriod,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _weeklyOnly ? 'Mingguan' : 'Semua',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: _kPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _kDark,
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
      return const Center(
        child: Text(
          'Belum ada riwayat tidur',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kGrey,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _HistoryCard(
          item: item,
          isDeleting: _deletingId == item.id,
          deleteMode: _deleteMode,
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
  });

  final SleepHistoryItem item;
  final VoidCallback onTap;
  final bool isDeleting;
  final bool deleteMode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: deleteMode ? const Color(0xFFEF4444) : Colors.grey.shade200,
          ),
        ),
        child: InkWell(
          onTap: isDeleting ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.date,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.sleepDuration,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${item.score}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _kDark,
                    ),
                  ),
                ),
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
