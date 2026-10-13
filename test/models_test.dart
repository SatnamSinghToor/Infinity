import 'package:flutter_test/flutter_test.dart';

import 'package:duggu/models/festival.dart';
import 'package:duggu/models/product.dart';
import 'package:duggu/widgets/ganesh_art.dart';

Map<String, dynamic> _row({
  String? imageUrl,
  List<dynamic>? imageUrls,
  num price = 100,
  num? discountPrice,
  int stock = 5,
}) =>
    {
      'id': 'p-1',
      'name': 'Diya',
      'price': price,
      'discount_price': discountPrice,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'stock': stock,
      'categories': {'name': 'Pooja Essentials'},
    };

Map<String, dynamic> _festival(String start, String end) => {
      'id': 'f-1',
      'chip_label': 'Ganeshotsav',
      'title': 'Ganesh Chaturthi',
      'start_date': start,
      'end_date': end,
    };

void main() {
  group('Product photos', () {
    test('uses image_urls in order, main photo first', () {
      final p = Product.fromSupabaseRow(
        _row(imageUrl: 'a', imageUrls: ['a', 'b', 'c']),
      );
      expect(p.gallery, ['a', 'b', 'c']);
    });

    test('falls back to the single image_url', () {
      final p = Product.fromSupabaseRow(_row(imageUrl: 'a'));
      expect(p.gallery, ['a']);
    });

    test('has no gallery without any photo, and skips empty entries', () {
      expect(Product.fromSupabaseRow(_row()).gallery, isEmpty);
      final p = Product.fromSupabaseRow(
        _row(imageUrl: 'a', imageUrls: ['', 'a', 5]),
      );
      expect(p.gallery, ['a']);
    });
  });

  group('Product prices and stock', () {
    test('the discount price is the selling price', () {
      final p = Product.fromSupabaseRow(_row(price: 200, discountPrice: 150));
      expect(p.price, 150);
      expect(p.originalPrice, 200);
      expect(p.discountPercent, 25);
    });

    test('no discount means no percent off', () {
      final p = Product.fromSupabaseRow(_row(price: 80));
      expect(p.price, 80);
      expect(p.discountPercent, 0);
    });

    test('an empty stock is not available', () {
      expect(Product.fromSupabaseRow(_row(stock: 0)).isAvailable, isFalse);
      expect(Product.fromSupabaseRow(_row(stock: 3)).isAvailable, isTrue);
    });
  });

  group('Festival calendar', () {
    test('a festival is on from its first day to its last, inclusive', () {
      final f = Festival.fromMap(_festival('2026-09-10', '2026-09-25'));
      expect(f.isOn(DateTime(2026, 9, 9)), isFalse);
      expect(f.isOn(DateTime(2026, 9, 10)), isTrue);
      expect(f.isOn(DateTime(2026, 9, 25, 23, 59)), isTrue);
      expect(f.isOn(DateTime(2026, 9, 26)), isFalse);
    });

    test('the earliest-starting festival wins an overlap', () {
      final early = Festival.fromMap(_festival('2026-10-01', '2026-10-20'));
      final late = Festival.fromMap({
        ..._festival('2026-10-10', '2026-10-30'),
        'chip_label': 'Later',
      });
      final now = DateTime(2026, 10, 15);
      expect(Festival.current([late, early], now)?.chipLabel, 'Ganeshotsav');
      expect(Festival.current([early], DateTime(2026, 11, 1)), isNull);
    });

    test('keeps the row id and falls back to default colours', () {
      final f = Festival.fromMap(_festival('2026-09-10', '2026-09-25'));
      expect(f.id, 'f-1');
      expect(f.showPooja, isFalse);
    });

    test('only Ganesh festivals wear the Ganesha artwork', () {
      expect(isGaneshFestival('Ganesh Chaturthi'), isTrue);
      expect(isGaneshFestival('ganesh utsav'), isTrue);
      expect(isGaneshFestival('Diwali'), isFalse);
      expect(isGaneshFestival(null), isFalse);
    });
  });
}
