import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/food.dart';
import 'package:mobile/pages/diet/food_detail_page.dart';
import 'package:mobile/services/api_cache_manager.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Food> _foods = [];
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchFoods({String? search}) async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final params = <String, String>{'match_mode': 'contains'};
      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/foods').replace(queryParameters: params);
      
      final cacheKey = uri.toString();
      final data = await ApiCacheManager.instance.getOrFetch(cacheKey, () async {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['data'] as List<dynamic>;
        }
        throw Exception('Gagal memuat data');
      });

      if (mounted) {
        setState(() { 
          _foods = (data as List<dynamic>).map((e) => Food.fromJson(e)).toList(); 
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = 'Tidak dapat terhubung ke internet: $e'; });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {}); // refresh suffix icon
    if (query.trim().isEmpty) {
      setState(() { _foods = []; _error = null; _isLoading = false; });
      return;
    }
    _fetchFoods(search: query);
  }

  Future<void> _openDetail(Food food) async {
    final result = await Navigator.push<Food>(
      context,
      MaterialPageRoute(builder: (context) => FoodDetailPage(food: food)),
    );
    if (result != null && mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib dipanggil untuk AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF3A3A3C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cari Makanan',
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E), fontSize: 17, letterSpacing: -0.3),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search Bar (properly aligned) ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.search, color: Color(0xFF8E8E93), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w400),
                      decoration: InputDecoration(
                        hintText: 'Cari makanan…',
                        hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15, fontWeight: FontWeight.w400),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () { _searchController.clear(); _onSearchChanged(''); },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.cancel, color: Color(0xFF8E8E93), size: 16),
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_searchController.text.trim().isEmpty) return _buildEmptyPrompt();
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_foods.isEmpty) return _buildNotFound();
    return _buildList();
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 48, color: Color(0xFFC7C7CC)),
          const SizedBox(height: 12),
          const Text('Ketik nama makanan untuk mencari',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF636366))),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFC7C7CC)),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _fetchFoods(search: _searchController.text),
            child: const Text('Coba lagi',
                style: TextStyle(color: Color(0xFF007AFF), fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Text('Makanan tidak ditemukan', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _foods.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final food = _foods[index];
        final isLast = index == _foods.length - 1;
        return GestureDetector(
          onTap: () => _openDetail(food),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: index == 0 ? const Radius.circular(12) : Radius.zero,
                bottom: isLast ? const Radius.circular(12) : Radius.zero,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Auto-scroll marquee for long names
                            _MarqueeText(
                              text: food.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1C1C1E)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${food.weight.toStringAsFixed(0)} g  ·  ${food.kcal.toStringAsFixed(0)} kkal',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _openDetail(food),
                        child: const Icon(Icons.add, size: 22, color: Color(0xFF007AFF)),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5EA)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Marquee Text Widget ──────────────────────────────────────────────────────
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double velocity;

  const _MarqueeText({required this.text, required this.style, this.velocity = 30.0}); // ignore: unused_element

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;
  bool _needsMarquee = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    WidgetsBinding.instance.addPostFrameCallback(_startIfNeeded);
  }

  void _startIfNeeded(Duration _) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      setState(() => _needsMarquee = true);
      _scrollLoop();
    }
  }

  Future<void> _scrollLoop() async {
    while (mounted && _needsMarquee) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;
      final duration = Duration(milliseconds: (maxScroll / widget.velocity * 1000).round());
      await _scrollController.animateTo(maxScroll, duration: duration, curve: Curves.linear);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}
