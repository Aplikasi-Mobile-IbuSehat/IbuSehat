import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/models/supplement.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/services/fcm_service.dart';

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
    final border = isDark ? darkBorder : const Color(0xFFEEEEEE);
    const kPrimary = Color(0xFF7C3AED);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        int tempHour = tempTime.hour;
        int tempMinute = tempTime.minute;
        final hourController = FixedExtentScrollController(initialItem: tempHour);
        final minuteController = FixedExtentScrollController(initialItem: tempMinute);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: isDark ? darkTextSecondary : Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          'Atur Pengingat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await FcmNotificationService.instance.checkAndPromptPermission(context);
                            if (mounted) {
                              setState(() {
                                _selectedTime = TimeOfDay(hour: tempHour, minute: tempMinute);
                              });
                            }
                          },
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: border),
                  const SizedBox(height: 8),
                  // Wheel picker with highlight strip
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 40,
                          right: 40,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: isDark ? 0.18 : 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 90,
                              child: ListWheelScrollView.useDelegate(
                                controller: hourController,
                                itemExtent: 48,
                                perspective: 0.004,
                                diameterRatio: 1.4,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (v) => setModalState(() => tempHour = v),
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 24,
                                  builder: (ctx, i) {
                                    final isSelected = tempHour == i;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 180),
                                        style: TextStyle(
                                          fontSize: isSelected ? 30 : 22,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                                          color: isSelected
                                              ? kPrimary
                                              : (isDark ? darkTextSecondary : Colors.grey.shade400),
                                        ),
                                        child: Text(i.toString().padLeft(2, '0')),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Text(
                              ':',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: ListWheelScrollView.useDelegate(
                                controller: minuteController,
                                itemExtent: 48,
                                perspective: 0.004,
                                diameterRatio: 1.4,
                                physics: const FixedExtentScrollPhysics(),
                                onSelectedItemChanged: (v) => setModalState(() => tempMinute = v),
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: 60,
                                  builder: (ctx, i) {
                                    final isSelected = tempMinute == i;
                                    return Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 180),
                                        style: TextStyle(
                                          fontSize: isSelected ? 30 : 22,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                                          color: isSelected
                                              ? kPrimary
                                              : (isDark ? darkTextSecondary : Colors.grey.shade400),
                                        ),
                                        child: Text(i.toString().padLeft(2, '0')),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
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
  // Supplement harus sudah di-log (punya logId) sebelum pengingat bisa diatur
  final bool isLogged = widget.supplement.logId != null && widget.supplement.logId!.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Tile untuk memilih waktu
      GestureDetector(
        onTap: () {
          if (!isLogged) {
            // Tampilkan pesan — harus tambah ke log dulu
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Tambahkan suplemen ke log terlebih dahulu untuk mengatur pengingat.',
                ),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
          _showTimePickerSheet(isDark, background, surface, textPrimary, textSecondary);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isLogged ? surface : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7)),
            borderRadius: BorderRadius.circular(12),
            border: isLogged
                ? null
                : Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
          ),
          child: Row(
            children: [
              Icon(
                isLogged ? Icons.access_time_rounded : Icons.lock_outline_rounded,
                size: 20,
                color: isLogged
                    ? const Color(0xFF8B5CF6)
                    : (isDark ? const Color(0xFF555555) : Colors.grey.shade400),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu Konsumsi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isLogged
                            ? textPrimary
                            : (isDark ? const Color(0xFF555555) : Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLogged
                          ? (_selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Belum diatur')
                          : 'Tambah ke log dulu',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF444444) : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isLogged
                    ? textSecondary
                    : (isDark ? const Color(0xFF444444) : Colors.grey.shade300),
              ),
            ],
          ),
        ),
      ),

      // Info badge jika belum di-log
      if (!isLogged) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5EA),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15,
                  color: isDark ? const Color(0xFF555555) : Colors.grey.shade400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tekan "Tambah" di pojok kanan atas, lalu atur pengingat.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF555555) : Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],

      // Badge pengingat aktif — hanya tampil jika sudah di-log dan ada waktu
      if (isLogged && _selectedTime != null) ...[
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
