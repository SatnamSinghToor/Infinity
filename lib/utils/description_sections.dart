/// A product description, split into the parts a shop page shows in separate
/// boxes.
///
/// Sellers and the AI writer both type one block of text, but the page is
/// laid out the way Amazon.in's mobile product page is (checked against a
/// live listing): "Top highlights" with the "About this item" bullets,
/// "Product specifications" as label/value rows, "Additional details" for
/// the prose, and "Important information" for ingredients. This reads the
/// text for those parts:
///
/// - `- `, `• `, `* ` or `1. ` lines are bullets;
/// - a short line such as `About this item`, `How to use:` or `## Storage`
///   starts a titled section;
/// - `Weight: 200 g` is a specification row;
/// - `Ingredients: …` (or an Ingredients section) is kept apart, since the
///   page shows it under Important information;
/// - a line with a web link (a photo credit, usually) is a small note, not
///   part of the copy.
///
/// Anything that fits none of these stays a paragraph, so no text is ever
/// dropped.
class DescriptionParts {
  /// Untitled prose, in order. The first one is the product's summary.
  final List<String> paragraphs;

  /// The "About this item" points.
  final List<String> bullets;

  /// Label/value rows, e.g. ("Weight", "200 g").
  final List<(String, String)> specs;

  /// Titled sections that are none of the special ones above.
  final List<DescriptionSection> sections;

  /// What the product is made of, when the text says.
  final String? ingredients;

  /// Lines under a Nutrition heading.
  final List<String> nutrition;

  /// Lines carrying links, such as a photo credit.
  final List<String> notes;

  const DescriptionParts({
    this.paragraphs = const [],
    this.bullets = const [],
    this.specs = const [],
    this.sections = const [],
    this.ingredients,
    this.nutrition = const [],
    this.notes = const [],
  });

  /// One or two lines for under the product's name.
  String get summary => paragraphs.isEmpty ? '' : paragraphs.first;

  /// Whether there is prose for "Additional details".
  bool get hasDetails => paragraphs.isNotEmpty || sections.isNotEmpty;

  static final _bullet = RegExp(r'^(?:[-•*–·▪]|\d{1,2}[.)])\s+(.+)$');
  static final _markdownHeading = RegExp(r'^#{1,6}\s*(.+?)\s*#*$');
  static final _boldLine = RegExp(r'^\*\*(.+?)\*\*:?$');
  static final _spec = RegExp(r"^([A-Za-z][A-Za-z0-9 &/().'-]{0,30}):\s+(.+)$");
  static final _link = RegExp(r'https?://|www\.', caseSensitive: false);
  static final _endsSentence = RegExp(r'[.!?,;]$');

  static const _bulletTitles = {
    'about this item',
    'about the item',
    'about this product',
    'key features',
    'features',
    'highlights',
    'top highlights',
    'key benefits',
    'benefits',
  };
  static const _specTitles = {
    'product details',
    'product specifications',
    'specifications',
    'technical details',
    'item details',
  };
  static const _nutritionTitles = {
    'nutrition',
    'nutritional info',
    'nutritional information',
    'nutrition facts',
    'nutrition information',
  };

  /// Reads [text]; an empty text gives empty parts.
  static DescriptionParts parse(String text) {
    final paragraphs = <String>[];
    final bullets = <String>[];
    final specs = <(String, String)>[];
    final sections = <DescriptionSection>[];
    final nutrition = <String>[];
    final notes = <String>[];
    String? ingredients;

    String? title;
    var sectionParagraphs = <String>[];
    var sectionBullets = <String>[];
    final buffer = StringBuffer();

    void flushParagraph() {
      final p = buffer.toString().trim();
      buffer.clear();
      if (p.isEmpty) return;
      if (title == null) {
        paragraphs.add(p);
      } else {
        sectionParagraphs.add(p);
      }
    }

    void closeSection() {
      flushParagraph();
      final t = title;
      if (t != null) {
        final key = _key(t);
        if (_bulletTitles.contains(key)) {
          bullets
            ..addAll(sectionBullets)
            ..addAll(sectionParagraphs);
        } else if (_nutritionTitles.contains(key)) {
          nutrition
            ..addAll(sectionParagraphs)
            ..addAll(sectionBullets);
        } else if (key == 'ingredients') {
          final all = [...sectionParagraphs, ...sectionBullets];
          if (all.isNotEmpty) ingredients = all.join(', ');
        } else if (sectionParagraphs.isNotEmpty || sectionBullets.isNotEmpty) {
          sections.add(DescriptionSection(
            title: t,
            paragraphs: sectionParagraphs,
            bullets: sectionBullets,
          ));
        }
      }
      title = null;
      sectionParagraphs = <String>[];
      sectionBullets = <String>[];
    }

    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .toList();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        flushParagraph();
        continue;
      }
      if (_link.hasMatch(line)) {
        flushParagraph();
        notes.add(line);
        continue;
      }

