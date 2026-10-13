import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'supabase_service.dart';

/// Production has been blind. There is no Crashlytics, no Sentry, nothing:
/// when the app throws on a customer's phone, the only trace is a red screen
/// they cannot read and the app's own console, which nobody has.
///
/// This reports uncaught errors to the `app_errors` table (see
/// supabase/app_errors.sql) — small, dependency-free, and honest about what
/// it cannot do:
///
///  * a guest's error is logged locally only, because the table is readable
///    by admins and a signed-out phone has no identity to file it under;
///  * one message never arrives twice in five minutes, so a screen that
///    throws on every rebuild cannot flood the table;
///  * nothing here is allowed to throw, ever — a reporter that crashes the
///    app it is watching is worse than no reporter.
class ErrorReporter {
  ErrorReporter._();

  /// How many reports one run of the app may send, whatever they are.
  static const int maxPerSession = 10;

  /// The same error is sent at most once in this long.
  static const Duration window = Duration(minutes: 5);

  static const int _maxMessage = 2000;
  static const int _maxStack = 8000;

  static int _sent = 0;
  static final Map<String, DateTime> _lastSeen = {};
  static bool _started = false;

  /// Hooks the three places a Flutter app drops an error, and puts a readable
  /// card where the red screen would be. Call once, from `main`.
  static void start() {
    if (_started) return;
    _started = true;

    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      // Keep the console behaviour (a red screen in debug, a log in release).
      previous?.call(details);
      report(details.exception, details.stack, source: 'flutter');
    };

    // Errors that escape a zone: a failed future nobody awaited, a plugin
    // callback throwing. Returning true says "handled" — the app stays up.
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      report(error, stack, source: 'async');
      return true;
    };

    ErrorWidget.builder = errorWidget;
  }

  /// What a customer sees where a widget failed to build, instead of the red
  /// screen: it says what happened, says the rest of the app is fine, and in
  /// debug still shows the details.
  static Widget errorWidget(FlutterErrorDetails details) {
    return Container(
      color: const Color(0xFFFDF4E0),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Color(0xFFB35A05)),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong on this screen',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17181C),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'The rest of the app still works. Go back and open it again.',
            maxLines: 3,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF7A7D86),
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            Text(
              details.exceptionAsString(),
              maxLines: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFFB35A05)),
            ),
          ],
        ],
      ),
    );
  }

  /// Sends [error] if it is worth sending. Never throws.
  static Future<void> report(
    Object error,
    StackTrace? stack, {
    String source = 'unknown',
  }) async {
    final message = error.toString();
    debugPrint('Duggu error ($source): $message');

    final key = fingerprint(message);
    final now = DateTime.now();
    if (!allow(key, now)) return;
    _sent++;
    _lastSeen[key] = now;

    // Guests have no row to file it under; their error stays in the log.
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseService.client.from('app_errors').insert({
        'user_id': userId,
        'source': source,
        'message': _clip(message, _maxMessage),
        'stack': stack == null ? null : _clip(stack.toString(), _maxStack),
        'platform': Platform.operatingSystem,
        // The exact shape of an error usually differs only in its ids and
        // numbers, so the fingerprint is what makes the table groupable.
        'fingerprint': key,
      });
    } catch (e) {
      // A reporter that throws would make the original error worse.
      debugPrint('Could not report the error: $e');
    }
  }

  /// One error, one row: ids, numbers and whitespace are taken out, so
  /// "Order 8f21c4aa failed" and "Order 91bb0e12 failed" count as the same
  /// bug instead of two.
  static String fingerprint(String message) {
    // Order ids, uuids, hex handles: four or more hex characters that
    // include a digit, so real words ("decade", "facade") are left alone.
    var text = message.replaceAll(
      RegExp(
        r'[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}',
      ),
      '<id>',
    );
    text = text.replaceAll(
      RegExp(r'\b(?=[0-9a-fA-F]{4,}\b)(?=[0-9a-fA-F]*[0-9])[0-9a-fA-F]+\b'),
      '<id>',
    );
    // A uuid or a dashed id leaves several of them in a row: one is enough.
    text = text.replaceAll(RegExp(r'(<id>[\s-]*)+'), '<id> ');
    text = text.replaceAll(RegExp(r'\d+'), '<n>');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return _clip(text.trim(), 200);
  }

  /// Whether [key] may be sent at [now]. Kept pure so the throttle can be
  /// tested without waiting five minutes.
  static bool allow(String key, DateTime now) {
    if (_sent >= maxPerSession) return false;
    final last = _lastSeen[key];
    if (last != null && now.difference(last) < window) return false;
    return true;
  }

  @visibleForTesting
  static void resetForTest() {
    _sent = 0;
    _lastSeen.clear();
    _started = false;
  }

  static String _clip(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}…';
}
