import 'package:duggu/utils/description_sections.dart';
import 'package:flutter_test/flutter_test.dart';

/// The product page shows a description in separate boxes, the way
/// Amazon.in's mobile page does. These pin how one block of seller text is
/// read into those boxes.
void main() {
  test('an empty description has no parts', () {
    final parts = DescriptionParts.parse('');
    expect(parts.summary, isEmpty);
    expect(parts.bullets, isEmpty);
    expect(parts.hasDetails, isFalse);
  });

  test('a photo credit with a link is a note, not copy', () {
    final parts = DescriptionParts.parse(
      'Aged Italian-style hard cheese for pasta and salads.\n'
      '\n'
      'Photo: Parmesan cheese knife on block of cheese.jpg (CC0), via '
      'Wikimedia Commons: https://commons.wikimedia.org/wiki/File:Parmesan.jpg',
    );
    expect(
        parts.summary, 'Aged Italian-style hard cheese for pasta and salads.');
    expect(parts.paragraphs, hasLength(1));
    expect(parts.notes.single, startsWith('Photo: Parmesan'));
    expect(parts.specs, isEmpty);
  });

  test('the AI writer layout splits into summary, bullets and sections', () {
    final parts = DescriptionParts.parse(
      'Amul cheese is creamy and rich in calcium.\n'
      'It melts well on pizza and toast.\n'
      '\n'
      'About this item\n'
      '- Made from graded cow and buffalo milk\n'
      '- Good source of calcium and protein\n'
      '- 100% vegetarian\n'
      '\n'
      'Product details\n'
      'A 200 g block, best kept refrigerated after opening.\n'
      '\n'
      'How to use\n'
      'Grate over pasta, or slice for sandwiches.',
    );
    expect(
        parts.summary,
        'Amul cheese is creamy and rich in calcium. It melts well on pizza '
        'and toast.');
    expect(parts.bullets, [
      'Made from graded cow and buffalo milk',
      'Good source of calcium and protein',
      '100% vegetarian',
    ]);
    expect(
        parts.sections.map((s) => s.title), ['Product details', 'How to use']);
    expect(parts.sections.last.paragraphs.single,
        'Grate over pasta, or slice for sandwiches.');
  });

  test('label: value lines become specification rows', () {
    final parts = DescriptionParts.parse(
      'Fresh basmati rice.\n'
      'Weight: 1 kg\n'
      'Country of Origin: India\n'
      'Shelf Life: 12 months',
    );
    expect(parts.specs, [
      ('Weight', '1 kg'),
      ('Country of Origin', 'India'),
      ('Shelf Life', '12 months'),
    ]);
    expect(parts.summary, 'Fresh basmati rice.');
  });

  test('ingredients are kept apart for Important information', () {
    final inline = DescriptionParts.parse(
      'Processed cheese.\nIngredients: cheese, sodium citrate, salt',
    );
    expect(inline.ingredients, 'cheese, sodium citrate, salt');
    expect(inline.specs, isEmpty);

    final titled = DescriptionParts.parse(
      'Processed cheese.\n\nIngredients:\n- cheese\n- salt',
    );
    expect(titled.ingredients, 'cheese, salt');
  });

  test('a long sentence with a colon stays prose', () {
    final parts = DescriptionParts.parse(
      'Note: this cheese is aged for twelve months in cool caves and develops '
      'a sharp, nutty flavour that is perfect for grating.',
    );
    expect(parts.specs, isEmpty);
    expect(parts.paragraphs, hasLength(1));
  });

  test('markdown headings and bold are read, not shown', () {
    final parts = DescriptionParts.parse(
      'Crunchy biscuits.\n\n## Key Features\n* **Crisp** and light\n'
      '* Baked, not fried',
    );
    expect(parts.bullets, ['Crisp and light', 'Baked, not fried']);
  });

  test('nothing is dropped from plain prose', () {
    final parts = DescriptionParts.parse(
      'First paragraph here.\n\nSecond paragraph here.',
    );
    expect(
        parts.paragraphs, ['First paragraph here.', 'Second paragraph here.']);
    expect(parts.sections, isEmpty);
  });
}
