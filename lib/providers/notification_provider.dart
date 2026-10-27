import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/supabase_service.dart';

class _PendingDelete {
  final AppNotification item;
  final int index;
  final Timer timer;

  _PendingDelete(this.item, this.index, this.timer);
}

/// The signed-in user's notifications, for every role. Each action updates
/// the list immediately and then syncs to Supabase; if the sync fails the
/// change is rolled back and the action returns false.
class NotificationProvider extends ChangeNotifier {
  /// How long a swiped-away notification can still be brought back before
  /// the delete is really sent to the server.
  static const undoWindow = Duration(seconds: 5);

  final List<AppNotification> _all = [];
  final Map<String, _PendingDelete> _pendingDeletes = {};
  bool _isLoading = false;
  StreamSubscription<List<Map<String, dynamic>>>? _watch;

  /// Set when the last load from the backend failed (offline, server error).
  /// An empty inbox after a failure is not the same as an empty inbox.
  bool _loadFailed = false;

  /// Inbox: everything that isn't archived, newest first.
  List<AppNotification> get notifications =>
      List.unmodifiable(_all.where((n) => !n.isArchived));

  List<AppNotification> get archived =>
      List.unmodifiable(_all.where((n) => n.isArchived));

  bool get isLoading => _isLoading;

  /// Set when the last load from the backend failed (offline, server error).
  /// An empty inbox after a failure is not the same as an empty inbox.
  bool get loadFailed => _loadFailed;

  /// Unread notifications in the inbox (archived ones don't count).
  int get unreadCount => _all.where((n) => !n.isArchived && !n.isRead).length;

  String? get _userId => SupabaseService.client.auth.currentUser?.id;

