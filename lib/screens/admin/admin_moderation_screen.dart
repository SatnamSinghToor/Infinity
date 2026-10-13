import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/safe_state.dart';
import 'admin_order_issues_screen.dart';
import 'admin_payouts_screen.dart';
import 'admin_support_screen.dart';
import 'admin_return_requests_screen.dart';
import 'admin_sponsored_slots_screen.dart';
import '../../widgets/role_common.dart';

/// Hub for the admin's three approval queues, each with a pending-count
/// badge — matches how the seller/delivery "More" screens surface a
/// business's separate concerns as one readable list instead of a row of
/// unlabeled app-bar icons.
class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  bool _isLoading = true;
  int _pendingReturns = 0;

  /// Whether the last load failed. A queue that could not be fetched is not
  /// an empty queue, and the counts must not read as zero because of it.
  bool _loadFailed = false;

  int _openIssues = 0;
  int _pendingBoosts = 0;
  int _pendingPayouts = 0;

  /// Support chats with a message from the account nobody has read.
  int _unreadChats = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final client = SupabaseService.client;
      final returns = await client
          .from('return_requests')
          .select('id')
          .eq('status', 'pending');
      final issues =
          await client.from('order_issues').select('id').eq('status', 'open');
      final boosts = await client
          .from('sponsored_slots')
          .select('id')
          .eq('status', 'PENDING');
      final payouts = await client
          .from('payout_requests')
          .select('id')
          .eq('status', 'pending');
      // Unread messages from the account itself (not an admin's reply),
      // counted once per chat.
      final unread = await client
          .from('support_messages')
          .select('thread_id, sender_id')
          .isFilter('read_at', null);
      final unreadChats = {
        for (final m in unread)
          if (m['sender_id'] == m['thread_id']) m['thread_id'],
      }.length;
      safeSetState(() {
        _pendingReturns = returns.length;
        _unreadChats = unreadChats;
        _openIssues = issues.length;
        _pendingBoosts = boosts.length;
        _pendingPayouts = payouts.length;
      });
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
          title: Text(l10n.adminModerationTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          centerTitle: true),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.adminModerationLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminModerationLoadFailed,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _QueueTile(
                icon: Iconsax.undo,
                title: l10n.adminModerationReturns,
                subtitle: l10n.adminModerationReturnsSub,
                pendingCount: _pendingReturns,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminReturnRequestsScreen(),
                    ),
                  );
                  _load();
                },
              ),
              _QueueTile(
                icon: Iconsax.warning_2,
                title: l10n.adminModerationIssues,
                subtitle: l10n.adminModerationIssuesSub,
                pendingCount: _openIssues,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminOrderIssuesScreen(),
                    ),
                  );
                  _load();
                },
              ),
              _QueueTile(
                icon: Iconsax.chart_2,
                title: l10n.adminModerationSlots,
                subtitle: l10n.adminModerationSlotsSub,
                pendingCount: _pendingBoosts,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminSponsoredSlotsScreen(),
                    ),
                  );
                  _load();
                },
              ),
              _QueueTile(
                icon: Iconsax.messages_2,
                title: l10n.adminSupportTitle,
                subtitle: l10n.adminSupportSub,
                pendingCount: _unreadChats,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminSupportScreen(),
                    ),
                  );
                  _load();
                },
              ),
              _QueueTile(
                icon: Iconsax.wallet_3,
                title: l10n.adminModerationPayouts,
                subtitle: l10n.adminModerationPayoutsSub,
                pendingCount: _pendingPayouts,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminPayoutsScreen(),
                    ),
                  );
                  _load();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int pendingCount;
  final VoidCallback onTap;

  const _QueueTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppConstants.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: pendingCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.dangerColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
      ),
    );
  }
}
