import 'dart:async';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../utils/safe_state.dart';
import '../utils/tokens.dart';
import '../widgets/pressable.dart';
import '../widgets/role_common.dart';

/// Chat with Support: one running conversation between an account and the
/// admins (supabase/support_messages.sql), live both ways.
///
/// Opened with no [threadId] it is the signed-in account's own chat; an
/// admin opens it on someone's [threadId] to answer them, with their name
/// as the [title].
class SupportChatScreen extends StatefulWidget {
  final String? threadId;
  final String? title;

  const SupportChatScreen({super.key, this.threadId, this.title});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  /// A failed load is said out loud, with a retry — never shown as a chat
  /// with nothing in it.
  bool _loadFailed = false;
  bool _sending = false;
  StreamSubscription<List<Map<String, dynamic>>>? _watch;

  late final String _me = context.read<AuthProvider>().userId;
  late final String _thread = widget.threadId ?? _me;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _watch?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The conversation, kept live: a reply lands without a refresh, the way
  /// a messenger does.
  Future<void> _load() async {
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    await _watch?.cancel();
    _watch = SupabaseService.client
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', _thread)
        .order('created_at')
        .listen(
          (rows) {
            safeSetState(() {
              _messages = rows;
              _isLoading = false;
            });
            _markRead();
            _toBottom();
          },
          onError: (Object e) {
            debugPrint('Support chat load failed: $e');
            safeSetState(() {
              _loadFailed = true;
              _isLoading = false;
            });
          },
        );
  }

  /// The other side's messages, now seen.
  Future<void> _markRead() async {
    final unread = _messages.any(
      (m) => m['sender_id'] != _me && m['read_at'] == null,
    );
    if (!unread) return;
    try {
      await SupabaseService.client
          .from('support_messages')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('thread_id', _thread)
          .neq('sender_id', _me)
          .isFilter('read_at', null);
    } catch (e) {
      debugPrint('Support chat read mark failed: $e');
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    safeSetState(() => _sending = true);
    try {
      await SupabaseService.client.from('support_messages').insert({
        'thread_id': _thread,
        'sender_id': _me,
        'body': text,
      });
      _input.clear();
    } catch (e) {
      debugPrint('Support message send failed: $e');
      if (mounted) roleSay(context, l10n.supportChatSendFailed);
    }
    safeSetState(() => _sending = false);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${_two(h)}:${_two(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  String _day(DateTime t, AppLocalizations l10n) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(t);
    if (day == today) return l10n.supportChatToday;
    if (day == today.subtract(const Duration(days: 1))) {
      return l10n.supportChatYesterday;
    }
    return '${_two(t.day)}-${_two(t.month)}-${t.year} ${_time(t)}';
  }

  DateTime _at(Map<String, dynamic> m) =>
      DateTime.tryParse(m['created_at'] as String? ?? '')?.toLocal() ??
      DateTime.now();

  Widget _separator(String text) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: tokens.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: tokens.textSecondary),
            ),
          ),
          Expanded(child: Divider(color: tokens.border)),
        ],
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final tokens = context.tokens;
    final mine = m['sender_id'] == _me;
    final read = m['read_at'] != null;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: mine ? tokens.primary : tokens.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(mine ? 20 : 4),
              bottomRight: Radius.circular(mine ? 4 : 20),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (m['body'] as String?) ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: mine ? Colors.white : tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _time(_at(m)),
                    style: TextStyle(
                      fontSize: 12,
                      color: mine
                          ? Colors.white.withOpacity(0.85)
                          : tokens.textSecondary,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 6),
                    Icon(
                      read ? Icons.done_all : Icons.done,
                      size: 16,
                      color: Colors.white.withOpacity(read ? 1 : 0.8),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final items = <Widget>[];
    DateTime? last;
    for (final m in _messages) {
      final at = _at(m);
      // A new day, or a gap of more than an hour, gets its own line.
      if (last == null ||
          !DateUtils.isSameDay(last, at) ||
          at.difference(last).inMinutes > 60) {
        items.add(_separator(_day(at, l10n)));
      }
      items.add(_bubble(m));
      last = at;
    }
    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: AppBar(
        backgroundColor: tokens.card,
        surfaceTintColor: tokens.card,
        title: Text(
          widget.title ?? l10n.supportChatTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RoleBody(
              loading: _isLoading,
              failed: _loadFailed,
              onRetry: _load,
              loadingMessage: l10n.supportChatLoading,
              errorTitle: l10n.supportChatLoadFailed,
              child: _messages.isEmpty
                  ? RoleEmpty(
                      icon: Iconsax.message_text,
                      title: l10n.supportChatEmptyTitle,
                      message: l10n.supportChatEmptyBody,
                    )
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                      children: items,
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l10n.supportChatHint,
                        filled: true,
                        fillColor: tokens.border.withOpacity(0.6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Pressable(
                    child: Material(
                      color: tokens.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _sending ? null : _send,
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Iconsax.send_1,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