      final heading = _headingOf(line, lines, i, isFirst: _isFirst(lines, i));
      if (heading != null) {
        closeSection();
        title = heading;
        continue;
      }

      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        flushParagraph();
        final point = _plain(bullet.group(1)!);
        if (point.isEmpty) continue;
        if (title == null) {
          bullets.add(point);
        } else {
          sectionBullets.add(point);
        }
        continue;
      }

      final spec = _spec.firstMatch(line);
      if (spec != null) {
        final label = _plain(spec.group(1)!);
        final value = _plain(spec.group(2)!);
        if (_key(label) == 'ingredients') {
          flushParagraph();
          ingredients = value;
          continue;
        }
        final shortLabel = label.split(RegExp(r'\s+')).length <= 4;
        final shortValue = value.length <= 80 && !_endsLikeProse(value);
        if (shortLabel && shortValue) {
          flushParagraph();
          specs.add((label, value));
          continue;
        }
      }

      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(_plain(line));
    }
    closeSection();

    return DescriptionParts(
      paragraphs: paragraphs,
      bullets: bullets,
      specs: specs,
      sections: sections,
      ingredients: ingredients,
      nutrition: nutrition,
      notes: notes,
    );
  }

  /// The title [line] starts, or null when it is ordinary text.
  static String? _headingOf(
    String line,
    List<String> lines,
    int index, {
    required bool isFirst,
  }) {
    final markdown = _markdownHeading.firstMatch(line);
    if (markdown != null) return _plain(markdown.group(1)!);
    final bold = _boldLine.firstMatch(line);
    if (bold != null) return _plain(bold.group(1)!);

    final bare =
        line.endsWith(':') ? line.substring(0, line.length - 1).trim() : line;
    if (bare.isEmpty || _bullet.hasMatch(line)) return null;
    final key = _key(bare);
    if (_bulletTitles.contains(key) ||
        _specTitles.contains(key) ||
        _nutritionTitles.contains(key) ||
        key == 'ingredients') {
      return _plain(bare);
    }

    // Any other short line with no sentence ending, followed by more text,
    // reads as a heading: "How to use", "Storage tips:". The very first
    // line is the product's opening, not a heading.
    // "Weight: 1 kg" is a row, not a title.
    if (isFirst || bare.contains(':')) return null;
    final words = bare.split(RegExp(r'\s+')).length;
    final short = words <= 5 && bare.length <= 40;
    final capital = RegExp(r'^[A-Z]').hasMatch(bare);
    final sentence = _endsSentence.hasMatch(bare);
    final hasNext = lines.skip(index + 1).any((l) => l.isNotEmpty);
    if (short && capital && !sentence && hasNext) return _plain(bare);
    return null;
  }

  static bool _isFirst(List<String> lines, int index) =>
      lines.take(index).every((l) => l.isEmpty);

  static bool _endsLikeProse(String value) =>
      value.endsWith('.') && value.split(RegExp(r'\s+')).length > 8;

  static String _key(String title) =>
      title.toLowerCase().replaceAll(RegExp(r'[:*#]'), '').trim();

  /// Without markdown emphasis, which the page does not render.
  static String _plain(String text) =>
      text.replaceAll('**', '').replaceAll('__', '').trim();
}

/// A titled part of a description, e.g. "How to use" and what follows it.
class DescriptionSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const DescriptionSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}
