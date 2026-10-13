import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/live_entrance.dart';
import '../widgets/role_common.dart';
import 'delivery/delivery_orders_screen.dart';
import 'order_detail_screen.dart';
import 'seller/seller_orders_screen.dart';
import '../widgets/pressable.dart';

/// One inbox for every role. Tap a notification to mark it read and open the
/// related order; swipe right to archive (or restore), swipe left to delete;
/// the ⋮ menus cover mark unread, mark all read, archive all and clear all.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  /// Rows an entrance animation has already played for, so a realtime
  /// update to one notification doesn't replay the whole inbox's entrance.
  final Set<String> _seenIds = {};

  bool get _onArchiveTab => _tabs.index == 1;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _snack(String message, {VoidCallback? onUndo, Duration? duration}) {
    final l10n = _l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
          duration: duration ?? const Duration(seconds: 3),
          action: onUndo == null
              ? null
              : SnackBarAction(
                  label: l10n.notificationsUndo,
                  onPressed: onUndo,
                ),
        ),
      );
  }

  void _failed() => _snack(_l10n.notificationsUpdateFailed);

  // --- per-notification actions -------------------------------------------

  /// The screen that shows what a notification is about, for this role.
  /// Null when there is nothing sensible to open (no order, or admin).
  Widget? _destinationFor(AppNotification n) {
    final orderId = n.orderId;
    if (orderId == null) return null;
    switch (context.read<AuthProvider>().role) {
      case UserRole.customer:
        return OrderDetailScreen(orderId: orderId);
      case UserRole.seller:
        return const SellerOrdersScreen();
      case UserRole.delivery:
        return const DeliveryOrdersScreen();
      case UserRole.admin:
        return null;
    }
  }

  void _open(AppNotification n) {
    final provider = context.read<NotificationProvider>();
    if (!n.isRead) provider.markAsRead(n.id);
    final destination = _destinationFor(n);
    if (destination != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
    }
  }

  Future<void> _toggleRead(AppNotification n) async {
    final provider = context.read<NotificationProvider>();
    final ok = n.isRead
        ? await provider.markAsUnread(n.id)
        : await provider.markAsRead(n.id);
    if (!ok && mounted) _failed();
  }

  Future<void> _archive(AppNotification n) async {
    final provider = context.read<NotificationProvider>();
    final ok = await provider.archive(n.id);
    if (!mounted) return;
    if (!ok) return _failed();
    _snack(_l10n.notificationsArchived, onUndo: () => provider.unarchive(n.id));
  }

  Future<void> _unarchive(AppNotification n) async {
    final ok = await context.read<NotificationProvider>().unarchive(n.id);
    if (!mounted) return;
    ok ? _snack(_l10n.notificationsUnarchived) : _failed();
  }

  void _delete(AppNotification n) {
    final provider = context.read<NotificationProvider>();
    provider.deleteWithUndo(n.id);
    _snack(
      _l10n.notificationsDeleted,
      onUndo: () => provider.undoDelete(n.id),
      duration: NotificationProvider.undoWindow,
    );
  }

  // --- bulk actions --------------------------------------------------------

  Future<void> _onMenu(String value) async {
    final provider = context.read<NotificationProvider>();
    switch (value) {
      case 'read_all':
        final ok = await provider.markAllAsRead();
        if (!mounted) return;
        ok ? _snack(_l10n.notificationsAllRead) : _failed();
      case 'archive_all':
        final count = provider.notifications.length;
        final ok = await provider.archiveAll();
        if (!mounted) return;
        ok ? _snack(_l10n.notificationsArchiveAllDone(count)) : _failed();
      case 'clear':
        await _confirmClear(provider);
    }
  }

  Future<void> _confirmClear(NotificationProvider provider) async {
    final archivedTab = _onArchiveTab;
    final count =
        archivedTab ? provider.archived.length : provider.notifications.length;
    if (count == 0) return;

    final l10n = _l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          archivedTab
              ? l10n.notificationsClearArchiveTitle
              : l10n.notificationsClearAllTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(l10n.notificationsClearConfirm(count)),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.notificationsCancel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.dangerColor,
            ),
            child: Text(
              l10n.notificationsDelete,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await provider.clearAll(archivedTab: archivedTab);
    if (!mounted) return;
    ok ? _snack(_l10n.notificationsCleared) : _failed();
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final inbox = provider.notifications;
    final archived = provider.archived;
    final unread = provider.unreadCount;
    final currentList = _onArchiveTab ? archived : inbox;
    final l10n = _l10n;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.notificationsTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.more),
            tooltip: l10n.notificationsMore,
            onSelected: _onMenu,
            itemBuilder: (_) => [
              if (!_onArchiveTab)
                PopupMenuItem(
                  value: 'read_all',
                  enabled: unread > 0,
                  child: _menuRow(
                    Iconsax.tick_circle,
                    l10n.notificationsMarkAllRead,
                  ),
                ),
              if (!_onArchiveTab)
                PopupMenuItem(
                  value: 'archive_all',
                  enabled: inbox.isNotEmpty,
                  child: _menuRow(
                    Iconsax.archive_add,
                    l10n.notificationsArchiveAll,
                  ),
                ),
              PopupMenuItem(
                value: 'clear',
                enabled: currentList.isNotEmpty,
                child: _menuRow(
                  Iconsax.trash,
                  _onArchiveTab
                      ? l10n.notificationsClearArchive
                      : l10n.notificationsClearAll,
                  color: AppConstants.dangerColor,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppConstants.primaryColor,
          indicatorWeight: 3,
          labelColor: AppConstants.textPrimaryColor,
          unselectedLabelColor:
              AppConstants.textPrimaryColor.withValues(alpha: 0.55),
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              text: unread > 0
                  ? l10n.notificationsInboxCount(unread)
                  : l10n.notificationsInbox,
            ),
            Tab(text: l10n.notificationsArchivedTab),
          ],
        ),
      ),
      body: provider.isLoading && inbox.isEmpty && archived.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _buildList(inbox, archivedTab: false),
                _buildList(archived, archivedTab: true),
              ],
            ),
    );
  }

  Widget _menuRow(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppConstants.textPrimaryColor),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildList(
    List<AppNotification> items, {
    required bool archivedTab,
  }) {
    final provider = context.read<NotificationProvider>();
    final l10n = _l10n;

    // An inbox that failed to load is not an empty inbox.
    if (provider.loadFailed && items.isEmpty) {
      return RoleError(
        title: l10n.notificationsLoadFailed,
        onRetry: provider.loadNotifications,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadNotifications,
      child: items.isEmpty
          ? LayoutBuilder(
              // A scrollable, so pull-to-refresh still works when empty.
              builder: (context, constraints) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: _buildEmpty(archivedTab),
                  ),
                ],
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) return _buildHint(archivedTab);
                final n = items[index - 1];
                return LiveEntrance(
                  key: ValueKey('entrance_${n.id}'),
                  id: n.id,
                  seen: _seenIds,
                  child: Dismissible(
                    key: ValueKey(n.id),
                    background: _swipeBackground(
                      alignment: Alignment.centerLeft,
                      color: archivedTab
                          ? AppConstants.successColor
                          : AppConstants.accentColor,
                      foreground:
                          archivedTab ? Colors.white : AppConstants.blackColor,
                      icon: archivedTab
                          ? Iconsax.archive_minus
                          : Iconsax.archive_add,
                      label: archivedTab
                          ? l10n.notificationsMoveToInbox
                          : l10n.notificationsArchive,
                    ),
                    secondaryBackground: _swipeBackground(
                      alignment: Alignment.centerRight,
                      color: AppConstants.dangerColor,
                      foreground: Colors.white,
                      icon: Iconsax.trash,
                      label: l10n.notificationsDelete,
                    ),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        archivedTab ? _unarchive(n) : _archive(n);
                      } else {
                        _delete(n);
                      }
                    },
                    child: _NotificationTile(
                      notification: n,
                      archivedTab: archivedTab,
                      onTap: () => _open(n),
                      onToggleRead: () => _toggleRead(n),
                      onArchive: () =>
                          archivedTab ? _unarchive(n) : _archive(n),
                      onDelete: () => _delete(n),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHint(bool archivedTab) {
    final l10n = _l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        archivedTab
            ? l10n.notificationsSwipeHintArchive
            : l10n.notificationsSwipeHintInbox,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: AppConstants.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required Color foreground,
    required IconData icon,
    required String label,
  }) {
    final isLeft = alignment == Alignment.centerLeft;
    final children = [
      Icon(icon, color: foreground, size: 22),
      const SizedBox(width: 8),
      Text(
        label,
        style: GoogleFonts.poppins(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft ? children : children.reversed.toList(),
      ),
    );
  }

  Widget _buildEmpty(bool archivedTab) {
    final l10n = _l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              archivedTab ? Iconsax.archive_1 : Iconsax.notification,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              archivedTab
                  ? l10n.notificationsEmptyArchivedTitle
                  : l10n.notificationsEmptyTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              archivedTab
                  ? l10n.notificationsEmptyArchivedBody
                  : l10n.notificationsEmptyBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool archivedTab;
  final VoidCallback onTap;
  final VoidCallback onToggleRead;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.archivedTab,
    required this.onTap,
    required this.onToggleRead,
    required this.onArchive,
    required this.onDelete,
  });

  IconData get _icon {
    // Types arrive as e.g. "ORDER", so compare case-insensitively.
    switch (notification.type.toLowerCase()) {
      case 'order':
        return Iconsax.receipt;
      case 'promo':
      case 'promotion':
        return Iconsax.discount_shape;
      case 'wallet':
        return Iconsax.wallet_money;
      default:
        return Iconsax.notification;
    }
  }

  String _timeAgo(AppLocalizations l10n) {
    final diff = DateTime.now().difference(notification.createdAt);
    final minutes = diff.inMinutes;
    if (minutes < 1) return l10n.notificationsJustNow;
    if (minutes < 60) return l10n.notificationsMinutesAgo(minutes);
    if (diff.inHours < 24) return l10n.notificationsHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.notificationsDaysAgo(diff.inDays);
    return DateFormat('d MMM').format(notification.createdAt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: unread
          ? Color.alphaBlend(
              AppConstants.primaryColor.withValues(alpha: 0.08),
              Colors.white,
            )
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor
                      .withValues(alpha: unread ? 0.16 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: AppConstants.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: AppConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: unread ? Colors.grey[700] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(l10n),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Iconsax.more, size: 18, color: Colors.grey[500]),
                padding: EdgeInsets.zero,
                tooltip: l10n.notificationsOptions,
                onSelected: (value) {
                  switch (value) {
                    case 'toggle_read':
                      onToggleRead();
                    case 'archive':
                      onArchive();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle_read',
                    child: _row(
                      unread ? Iconsax.tick_circle : Iconsax.eye_slash,
                      unread
                          ? l10n.notificationsMarkRead
                          : l10n.notificationsMarkUnread,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: _row(
                      archivedTab ? Iconsax.archive_minus : Iconsax.archive_add,
                      archivedTab
                          ? l10n.notificationsMoveToInbox
                          : l10n.notificationsArchive,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: _row(
                      Iconsax.trash,
                      l10n.notificationsDelete,
                      color: AppConstants.dangerColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppConstants.textPrimaryColor),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
