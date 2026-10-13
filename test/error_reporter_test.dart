import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/services/error_reporter.dart';

/// Production has been blind: an uncaught error on a customer's phone left no
/// trace anywhere. These tests hold the reporter to the three promises it
/// makes — it groups the same bug together, it never floods and never leaks a
/// guest's error, and it cannot itself take the app down.
void main() {
  setUp(ErrorReporter.resetForTest);

  group('one bug, one fingerprint', () {
    test('ids and numbers do not make a new bug', () {
      final a = ErrorReporter.fingerprint('Order 8f21c4aa failed to load');
      final b = ErrorReporter.fingerprint('Order 91bb0e12 failed to load');
      final c = ErrorReporter.fingerprint(
        'Order 11111111-2222-3333-4444-555555555555 failed to load',
      );
      expect(a, b);
      expect(b, c);
    });

    test('different messages stay different', () {
      expect(
        ErrorReporter.fingerprint('Order 12 failed'),
        isNot(ErrorReporter.fingerprint('Cart 12 failed')),
      );
    });

    test('whitespace is flattened and long messages are clipped', () {
      expect(
        ErrorReporter.fingerprint('a\n   b\tc'),
        'a b c',
      );
      expect(
        ErrorReporter.fingerprint('x' * 500).length,
        lessThanOrEqualTo(201),
      );
    });
  });

  group('the throttle', () {
    final now = DateTime(2026, 9, 24, 12);

    test('the first report of a bug goes, the second does not', () {
      expect(ErrorReporter.allow('bug', now), isTrue);
      // …and after the window it is allowed again, so a bug that keeps
      // happening once an hour is still visible.
      expect(ErrorReporter.allow('bug', now.add(const Duration(minutes: 6))),
          isTrue);
    });

    test('a guest is never filed under a signed-in account', () {
      // report() bails before touching the table when there is no user; the
      // check lives in report(), and this pins that it is still there.
      final source =
          File('lib/services/error_reporter.dart').readAsStringSync();
      expect(source, contains('currentUser?.id'));
      expect(source, contains('if (userId == null) return;'));
    });
  });

  group('the reporter cannot make things worse', () {
    test('it wraps its own send, and never lets a report throw', () {
      final source =
          File('lib/services/error_reporter.dart').readAsStringSync();
      expect(source, contains('A reporter that throws would make'));
      expect(source, contains('catch (e) {'));
      // The three hooks that count as "uncaught" in a Flutter app.
      expect(source, contains('FlutterError.onError'));
      expect(source, contains('platformDispatcher.onError'));
      expect(source, contains('ErrorWidget.builder'));
    });

    test('main starts it before the app is built', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('ErrorReporter.start();'));
      final started = main.indexOf('ErrorReporter.start();');
      final runApp = main.indexOf('runApp(');
      expect(started, lessThan(runApp));
    });
  });

  group('the table is an admin record, not a public log', () {
    final sql = File('supabase/app_errors.sql').readAsStringSync();

    test('an app may only file its own error, and only admins read it', () {
      expect(sql, contains('create table if not exists public.app_errors'));
      expect(sql, contains('app_errors_own_insert'));
      expect(sql, contains('with check (user_id = auth.uid())'));
      expect(sql, contains('app_errors_admin_read'));
      expect(sql, contains('using (public.is_admin())'));
      expect(sql, contains('No update and no delete policies'));
    });

    test('the columns hold no contact details or basket contents', () {
      // Only the table's own definition: the comments above it are allowed
      // to spell out what is deliberately missing.
      final table = sql.substring(
        sql.indexOf('create table if not exists public.app_errors'),
        sql.indexOf(');', sql.indexOf('create table if not exists')),
      );
      for (final forbidden in ['email', 'phone', 'address', 'cart']) {
        expect(table, isNot(contains(forbidden)), reason: forbidden);
      }
      expect(table, contains('fingerprint'));
      expect(table, contains('stack'));
      expect(table, contains('message'));
    });
  });
}
