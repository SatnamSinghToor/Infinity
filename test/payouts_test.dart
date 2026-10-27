import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/models/payout_request.dart';

/// Payouts are the one place in the app where money leaves towards a person
/// rather than towards the shop, so the rule is that the app never decides the
/// amount: it asks, the database checks, and an admin approves. These tests
/// hold that shape in place — the SQL that checks, the screen that asks, the
/// queue that decides, and the two doors that lead there.
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('the database checks the money, not the app', () {
    final sql = read('supabase/payout_requests.sql');

    test('the table, its states and its indexes exist', () {
      expect(
          sql, contains('create table if not exists public.payout_requests'));
      expect(sql, contains("'pending', 'approved', 'rejected', 'paid'"));
      expect(sql, contains('enable row level security'));
      expect(sql, contains('payout_requests_user_idx'));
    });

    test('a partner may only ask for themselves, and only for their role', () {
      expect(sql, contains('payout_requests_own_insert'));
      expect(sql, contains('user_id = auth.uid()'));
      expect(sql, contains('and status = \'pending\''));
    });

    test('only an admin may decide, and nobody may delete the record', () {
      expect(sql, contains('payout_requests_admin_update'));
      expect(sql, contains('using (public.is_admin())'));
      expect(sql, contains('No deletes, by anyone'));
    });

    test('the amount is checked against what was really earned', () {
      expect(sql, contains('create or replace function public.request_payout'));
      expect(sql, contains('OVER_BALANCE:%'));
      expect(sql, contains('sum(seller_payout)'));
      expect(sql, contains('from public.delivery_earnings'));
      // Already-asked-for money cannot be asked for again while pending.
      expect(sql, contains("status in ('pending', 'approved', 'paid')"));
    });

    test('asking and reading the balance are for signed-in users only', () {
      expect(
        sql,
        contains(
          'revoke execute on function public.request_payout(numeric, text, text)\n'
          '  from public, anon;',
        ),
      );
      expect(sql, contains('grant execute on function public.request_payout'));
      expect(sql, contains('create or replace function public.payout_balance'));
    });
  });

  group('the screens', () {
    test('the partner asks through the database, never around it', () {
      final screen = read('lib/screens/payouts_screen.dart');
      expect(screen, contains("rpc('request_payout'"));
      expect(screen, contains("rpc('payout_balance'"));
      expect(screen, contains('RoleBody('));
      expect(screen, contains('bool _loadFailed = false;'));
      expect(screen, contains("Couldn't load your payouts"));
      expect(screen, isNot(contains('catch (_) {}')));
    });

    test('the admin queue decides, and paid is a separate step', () {
      final admin = read('lib/screens/admin/admin_payouts_screen.dart');
      expect(admin, contains("'status': approve ? 'approved' : 'rejected'"));
      expect(admin, contains("'status': 'paid'"));
      expect(admin, contains('payment_reference'));
      expect(admin, contains('RoleBody('));
      // The words moved into the string files with the screen's l10n
      // migration; the screen must still ask for them.
      expect(admin, contains('adminPayoutsLoadFailed'));
      expect(
        read('lib/l10n/app_en.arb'),
        contains("Couldn't load the payout queue"),
      );
      expect(admin, isNot(contains('catch (_) {}')));
    });

    test('both earning screens open it, and moderation counts it', () {
      for (final path in [
        'lib/screens/seller/seller_earnings_screen.dart',
        'lib/screens/delivery/delivery_earnings_screen.dart',
      ]) {
        final src = read(path);
        expect(src, contains("import '../payouts_screen.dart';"), reason: path);
        expect(src, contains('PayoutsScreen()'), reason: path);
        // The button's words live in the string files for the screens that
        // have migrated, and in the screen itself for the rest.
        final saysPayouts = src.contains('sellerEarningsPayouts') ||
            src.contains('deliveryEarningsPayouts') ||
            src.contains('Payouts & withdrawals');
        expect(saysPayouts, isTrue, reason: path);
      }

      // Both migrated screens' sentence is in the string files.
      final arb = read('lib/l10n/app_en.arb');
      expect(
        arb,
        contains('"sellerEarningsPayouts": "Payouts & withdrawals"'),
      );
      expect(
        arb,
        contains('"deliveryEarningsPayouts": "Payouts & withdrawals"'),
      );

      final hub = read('lib/screens/admin/admin_moderation_screen.dart');
      expect(hub, contains('AdminPayoutsScreen()'));
      expect(hub, contains("from('payout_requests')"));
      expect(hub, contains('_pendingPayouts'));
    });
  });

  group('the model', () {
    test('reads a row as the queue writes it', () {
      final request = PayoutRequest.fromSupabaseRow({
        'id': '11111111-2222-3333-4444-555555555555',
        'user_id': 'seller-1',
        'role': 'delivery',
        'amount': 480.5,
        'method': 'duggu@upi',
        'note': 'weekly',
        'status': 'approved',
        'decision_note': 'Approved. The transfer will follow.',
        'payment_reference': 'UTR12345',
        'created_at': '2026-09-24T10:00:00Z',
      });

      expect(request.amount, 480.5);
      expect(request.roleLabel, 'Delivery partner');
      expect(request.isPending, isFalse);
      expect(request.decisionNote, contains('Approved'));
      expect(request.paymentReference, 'UTR12345');
    });

    test('a fresh request is pending, and a seller is a seller', () {
      final request = PayoutRequest.fromSupabaseRow({
        'id': 'x',
        'user_id': 'seller-1',
        'role': 'seller',
        'amount': 100,
        'created_at': '2026-09-24T10:00:00Z',
      });

      expect(request.status, 'pending');
      expect(request.isPending, isTrue);
      expect(request.roleLabel, 'Seller');
      expect(request.method, isNull);
    });
  });
}
