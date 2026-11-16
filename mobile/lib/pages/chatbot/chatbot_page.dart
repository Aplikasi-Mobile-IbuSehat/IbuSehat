import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/widgets/custom_toast.dart';
import 'package:mobile/widgets/health_gate.dart';
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

  /// Sesi chat di server. Riwayat & ingatan AI disimpan backend per sesi,
  /// jadi aplikasi cukup mengirim id sesi (null = sesi baru).
  int? _sessionId;

  /// True selama percakapan terakhir sedang dimuat dari server.
  bool _restoring = true;

  /// Sisa kuota chat harian (diisi dari respons backend setelah chat pertama).
  int? _quotaUsed;
  int? _quotaLimit;

  static const String _greetingText =
      'Halo 👋 Aku IbuSehat AI, pendamping kesehatan ibu pasca melahirkan. '
      'Mau tanya soal pemulihan, menyusui, atau pola makan? '
      'Aku juga bisa bantu mencatat makanan dan suplemenmu.';

  Message get _greeting =>
      Message(text: _greetingText, isAi: true, timestamp: DateTime.now());

  @override
  void initState() {
    super.initState();
    // Sapaan pembuka ditampilkan tanpa memanggil backend.
    _messages.add(_greeting);
    _restoreLatestSession();
  }

  /// Lanjutkan percakapan terakhir pengguna, kalau ada.
  Future<void> _restoreLatestSession() async {
    try {
      final sessions = await _apiService.fetchChatSessions();
      if (sessions.isNotEmpty) {
        await _openSession(sessions.first.id);
      }
    } catch (_) {
      // Gagal memuat riwayat tidak menghalangi chat baru.
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  /// Muat isi satu sesi ke layar dan jadikan sesi aktif.
  Future<void> _openSession(int sessionId) async {
    final history = await _apiService.fetchChatMessages(sessionId);
    if (!mounted) return;

    setState(() {
      _sessionId = sessionId;
      _messages
        ..clear()
        // Daftar ditampilkan terbalik: indeks 0 = pesan terbaru.
        ..addAll(history.reversed.map(
          (m) => Message(
            text: m.text,
            isAi: m.isAi,
            isEmergency: m.isEmergency,
            timestamp: m.timestamp,
          ),
        ))
        ..add(_greeting);
    });
  }

  void _startNewChat() {
    if (_isLoading) return;
    setState(() {
      _sessionId = null;
      _messages
        ..clear()
        ..add(_greeting);
    });
  }

  Future<void> _showHistorySheet() async {
    if (_isLoading) return;

    final List<ChatSessionSummary> sessions;
    try {
      sessions = await _apiService.fetchChatSessions();
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
      return;
    }
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? darkSurface : lightSurface;
    final textPrimary = isDark ? darkTextPrimary : lightTextPrimary;
    final textSecondary = isDark ? darkTextSecondary : lightTextSecondary;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Riwayat Percakapan',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _startNewChat();
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Baru'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        child: Text(
                          'Belum ada percakapan tersimpan.',
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: sessions.length,
                          itemBuilder: (_, index) {
                            final session = sessions[index];
                            final isActive = session.id == _sessionId;
                            return ListTile(
                              leading: Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: isActive
                                    ? const Color(0xFF8B5CF6)
                                    : textSecondary,
                                size: 20,
                              ),
                              title: Text(
                                session.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              subtitle: session.lastMessageAt == null
                                  ? null
                                  : Text(
                                      _formatSessionTime(session.lastMessageAt!),
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                              trailing: IconButton(
                                tooltip: 'Hapus percakapan',
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final deleted = await _deleteSession(session);
                                  if (deleted) {
                                    setSheetState(() => sessions.removeAt(index));
                                  }
                                },
                              ),
                              onTap: () async {
                                Navigator.pop(sheetContext);
                                if (isActive) return;
                                try {
                                  await _openSession(session.id);
                                } catch (e) {
                                  if (mounted) {
                                    _showSnackBar(
                                      e.toString().replaceFirst('Exception: ', ''),
                                      isError: true,
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _deleteSession(ChatSessionSummary session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus percakapan?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '"${session.title}" akan dihapus permanen dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    try {
      await _apiService.deleteChatSession(session.id);
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
      return false;
    }

    if (mounted && session.id == _sessionId) _startNewChat();
    return true;
  }

  String _formatSessionTime(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final clock = '${two(time.hour)}.${two(time.minute)}';
    final sameDay =
        time.year == now.year && time.month == now.month && time.day == now.day;
    return sameDay
        ? 'Hari ini, $clock'
        : '${two(time.day)}/${two(time.month)}/${time.year}, $clock';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading || _restoring) return;

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
      ChatResult result;
      try {
        result = await _apiService.sendChatMessage(text, sessionId: _sessionId);
      } on ChatAccessException catch (e) {
        // Sesi sudah terhapus (mis. dari perangkat lain): lanjut di sesi baru.
        if (e.code != 'SESSION_NOT_FOUND' || _sessionId == null) rethrow;
        _sessionId = null;
        result = await _apiService.sendChatMessage(text);
      }

      if (mounted) {
        setState(() {
          if (result.sessionId != null) _sessionId = result.sessionId;

          if (result.quotaUsed != null) _quotaUsed = result.quotaUsed;
          if (result.quotaLimit != null) _quotaLimit = result.quotaLimit;

          _messages.insert(
            0,
            Message(
              text: result.reply,
              isAi: true,
              isEmergency: result.isEmergency,
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

        if (e.code == 'health_data_required') {
          // Pesan belum terkirim: kembalikan ke input & minta isi data.
          setState(() => _messages.remove(userMessage));
          unawaited(_promptHealthData(pendingText: text));
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

  /// Server menolak karena data kesehatan belum lengkap: tampilkan popup
  /// akses fitur → halaman Data Kesehatan. Setelah tersimpan, pesan yang
  /// tadi diketik dikirim ulang.
  Future<void> _promptHealthData({required String pendingText}) async {
    _controller.text = pendingText;
    // Segarkan cache dulu supaya gerbang tidak memakai flag lama.
    await AuthService.instance.syncUserFromApi();
    if (!mounted) return;
    final ok = await HealthGate.ensure(context);
    if (ok && mounted && _controller.text.trim().isNotEmpty) {
      _sendMessage(_controller.text);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    CustomToast.show(context, message, isError: isError);
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
        actions: [
          IconButton(
            tooltip: 'Riwayat percakapan',
            icon: Icon(Icons.history_rounded, color: textPrimary, size: 22),
            onPressed: _showHistorySheet,
          ),
          IconButton(
            tooltip: 'Percakapan baru',
            icon: Icon(Icons.add_comment_outlined, color: textPrimary, size: 21),
            onPressed: _startNewChat,
          ),
          const SizedBox(width: 4),
        ],
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
          if (_restoring)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF8B5CF6),
              backgroundColor: Colors.transparent,
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
                  colors: message.isError || message.isEmergency
                      ? [Colors.red.shade300, Colors.red.shade400]
                      : [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  message.isError
                      ? Icons.error_outline_rounded
                      : message.isEmergency
                          ? Icons.warning_amber_rounded
                          : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            // AI Text
            Expanded(
              child: Container(
                // Balasan darurat diberi bingkai merah agar tidak terlewat.
                padding: message.isEmergency
                    ? const EdgeInsets.all(12)
                    : const EdgeInsets.only(top: 2),
                decoration: message.isEmergency
                    ? BoxDecoration(
                        color: isDark
                            ? Colors.red.shade900.withValues(alpha: 0.25)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade300),
                      )
                    : null,
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
                hintText: _isLoading
                    ? 'Menunggu respons...'
                    : 'Tanya seputar ibu pasca melahirkan...',
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

  /// Balasan yang memuat pesan darurat dari backend (ditampilkan menonjol).
  final bool isEmergency;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isAi,
    this.isError = false,
    this.isEmergency = false,
    required this.timestamp,
  });
}

