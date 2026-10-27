import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/services/analytics.dart';

/// The shop has been making decisions blind, and this is the fix: a small
/// named set of events, each with the exact fields it may carry. These tests
/// hold the promises that make it safe to ship — nothing unlisted goes out,
/// nothing personal fits, and a busy day cannot flood the table.
void main() {
  setUp(Analytics.resetForTest);
  tearDown(Analytics.resetForTest);

  test('an event the catalog does not know is dropped', () {
    Analytics.log('nonsense_event', {'x': 1});
    expect(Analytics.accepted, 0);

    Analytics.log('add_to_cart', {'product_id': 'p1', 'quantity': 1});
    expect(Analytics.accepted, 1);
  });

  test('a property that event may not carry is dropped', () {
    expect(
      Analytics.cleanProps('add_to_cart', {
        'product_id': 'p1',
        'quantity': 2,
        'phone': '9999999999',
        'note': 'leave at the door',
      }),
      {'product_id': 'p1', 'quantity': 2},
    );
  });

  test('text is clipped, nulls go, numbers and flags survive', () {
    final search = Analytics.cleanProps('search', {
      'term': 'x' * 200,
      'results': null,
    });
    expect((search['term'] as String).length, Analytics.maxTextLength + 1);
    expect(search.containsKey('results'), isFalse);

    expect(
      Analytics.cleanProps('order_placed', {'coupon': true, 'payment': 'cod'}),
      {'coupon': true, 'payment': 'cod'},
    );
  });

  test('one run of the app stops at its cap', () {
    for (var i = 0; i < Analytics.maxPerSession + 50; i++) {
      Analytics.log('app_open');
    }
    expect(Analytics.accepted, Analytics.maxPerSession);
  });

  test('every event the app logs is in the catalog', () {
    final names = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();
      for (final m in RegExp(r"Analytics\.log\('([a-z_]+)'").allMatches(src)) {
        names.add(m.group(1)!);
      }
    }
    expect(names, isNotEmpty);
    for (final name in names) {
      expect(Analytics.catalog.containsKey(name), isTrue, reason: name);
    }
  });

  test('the table carries its own guard rails', () {
    final sql = File('supabase/app_events.sql').readAsStringSync();
    expect(sql, contains('create table if not exists public.app_events'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('for insert to authenticated'));
    expect(sql, contains('with check (user_id = auth.uid())'));
    expect(sql, contains('using (public.is_admin())'));
  });

  test('the app starts recording when it starts', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('Analytics.start()'));
  });
}