  /// Forgets the in-memory notifications on sign-out.
  void resetLocal() {
    _watch?.cancel();
    _watch = null;
    for (final p in _pendingDeletes.values) {
      p.timer.cancel();
    }
    _pendingDeletes.clear();
    _all.clear();
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    final uid = _userId;
    if (uid == null) return;

    _isLoading = true;
    _loadFailed = false;
    notifyListeners();

    try {
      final rows = await SupabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      _all
        ..clear()
        ..addAll(
          rows
              .map(AppNotification.fromSupabaseRow)
              // Swiped away but still inside the undo window.
              .where((n) => !_pendingDeletes.containsKey(n.id)),
        );
    } catch (e) {
      debugPrint('Notifications load failed: $e');
      _loadFailed = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Keeps the inbox current for as long as the app is signed in: a new
  /// order, status change or restock used to only reach here on the next
  /// [loadNotifications] call (a screen re-opening, a pull-to-refresh) —
  /// this reflects it, and every read/archive/delete made on another of the
  /// user's own devices, the moment it happens. Call more than once is a
  /// no-op; [resetLocal] stops it on sign-out.
  /// Starts the live watch over again. After the phone has slept its
  /// socket can be gone without the stream ever saying so, and a watch that
  /// is still set would otherwise never be opened again.
  void rewatchLive() {
    _watch?.cancel();
    _watch = null;
    watchLive();
  }

  void watchLive() {
    final uid = _userId;
    if (uid == null || _watch != null) return;
    _watch = SupabaseService.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .listen(
          _applyRows,
          // Best-effort: a dropped realtime connection just means the inbox
          // falls back to needing a manual refresh, not that it breaks.
          onError: (Object e) => debugPrint('Notifications watch failed: $e'),
        );
  }

  void _applyRows(List<Map<String, dynamic>> rows) {
    _all
      ..clear()
      ..addAll(
        rows
            .map(AppNotification.fromSupabaseRow)
            // Still inside its undo window: the server hasn't heard about
            // the delete yet, so the row is still in [rows] — keep it gone
            // on screen until the undo timer actually decides its fate.
            .where((n) => !_pendingDeletes.containsKey(n.id)),
      );
    _loadFailed = false;
    notifyListeners();
  }

  // --- helpers -------------------------------------------------------------

  int _indexOf(String id) => _all.indexWhere((n) => n.id == id);

  /// Applies [change] to one notification locally, runs [sync], and rolls
  /// back if [sync] throws.
  Future<bool> _apply(
    String id,
    AppNotification Function(AppNotification) change,
    Future<void> Function() sync,
  ) async {
    final index = _indexOf(id);
    if (index == -1) return false;
    final before = _all[index];
    _all[index] = change(before);
    notifyListeners();

    try {
      await sync();
      return true;
    } catch (e) {
      debugPrint('Notification update failed: $e');
      final now = _indexOf(id);
      if (now != -1) _all[now] = before;
      notifyListeners();
      return false;
    }
  }

  /// Same as [_apply] but for several notifications at once (bulk actions).
  Future<bool> _applyMany(
    Iterable<AppNotification> targets,
    AppNotification Function(AppNotification) change,
    Future<void> Function() sync,
  ) async {
    final ids = targets.map((n) => n.id).toSet();
    if (ids.isEmpty) return true;
    final before = {
      for (final n in _all.where((n) => ids.contains(n.id))) n.id: n
    };
    for (var i = 0; i < _all.length; i++) {
      if (ids.contains(_all[i].id)) _all[i] = change(_all[i]);
    }
    notifyListeners();

    try {
      await sync();
      return true;
    } catch (e) {
      debugPrint('Bulk notification update failed: $e');
      for (var i = 0; i < _all.length; i++) {
        final original = before[_all[i].id];
        if (original != null) _all[i] = original;
      }
      notifyListeners();
      return false;
    }
  }

  // --- read / unread -------------------------------------------------------

  Future<bool> markAsRead(String id) => _setRead(id, true);

  Future<bool> markAsUnread(String id) => _setRead(id, false);

  Future<bool> _setRead(String id, bool read) {
    final index = _indexOf(id);
    if (index == -1) return Future.value(false);
    if (_all[index].isRead == read) return Future.value(true);
    return _apply(
      id,
      (n) => n.copyWith(isRead: read),
      () => SupabaseService.client
          .from('notifications')
          .update({'is_read': read}).eq('id', id),
    );
  }

  Future<bool> markAllAsRead() {
    final uid = _userId;
    if (uid == null) return Future.value(false);
    return _applyMany(
      _all.where((n) => !n.isArchived && !n.isRead),
      (n) => n.copyWith(isRead: true),
      () => SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false)
          .isFilter('archived_at', null),
    );
  }

  // --- archive -------------------------------------------------------------

  Future<bool> archive(String id) {
    final at = DateTime.now();
    return _apply(
      id,
      (n) => n.copyWith(archivedAt: at),
      () => SupabaseService.client
          .from('notifications')
          .update({'archived_at': at.toUtc().toIso8601String()}).eq('id', id),
    );
  }

  Future<bool> unarchive(String id) {
    return _apply(
      id,
      (n) => n.copyWith(clearArchived: true),
      () => SupabaseService.client
          .from('notifications')
          .update({'archived_at': null}).eq('id', id),
    );
  }

  Future<bool> archiveAll() {
    final uid = _userId;
    if (uid == null) return Future.value(false);
    final at = DateTime.now();
    return _applyMany(
      _all.where((n) => !n.isArchived),
      (n) => n.copyWith(archivedAt: at),
      () => SupabaseService.client
          .from('notifications')
          .update({'archived_at': at.toUtc().toIso8601String()})
          .eq('user_id', uid)
          .isFilter('archived_at', null),
    );
  }

  // --- delete --------------------------------------------------------------

  /// Removes [id] from the list right away, but only tells the server after
  /// [undoWindow] — so [undoDelete] can bring it back without re-inserting
  /// the row (which would fire the push trigger a second time).
  void deleteWithUndo(String id) {
    final index = _indexOf(id);
    if (index == -1) return;
    final item = _all.removeAt(index);
    _pendingDeletes[id] = _PendingDelete(
      item,
      index,
      Timer(undoWindow, () => _commitDelete(id)),
    );
    notifyListeners();
  }

  void undoDelete(String id) {
    final pending = _pendingDeletes.remove(id);
    if (pending == null) return;
    pending.timer.cancel();
    _all.insert(pending.index.clamp(0, _all.length), pending.item);
    notifyListeners();
  }

  Future<void> _commitDelete(String id) async {
    final pending = _pendingDeletes.remove(id);
    if (pending == null) return;
    try {
      await SupabaseService.client.from('notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('Notification delete failed: $e');
      // Couldn't delete it for real — put it back rather than lie.
      _all.insert(pending.index.clamp(0, _all.length), pending.item);
      notifyListeners();
    }
  }

  /// Permanently deletes every notification in the inbox ([archivedTab]
  /// false) or in the archive ([archivedTab] true).
  Future<bool> clearAll({required bool archivedTab}) async {
    final uid = _userId;
    if (uid == null) return false;
    final targets = _all.where((n) => n.isArchived == archivedTab).toList();
    if (targets.isEmpty) return true;

    final ids = targets.map((n) => n.id).toSet();
    final snapshot = List<AppNotification>.of(_all);
    _all.removeWhere((n) => ids.contains(n.id));
    notifyListeners();

    try {
      final query = SupabaseService.client
          .from('notifications')
          .delete()
          .eq('user_id', uid);
      await (archivedTab
          ? query.not('archived_at', 'is', null)
          : query.isFilter('archived_at', null));
      return true;
    } catch (e) {
      debugPrint('Clear all failed: $e');
      _all
        ..clear()
        ..addAll(snapshot);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _watch?.cancel();
    for (final p in _pendingDeletes.values) {
      p.timer.cancel();
    }
    super.dispose();
  }
}
