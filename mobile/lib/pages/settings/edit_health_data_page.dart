import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/widgets/custom_toast.dart';

/// Halaman "Data Kesehatan". Dibuka dari Profil maupun dari popup HealthGate;
/// di-pop dengan `true` setelah data berhasil disimpan.
class EditHealthDataPage extends StatefulWidget {
  const EditHealthDataPage({super.key});

  @override
  State<EditHealthDataPage> createState() => _EditHealthDataPageState();
}

class _EditHealthDataPageState extends State<EditHealthDataPage> {
  final _formKey = GlobalKey<FormState>();

  final _targetWeightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  DateTime _deliveryDate = DateTime.now();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _targetWeightController.dispose();
    _currentWeightController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _fillForm(Map<String, dynamic> data) {
    _targetWeightController.text = _numberText(data['target_weight']);
    _currentWeightController.text = _numberText(data['weight']);
    _ageController.text = data['age']?.toString() ?? '';
    _heightController.text = _numberText(data['height']);

    final rawDate = data['delivery_date']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      _deliveryDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }
  }

  String _numberText(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      return value == value.roundToDouble()
          ? value.round().toString()
          : value.toString();
    }
    return value.toString();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await AuthService.instance.fetchProfile();
      if (!mounted) return;
      setState(() {
        _fillForm(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      CustomToast.show(context, 'Isi data kesehatan dengan benar', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await AuthService.instance.updateHealthProfile(
        height: double.parse(_heightController.text.trim()),
        weight: double.parse(_currentWeightController.text.trim()),
        targetWeight: double.parse(_targetWeightController.text.trim()),
        age: int.parse(_ageController.text.trim()),
        deliveryDate: _formatDate(_deliveryDate),
      );
      if (!mounted) return;
      CustomToast.show(context, 'Data kesehatan berhasil diperbarui');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF8B5CF6),
                    onPrimary: Colors.white,
                    surface: darkSurface,
                    onSurface: darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF8B5CF6),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF1F1235),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _deliveryDate) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  String? _requiredNumber(String? value, {required double min, required double max, required String label}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label wajib diisi';
    final number = double.tryParse(text);
    if (number == null) return '$label harus berupa angka';
    if (number < min || number > max) {
      return '$label harus antara ${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)}';
    }
    return null;
  }

  String? _requiredAge(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Umur wajib diisi';
    final number = int.tryParse(text);
    if (number == null) return 'Umur harus berupa angka';
    if (number < 12 || number > 80) return 'Umur harus antara 12–80 tahun';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Data Kesehatan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
            : _loadError != null
                ? _buildErrorState(textPrimary, textSecondary)
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data ini digunakan untuk menyesuaikan rekomendasi nutrisi, olahraga, dan perawatan kulit Anda.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildInputField(
                            label: 'Target Berat Badan',
                            controller: _targetWeightController,
                            unit: 'Kg',
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: (v) => _requiredNumber(v, min: 30, max: 200, label: 'Target berat badan'),
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            label: 'Berat Badan Saat Ini',
                            controller: _currentWeightController,
                            unit: 'Kg',
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: (v) => _requiredNumber(v, min: 30, max: 200, label: 'Berat badan'),
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            label: 'Umur',
                            controller: _ageController,
                            unit: 'Tahun',
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: _requiredAge,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            label: 'Tinggi Badan',
                            controller: _heightController,
                            unit: 'Cm',
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: (v) => _requiredNumber(v, min: 100, max: 220, label: 'Tinggi badan'),
                          ),
                          const SizedBox(height: 20),
                          _buildDateField(isDark),
                          const SizedBox(height: 60),
                          _buildSaveButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState(Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _loadError ?? 'Gagal memuat data kesehatan',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadProfile,
              child: const Text(
                'Coba lagi',
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required bool isDark,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : const Color(0x0D000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              suffixText: unit,
              suffixStyle: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(bool isDark) {
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final surface = isDark ? darkSurface : lightSurface;
    final border = isDark ? darkBorder : const Color(0x0D000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal Terakhir Melahirkan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMMM yyyy', 'id').format(_deliveryDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.edit_calendar_rounded, size: 20, color: textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return InkWell(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
