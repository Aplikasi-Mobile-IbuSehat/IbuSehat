import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/pages/payments/premium_page.dart';
import 'package:mobile/widgets/app_header_actions.dart';
import '../../services/api_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  final List<Message> _messages = [];
  bool _isLoading = false;

  /// Riwayat percakapan dalam format role/text untuk dikirim ke backend.
  /// Backend menerapkan sliding window (4 pasangan terakhir), jadi di sisi
  /// Flutter cukup simpan seluruh riwayat sesi ini.
  final List<Map<String, String>> _history = [];

  /// Sisa kuota chat harian (diisi dari respons backend setelah chat pertama).
  int? _quotaUsed;
  int? _quotaLimit;

  static const String _greetingText =
      'Halo 👋 Saya Asisten Ibusehat. Hari ini Anda sudah makan atau minum suplemen apa?';

  @override
  void initState() {
    super.initState();
    // Tampilkan sapaan pembuka dari AI tanpa memanggil backend, sekaligus
    // dicatat ke history agar Gemini tahu giliran pertama adalah miliknya.
    _messages.insert(
      0,
      Message(text: _greetingText, isAi: true, timestamp: DateTime.now()),
    );
    _history.add({'role': 'model', 'text': _greetingText});
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = Message(
      text: text,
      isAi: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await _apiService.sendChatMessage(
        text,
        history: List<Map<String, String>>.from(_history),
      );

      if (mounted) {
        setState(() {
          // Simpan ke history untuk request berikutnya
          _history.add({'role': 'user', 'text': text});
          _history.add({'role': 'model', 'text': result.reply});

          if (result.quotaUsed != null) _quotaUsed = result.quotaUsed;
          if (result.quotaLimit != null) _quotaLimit = result.quotaLimit;

          _messages.insert(
            0,
            Message(
              text: result.reply,
              isAi: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();

        // Tampilkan feedback jika ada data yang berhasil/gagal disimpan
        if (result.saved != null) {
          final type = result.saved!['type'];
          final label = type == 'food_log'
              ? 'Makanan berhasil ditambahkan ke catatan harian'
              : 'Suplemen berhasil ditambahkan ke catatan harian';
          _showSnackBar(label, isError: false);
        } else if (result.saveError != null) {
          _showSnackBar(result.saveError!, isError: true);
        }
      }
    } on ChatAccessException catch (e) {
      if (mounted) {
        if (e.quotaUsed != null) _quotaUsed = e.quotaUsed;
        if (e.quotaLimit != null) _quotaLimit = e.quotaLimit;

        if (e.code == 'PREMIUM_REQUIRED') {
          _showPremiumDialog(e.message);
        } else {
          setState(() {
            _messages.insert(
              0,
              Message(
                text: e.message,
                isAi: true,
                isError: true,
                timestamp: DateTime.now(),
              ),
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            Message(
              text: 'Maaf, terjadi kesalahan: ${e.toString().replaceFirst("Exception: ", "")}',
              isAi: true,
              isError: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPremiumDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Fitur Premium', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumPage()),
              );
            },
            child: const Text('Upgrade Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumSparklesInlineIcon(),
            Text(
              'IbuSehat AI',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontSize: 17,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: border,
            height: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_quotaLimit != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: surface.withValues(alpha: 0.6),
              child: Text(
                'Sisa chat hari ini: ${(_quotaLimit! - (_quotaUsed ?? 0)).clamp(0, _quotaLimit!)} / $_quotaLimit',
                style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Index 0 saat loading adalah gelembung "typing"
                if (_isLoading && index == 0) {
                  return _buildTypingIndicator();
                }
                final messageIndex = _isLoading ? index - 1 : index;
                return _buildMessageRow(_messages[messageIndex]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          // Animated dots
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _TypingDotsWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(Message message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;
    if (message.isAi) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Avatar
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: message.isError
                      ? [Colors.red.shade300, Colors.red.shade400]
                      : [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  message.isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            // AI Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: message.isError
                    ? Text(
                        message.text,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      )
                    : MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                          strong: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          em: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                          h1: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                          h2: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                          h3: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          listBullet: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                          code: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: isDark ? darkBorder : const Color(0xFFF4F0FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: const Color(0xFF8B5CF6),
                                width: 3,
                              ),
                            ),
                          ),
                          blockquote: TextStyle(
                            color: textSecondary,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;
    final border = isDark ? darkBorder : lightBorder;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: border,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              enabled: !_isLoading,
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _isLoading ? 'Menunggu respons...' : 'Tanya apa saja...',
                hintStyle: TextStyle(
                  color: textSecondary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
                isDense: true,
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              final hasText = value.text.trim().isNotEmpty && !_isLoading;
              return Center(
                child: GestureDetector(
                  onTap: hasText ? () => _sendMessage(_controller.text) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasText ? const Color(0xFF8B5CF6) : Colors.grey.shade300,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Widget animasi "mengetik" dengan tiga titik berdenyut
class _TypingDotsWidget extends StatefulWidget {
  @override
  State<_TypingDotsWidget> createState() => _TypingDotsWidgetState();
}

class _TypingDotsWidgetState extends State<_TypingDotsWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Cascade delay untuk tiap titik
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class Message {
  final String text;
  final bool isAi;
  final bool isError;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isAi,
    this.isError = false,
    required this.timestamp,
  });
}