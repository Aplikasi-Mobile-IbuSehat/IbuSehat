import 'package:flutter/material.dart';
import 'package:mobile/widgets/app_background.dart';
import 'package:intl/intl.dart';

class EditHealthDataPage extends StatefulWidget {
  const EditHealthDataPage({super.key});

  @override
  State<EditHealthDataPage> createState() => _EditHealthDataPageState();
}

class _EditHealthDataPageState extends State<EditHealthDataPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Contollers with initial mocked values
  final _targetWeightController = TextEditingController(text: '55');
  final _currentWeightController = TextEditingController(text: '65');
  final _ageController = TextEditingController(text: '28');
  final _heightController = TextEditingController(text: '162');
  DateTime _deliveryDate = DateTime(2026, 1, 12);

  @override
  void dispose() {
    _targetWeightController.dispose();
    _currentWeightController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Edit Data Kesehatan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F1235),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F1235), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data ini digunakan untuk menyesuaikan rekomendasi nutrisi, olahraga, dan perawatan kulit Anda.',
                    style: TextStyle(
                      color: const Color(0xFF1F1235).withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInputField(
                    label: 'Target Berat Badan',
                    controller: _targetWeightController,
                    unit: 'Kg',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Berat Badan Saat Ini',
                    controller: _currentWeightController,
                    unit: 'Kg',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Umur',
                    controller: _ageController,
                    unit: 'Tahun',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Tinggi Badan',
                    controller: _heightController,
                    unit: 'Cm',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tanggal Terakhir Melahirkan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1235),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMMM yyyy', 'id').format(_deliveryDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1235),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar_rounded, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildSaveButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1235),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              suffixText: unit,
              suffixStyle: TextStyle(
                color: const Color(0xFF1F1235).withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return InkWell(
      onTap: () {
        if (_formKey.currentState!.validate()) {
          // Implement save logic here
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data kesehatan berhasil diperbarui'),
              backgroundColor: Color(0xFF8B5CF6),
            ),
          );
        }
      },
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
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
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
