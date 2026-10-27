import 'package:duggu/widgets/category_picker_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seller's category picker replaced one long dropdown. These pin how
/// the categories are grouped and searched.
void main() {
  final tree = CategoryTree.from(const [
    PickerCategory(id: 'kids', name: 'Kids'),
    PickerCategory(id: 'toys', name: 'Toys & Games', parentId: 'kids'),
    PickerCategory(id: 'art', name: 'Art & School', parentId: 'kids'),
    PickerCategory(id: 'decor', name: 'Decor'),
    PickerCategory(id: 'light', name: 'Lighting & Candles', parentId: 'decor'),
    PickerCategory(id: 'fresh', name: 'Fresh Fruits'),
    // Its main category is switched off, so it stands on its own.
    PickerCategory(id: 'orphan', name: 'Haircare', parentId: 'gone'),
  ]);

  test('main categories hold their sub-categories', () {
    expect(tree.mains.map((c) => c.id), ['kids', 'decor', 'fresh', 'orphan']);
    expect(tree.subs['kids']!.map((c) => c.id), ['toys', 'art']);
  });

  test('a group heading cannot be picked; a leaf can', () {
    expect(tree.isPickable(tree.byId['kids']!), isFalse);
    expect(tree.isPickable(tree.byId['toys']!), isTrue);
    expect(tree.isPickable(tree.byId['fresh']!), isTrue);
    expect(tree.isPickable(tree.byId['orphan']!), isTrue);
  });

  test('search finds sub-categories by their own or their group name', () {
    expect(tree.search('candle').map((c) => c.id), ['light']);
    expect(tree.search('kids').map((c) => c.id), ['art', 'toys']);
    expect(tree.search('TOYS').single.id, 'toys');
    expect(tree.search('games kids').single.id, 'toys');
  });

  test('search never offers a heading, and blank search is empty', () {
    expect(tree.search('decor').map((c) => c.id), ['light']);
    expect(tree.search('   '), isEmpty);
    expect(tree.search('vacuum'), isEmpty);
  });

  test('a name that starts with the search comes first', () {
    final t = CategoryTree.from(const [
      PickerCategory(id: 'a', name: 'Pet Toys'),
      PickerCategory(id: 'b', name: 'Toys & Games'),
    ]);
    expect(t.search('toys').map((c) => c.id), ['b', 'a']);
  });
}
