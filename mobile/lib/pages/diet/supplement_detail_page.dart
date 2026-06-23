import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/models/supplement.dart';
import 'package:mobile/theme/app_colors.dart';

class SupplementDetailPage extends StatefulWidget {
  final Supplement supplement;
  final bool isManual;

  const SupplementDetailPage({
    super.key,
    required this.supplement,
    this.isManual = false,
  });

  @override
  State<SupplementDetailPage> createState() => _SupplementDetailPageState();
}

class _SupplementDetailPageState extends State<SupplementDetailPage> {
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.supplement.reminderTime;
  }

  void _save() {
    final finalSupplement = widget.supplement.copyWith(reminderTime: _selectedTime);
    Navigator.pop(context, finalSupplement);
  }

  // ── Time picker — slides up from bottom ─────────────────────────────────
  void _showTimePickerSheet(bool isDark, Color background, Color surface, Color textPrimary, Color textSecondary) {
    TimeOfDay tempTime = _selectedTime ?? TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final FixedExtentScrollController hourController =
                FixedExtentScrollController(initialItem: tempTime.hour);
            final FixedExtentScrollController minuteController =
                FixedExtentScrollController(initialItem: tempTime.minute);

            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24,
                  24 + MediaQuery.of(ctx).viewInsets.bottom),
              decoration: BoxDecoration(
                color: background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? darkBorder : const Color(0xFFC7C7CC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Waktu Konsumsi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 140,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildWheel(hourController, 24, tempTime.hour, textPrimary, textSecondary, (idx) {
                            setModalState(() => tempTime = TimeOfDay(hour: idx, minute: tempTime.minute));
                          }),
                          Text(
                            ':',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: textPrimary),
                          ),
                          _buildWheel(minuteController, 60, tempTime.minute, textPrimary, textSecondary, (idx) {
                            setModalState(() => tempTime = TimeOfDay(hour: tempTime.hour, minute: idx));
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _selectedTime = tempTime);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWheel(
    FixedExtentScrollController ctrl,
    int count,
    int current,
    Color textPrimary,
    Color textSecondary,
    Function(int) onSelected,
  ) {
    return SizedBox(
      width: 64,
      child: ListWheelScrollView.useDelegate(
        controller: ctrl,
        itemExtent: 46,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, idx) {
            final isSelected = idx == current;
            return Center(
              child: Text(
                idx.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: isSelected ? 22 : 17,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? textPrimary : textSecondary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final background = isDark ? darkBackground : const Color(0xFFF2F2F7);
    final surface = isDark ? darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Detail Suplemen',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
        TextButton(
          onPressed: _save,
          child: Text(
            // Kalau supplement sudah punya logId berarti sedang edit, bukan tambah
            widget.supplement.logId != null ? 'Simpan' : 'Tambah',
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildHeroImage(isDark, surface, textSecondary),
            ),
            
            // Name & source
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.supplement.name,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  if (widget.supplement.source.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.supplement.source,
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Info sections
            if (!widget.isManual) ...[
              _buildInfoSection('KOMPOSISI', widget.supplement.composition, surface, textPrimary, textSecondary),
              _buildInfoSection('KEMASAN', widget.supplement.packaging, surface, textPrimary, textSecondary),
              _buildInfoSection('ATURAN KONSUMSI', widget.supplement.rules, surface, textPrimary, textSecondary),
            ],

            // Reminder section
            _buildSectionHeader('PENGINGAT', textSecondary),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildReminderTile(isDark, background, surface, textPrimary, textSecondary),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(bool isDark, Color surface, Color textSecondary) {
    final imageUrl = widget.supplement.imageUrl;
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain, // centered, not cropped
                alignment: Alignment.center,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: textSecondary),
                ),
                errorWidget: (context, url, error) => _buildImageFallback(surface, textSecondary),
              )
            : _buildImageFallback(surface, textSecondary),
      ),
    );
  }

  Widget _buildImageFallback(Color surface, Color textSecondary) {
    return Container(
      color: surface,
      child: Center(
        child: Icon(Icons.medication_rounded, size: 80, color: textSecondary.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, Color surface, Color textPrimary, Color textSecondary) {
    if (content.trim().isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, textSecondary),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: TextStyle(fontSize: 15, height: 1.55, fontWeight: FontWeight.w400, color: textPrimary),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String label, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 0.6),
      ),
    );
  }

Widget _buildReminderTile(bool isDark, Color background, Color surface,
    Color textPrimary, Color textSecondary) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Tile untuk memilih waktu
      GestureDetector(
        onTap: () => _showTimePickerSheet(
            isDark, background, surface, textPrimary, textSecondary),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration:
              BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 20, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waktu Konsumsi',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Belum diatur',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: textSecondary),
            ],
          ),
        ),
      ),

      if (_selectedTime != null) ...[
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  size: 18, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pengingat aktif pukul ${_selectedTime!.format(context)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
              // Tombol hapus pengingat
              GestureDetector(
                onTap: () => setState(() => _selectedTime = null),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFF8B5CF6)),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}
}
