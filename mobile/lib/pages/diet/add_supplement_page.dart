import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/api_config.dart';
import 'package:mobile/models/supplement.dart';
import 'package:mobile/pages/diet/supplement_detail_page.dart';
import 'package:mobile/services/api_cache_manager.dart';

class AddSupplementPage extends StatefulWidget {
  final Supplement? supplement;
  const AddSupplementPage({super.key, this.supplement});

  @override
  State<AddSupplementPage> createState() => _AddSupplementPageState();
}

class _AddSupplementPageState extends State<AddSupplementPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Supplement> _supplements = [];
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.supplement != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SupplementDetailPage(supplement: widget.supplement!)),
        );
        if (result != null && mounted) {
          Navigator.pop(context, result);
        } else if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  Future<void> _fetchSupplements({String? search}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final params = <String, String>{'per_page': '50', 'match_mode': 'contains'};
      if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/supplements').replace(queryParameters: params);
      
      final cacheKey = uri.toString();
      final data = await ApiCacheManager.instance.getOrFetch(cacheKey, () async {
        final response = await http.get(uri);
        if (response.statusCode != 200) throw Exception('Gagal memuat suplemen');
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['data'] as List<dynamic>? ?? <dynamic>[];
      });

      final items = (data as List<dynamic>)
          .map((e) => Supplement.fromJson(e as Map<String, dynamic>, baseUrl: ApiConfig.baseUrl))
          .toList();

      if (!mounted) return;
      setState(() { _supplements = items; _isLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = 'Tidak dapat memuat data suplemen'; });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh suffix icon
    if (value.trim().isEmpty) {
      _debounce?.cancel();
      setState(() { _supplements = []; _error = null; _isLoading = false; });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _fetchSupplements(search: value));
  }

  Future<void> _openDetail(Supplement supplement) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupplementDetailPage(supplement: supplement)),
    );
    if (result != null && mounted) Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Panggil super.build untuk meregister KeepAlive
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
          'Cari Suplemen',
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E), fontSize: 17, letterSpacing: -0.3),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search Bar (properly aligned using Row) ──────────────────────
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
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w400),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama produk suplemen…',
                        hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 15, fontWeight: FontWeight.w400),
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
    if (_supplements.isEmpty) return _buildNotFound();
    return _buildList();
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 48, color: Color(0xFFC7C7CC)),
          const SizedBox(height: 12),
          const Text('Ketik nama suplemen untuk mencari',
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
            onTap: () => _fetchSupplements(search: _searchController.text),
            child: const Text('Coba lagi', style: TextStyle(color: Color(0xFF007AFF), fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Text('Produk tidak ditemukan', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _supplements.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final supplement = _supplements[index];
        final isLast = index == _supplements.length - 1;
        return GestureDetector(
          onTap: () => _openDetail(supplement),
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
                            // Marquee for long supplement names
                            _MarqueeText(
                              text: supplement.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1C1C1E)),
                            ),
                            if (supplement.packaging.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(supplement.packaging,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _openDetail(supplement),
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

  const _MarqueeText({required this.text, required this.style, this.velocity = 30.0});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _needsMarquee = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
      await Future.delayed(const Duration(seconds: 1));
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
