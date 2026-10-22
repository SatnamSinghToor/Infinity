import 'dart:async';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../services/supabase_service.dart';
import '../../utils/safe_state.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/role_common.dart';
import '../support_chat_screen.dart';

/// Every Chat with Support conversation, newest first: who it is, their
/// last message, and how many of theirs are still unread. Tapping one opens
/// it to answer. Kept live, so a new message moves its chat to the top.
class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  bool _isLoading = true;

  /// A failed load is said out loud, with a retry — never shown as an
  /// empty inbox.
  bool _loadFailed = false;

  /// One entry per conversation: its latest message and unread count.
  List<({String thread, Map<String, dynamic> last, int unread})> _threads = [];
  Map<String, String> _names = {};
  StreamSubscription<List<Map<String, dynamic>>>? _watch;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _watch = SupabaseService.client
        .from('support_messages')
        .stream(primaryKey: ['id']).listen(
      (_) {
        _debounce?.cancel();
        _debounce = Timer(
          const Duration(milliseconds: 400),
          () => _load(silent: true),
        );
      },
      onError: (Object e) => debugPrint('Support inbox watch failed: $e'),
    );
  }

  @override
  void dispose() {
    _watch?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    safeSetState(() {
      if (!silent) _isLoading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.client
          .from('support_messages')
          .select('thread_id, sender_id, body, created_at, read_at')
          .order('created_at', ascending: false)
          .limit(2000);
      final byThread = <String, List<Map<String, dynamic>>>{};
      for (final r in rows) {
        (byThread[r['thread_id'] as String] ??= []).add(r);
      }
      final threads = [
        for (final e in byThread.entries)
          (
            thread: e.key,
            last: e.value.first,
            unread: e.value
                .where((m) => m['sender_id'] == e.key && m['read_at'] == null)
                .length,
          ),
      ];
      var names = <String, String>{};
      try {
        if (threads.isNotEmpty) {
          final people = await SupabaseService.client
              .from('profiles')
              .select('id, full_name, email, role')
              .inFilter('id', [for (final t in threads) t.thread]);
          names = {
            for (final p in people)
              p['id'] as String: [
                ((p['full_name'] as String?)?.trim().isNotEmpty ?? false)
                    ? p['full_name'] as String
                    : (p['email'] as String?) ?? '',
                if (p['role'] != null) '· ${p['role']}',
              ].join(' '),
          };
        }
      } catch (e) {
        debugPrint('Support inbox names failed: $e');
      }
      safeSetState(() {
        _threads = threads;
        _names = names;
      });
    } catch (e) {
      debugPrint('Support inbox load failed: $e');
      if (!silent) safeSetState(() => _loadFailed = true);
    }
    if (!silent) safeSetState(() => _isLoading = false);
  }

  String _when(String? iso) {
    final at = DateTime.tryParse(iso ?? '')?.toLocal();
    if (at == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    if (DateUtils.isSameDay(at, DateTime.now())) {
      return '${two(at.hour)}:${two(at.minute)}';
    }
    return '${two(at.day)}/${two(at.month)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.surface,
      appBar: GradientAppBar(
        title: Text(
          l10n.adminSupportTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: RoleBody(
        loading: _isLoading,
        failed: _loadFailed,
        onRetry: _load,
        loadingMessage: l10n.adminSupportLoading,
        errorTitle: l10n.adminSupportLoadFailed,
        child: _threads.isEmpty
            ? RoleEmpty(
                icon: Iconsax.messages_2,
                title: l10n.adminSupportEmptyTitle,
                message: l10n.adminSupportEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _threads.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.listGap),
                  itemBuilder: (context, i) {
                    final t = _threads[i];
                    final name = _names[t.thread] ?? t.thread.substring(0, 8);
                    return Material(
                      color: tokens.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        side: BorderSide(color: tokens.border),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupportChatScreen(
                              threadId: t.thread,
                              title: name,
                            ),
                          ),
                        ).then((_) => _load(silent: true)),
                        leading: CircleAvatar(
                          backgroundColor:
                              tokens.primary.withOpacity(0.12),
                          child: Icon(Iconsax.user, color: tokens.primary),
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          (t.last['body'] as String?) ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _when(t.last['created_at'] as String?),
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.textSecondary,
                              ),
                            ),
                            if (t.unread > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.primary,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  '${t.unread}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
