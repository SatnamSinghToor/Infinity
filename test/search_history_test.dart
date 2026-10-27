import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duggu/services/search_history.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty', () async {
    expect(await SearchHistory.load(), isEmpty);
  });

  test('a search is remembered, newest first', () async {
    await SearchHistory.add('milk');
    await SearchHistory.add('bread');
    expect(await SearchHistory.load(), ['bread', 'milk']);
  });

  test('searching the same term again moves it to the front once', () async {
    await SearchHistory.add('milk');
    await SearchHistory.add('bread');
    await SearchHistory.add('milk');
    expect(await SearchHistory.load(), ['milk', 'bread']);
  });

  test('matching is case insensitive', () async {
    await SearchHistory.add('Milk');
    await SearchHistory.add('milk');
    expect(await SearchHistory.load(), ['milk']);
  });

  test('a blank search is not remembered', () async {
    await SearchHistory.add('   ');
    expect(await SearchHistory.load(), isEmpty);
  });

  test('only the most recent 8 searches are kept', () async {
    for (var i = 0; i < 10; i++) {
      await SearchHistory.add('term$i');
    }
    final saved = await SearchHistory.load();
    expect(saved.length, 8);
    expect(saved.first, 'term9');
    expect(saved, isNot(contains('term0')));
    expect(saved, isNot(contains('term1')));
  });

  test('clear empties the history', () async {
    await SearchHistory.add('milk');
    await SearchHistory.clear();
    expect(await SearchHistory.load(), isEmpty);
  });
}
