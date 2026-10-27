import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// The shop has been making decisions blind. Nothing recorded what customers
/// look at, what they search for, or where a checkout gets abandoned — so
/// "which products are worth stocking" could only be guessed, and a coupon
/// that never applies was invisible.
///
/// This records a small, named set of events to the `app_events` table (see
/// supabase/app_events.sql) — first-party, no dependency, no third party
/// holding the shop's data. What keeps it honest:
///
///  * only the events in [catalog] exist, and each one may carry only the
///    properties listed there. An unknown event or property is dropped, so a
///    later change cannot quietly start shipping a phone number;
///  * a guest's activity is not recorded at all — the table has an owner
///    column, and nobody's anonymous trail is worth the risk;
///  * one event is one row, sent in the background: a tap is never kept
///    waiting, no timer outlives the screen that logged, and a failure is
///    forgotten. Nothing here is allowed to throw.
class Analytics {
  Analytics._();

  /// Every event the app may send, with the exact properties that event is
  /// allowed to carry.
  static const Map<String, Set<String>> catalog = {
    /// Somebody opened the app.
    'app_open': {},

    /// A product page was opened.
    'product_view': {'product_id'},

    /// Something went into the cart.
    'add_to_cart': {'product_id', 'quantity'},

    /// A search was typed. `results` is how many products it found — a search
    /// that finds nothing is the clearest "you do not stock this" there is.
    'search': {'term', 'results'},

    /// The checkout screen was opened.
    'checkout_started': {'items', 'subtotal'},

    /// An order went through. `coupon` says whether a code was applied, not
    /// which one.
    'order_placed': {'total', 'items', 'payment', 'coupon'},

    /// A coupon code was refused, and why: 'invalid', 'min_order' or 'error'.
    'coupon_failed': {'code', 'reason'},
  };

  /// How many events one run of the app may send, whatever they are.
  static const int maxPerSession = 200;

  /// Longest a text property may be. The search term is the only text this
  /// records, and even that does not need to be an essay.
  static const int maxTextLength = 60;

  static int _sent = 0;
  static bool _started = false;

  /// Records that the app was opened. Call once, from `main`.
  static void start() {
    if (_started) return;
    _started = true;
    log('app_open');
  }

  /// How many events this run has sent.
  @visibleForTesting
  static int get accepted => _sent;

  /// What [name] may carry, once the catalog and the value rules have had
  /// their say. Pure, so the rules can be tested without sending anything.
  @visibleForTesting
  static Map<String, Object?> cleanProps(
    String name,
    Map<String, Object?> props,
  ) {
    final allowed = catalog[name];
    if (allowed == null) return const {};
    final clean = <String, Object?>{};
    for (final entry in props.entries) {
      if (!allowed.contains(entry.key)) continue;
      final value = entry.value;
      if (value == null) continue;
      if (value is String) {
        clean[entry.key] = clip(value);
      } else if (value is num || value is bool) {
        clean[entry.key] = value;
      }
    }
    return clean;
  }

  /// Records [name] with [props]. Never throws, never awaits, never blocks.
  static void log(String name, [Map<String, Object?> props = const {}]) {
    if (!catalog.containsKey(name)) return;
    if (_sent >= maxPerSession) return;
    _sent++;
    unawaited(_send(name, cleanProps(name, props)));
  }

  /// Writes one row. A guest keeps nothing: the table's rows belong to an
  /// account, and this app does not keep an anonymous trail.
  static Future<void> _send(String name, Map<String, Object?> props) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseService.client.from('app_events').insert({
        'user_id': userId,
        'name': name,
        'props': props,
        'platform': Platform.operatingSystem,
      });
    } catch (e) {
      // Losing an event costs a report; throwing here would cost a sale.
      debugPrint('Could not record the event: $e');
    }
  }

  /// [text], cut to [maxTextLength] with an ellipsis when it is longer.
  static String clip(String text) => text.length <= maxTextLength
      ? text
      : '${text.substring(0, maxTextLength)}…';

  @visibleForTesting
  static void resetForTest() {
    _sent = 0;
    _started = false;
  }
}
