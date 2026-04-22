import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/models/supplement.dart';

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

  // Image height for parallax hero
  static const double _kHeroHeight = 320.0;

  void _save() {
    final finalSupplement = widget.supplement.copyWith(reminderTime: _selectedTime);
    Navigator.pop(context, finalSupplement);
  }

  // ── Time picker — slides up from bottom ─────────────────────────────────
  void _showTimePickerSheet() {
    TimeOfDay tempTime = _selectedTime ?? TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // The default showModalBottomSheet already slides from bottom
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
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7C7CC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Waktu Konsumsi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 140,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildWheel(hourController, 24, tempTime.hour, (idx) {
                            setModalState(() => tempTime = TimeOfDay(hour: idx, minute: tempTime.minute));
                          }),
                          const Text(
                            ':',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: Color(0xFF1C1C1E)),
                          ),
                          _buildWheel(minuteController, 60, tempTime.minute, (idx) {
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
                        backgroundColor: const Color(0xFF007AFF),
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
                  color: isSelected ? const Color(0xFF1C1C1E) : const Color(0xFFC7C7CC),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Parallax Hero Image via SliverAppBar ─────────────────────────
          SliverAppBar(
            expandedHeight: _kHeroHeight,
            pinned: true,
            backgroundColor: const Color(0xFFF2F2F7),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Color(0xFF3A3A3C)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Tambah',
                      style: TextStyle(color: Color(0xFF007AFF), fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHeroImage(),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & source
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.supplement.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      if (widget.supplement.source.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.supplement.source,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Info sections
                if (!widget.isManual) ...[
                  _buildInfoSection('KOMPOSISI', widget.supplement.composition),
                  _buildInfoSection('KEMASAN', widget.supplement.packaging),
                  _buildInfoSection('ATURAN KONSUMSI', widget.supplement.rules),
                ],

                // Reminder section
                _buildSectionHeader('PENGINGAT'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _buildReminderTile(),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    final imageUrl = widget.supplement.imageUrl;
    return Container(
      width: double.infinity,
      height: _kHeroHeight,
      color: Colors.white,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain, // centered, not cropped
              alignment: Alignment.center,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8E8E93)),
              ),
              errorWidget: (context, url, error) => _buildImageFallback(),
            )
          : _buildImageFallback(),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Icon(Icons.medication_rounded, size: 80, color: Color(0xFFC7C7CC)),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    if (content.trim().isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(fontSize: 15, height: 1.55, fontWeight: FontWeight.w400, color: Color(0xFF1C1C1E)),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93), letterSpacing: 0.6),
      ),
    );
  }

  Widget _buildReminderTile() {
    return GestureDetector(
      onTap: _showTimePickerSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF007AFF)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waktu Konsumsi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 2),
                  Text(
                    _selectedTime != null ? _selectedTime!.format(context) : 'Belum diatur',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}
