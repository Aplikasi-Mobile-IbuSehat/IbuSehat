import 'package:flutter/material.dart';
import 'package:mobile/models/food.dart';
import 'package:mobile/pages/diet/food_detail_page.dart';
import 'package:mobile/widgets/app_background.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Food> _searchResults = [];

  final List<Food> _dummyFoods = [
    Food(id: 'f1', name: 'Mie Goreng Spesial', weight: 200, kcal: 400, protein: 12, fat: 15, carbs: 54),
    Food(id: 'f2', name: 'Mie Goreng Instan', weight: 85, kcal: 380, protein: 8, fat: 14, carbs: 52),
    Food(id: 'f3', name: 'Mie Goreng Jawa', weight: 250, kcal: 450, protein: 15, fat: 18, carbs: 58),
  ];

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    // Simulate search logic
    final results = _dummyFoods
        .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    setState(() {
      _searchResults = results;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Cari Makanan',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1235),
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F1235),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: AppBackground(child: SafeArea(child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Cari makanan (misal: mie goreng)',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8B5CF6)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _searchResults.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(),
          ),
        ],
      ))),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Ketik nama makanan untuk mencari'
                : 'Makanan tidak ditemukan',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('🍜', style: TextStyle(fontSize: 24)),
              ),
            ),
            title: Text(
              food.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1F1235)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${food.weight.toStringAsFixed(0)}g  •  ${food.kcal.toStringAsFixed(0)} kcal',
                style: TextStyle(
                    color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            trailing: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FoodDetailPage(food: food)),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        );
      },
    );
  }
}
