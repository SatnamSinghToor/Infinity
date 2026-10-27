import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shopper's own recent searches, kept on the device so the idle search
/// screen can offer "search that again" without asking the server for it.
/// Unrelated to `lib/services/analytics.dart`, which logs searches for the
/// business, not for the shopper to see.
class SearchHistory {
  const SearchHistory._();

  static const _key = 'search_history_terms';
  static const _max = 8;

  /// The saved terms, newest first.
  static Future<List<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? const [];
    } catch (e) {
      // Best-effort: an unreadable history just starts empty.
      debugPrint('Loading search history failed: $e');
      return const [];
    }
  }

  /// Puts [term] at the front, drops any earlier copy of it (case
  /// insensitive), and keeps at most [_max] terms.
  static Future<List<String>> add(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return load();
    final current = await load();
    final next = [
      trimmed,
      ...current.where((t) => t.toLowerCase() != trimmed.toLowerCase()),
    ].take(_max).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, next);
    } catch (e) {
      // Best-effort: the search itself still worked even if it isn't
      // remembered for next time.
      debugPrint('Saving search history failed: $e');
    }
    return next;
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('Clearing search history failed: $e');
    }
  }
}
