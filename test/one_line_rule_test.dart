import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// House rule: text in buttons, chips, bars and product cards stays on one
/// line (`maxLines: 1` + ellipsis). A second line makes the widget taller and
/// breaks the layout around it, especially on small phones or with a large
/// system font. This test fails when such a Text has no `maxLines`.
///
/// Text that should wrap on purpose (paragraphs, order details) is not in these
/// places, or can carry an explicit `maxLines`.
void main() {
  const cardFiles = [
    'lib/widgets/product_card.dart',
    'lib/widgets/home_all_sections.dart',
    'lib/widgets/home_brand_store_sections.dart',
    'lib/widgets/delivery_address_sheet.dart',
    'lib/screens/home_screen.dart',
    'lib/screens/wishlist_screen.dart',
    'lib/screens/search_screen.dart',
  ];
  final ancestorRe = RegExp(r'Button|Chip|AppBar|SnackBar|SearchBar|Badge');
  bool isId(String c) => RegExp(r'[A-Za-z0-9_.]').hasMatch(c);

  List<String> ancestors(String s, int pos) {
    final out = <String>[];
    var depth = 0;
    for (var i = pos - 1; i >= 0; i--) {
      final c = s[i];
      if (c == ')' || c == ']' || c == '}') depth++;
      if (c == '(' || c == '[' || c == '{') {
        if (depth > 0) {
          depth--;
        } else if (c == '(') {
          var j = i;
          while (j > 0 && isId(s[j - 1])) {
            j--;
          }
          out.add(s.substring(j, i));
        }
      }
    }
    return out;
  }

  test('text in buttons, bars and product cards is single-line', () {
    final problems = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final s = entity.readAsStringSync();
      final all = cardFiles.contains(path);
      for (final m in RegExp(r'(?<![A-Za-z_.])Text\(').allMatches(s)) {
        var d = 0;
        var end = -1;
        for (var i = m.end - 1; i < s.length; i++) {
          if (s[i] == '(') d++;
          if (s[i] == ')' && --d == 0) {
            end = i;
            break;
          }
        }
        if (end < 0) continue;
        final body = s.substring(m.end, end);
        if (body.contains('maxLines') || body.contains(r'\n')) continue;
        if (all || ancestors(s, m.start).any(ancestorRe.hasMatch)) {
          final line = '\n'.allMatches(s.substring(0, m.start)).length + 1;
          problems.add('$path:$line');
        }
      }
    }
    expect(problems, isEmpty,
        reason: 'Add maxLines: 1, overflow: TextOverflow.ellipsis to these');
  });
}
