import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'festive_tokens.dart';

/// Hand-drawn line glyphs for the category strip and the bottom bar.
///
/// The reference uses a bespoke icon set; drawing them as paths keeps the
/// screen free of nine imported images, scales to any pixel ratio without
/// artefacts, and tints with a single colour.
class FestiveGlyphPainter extends CustomPainter {
  const FestiveGlyphPainter({
    required this.glyph,
    required this.color,
    this.strokeWidth = 1.7,
    this.fill,
  });

  final FestiveGlyph glyph;
  final Color color;
  final double strokeWidth;

  /// Solid fill behind the stroke — the active Home tab in the bottom bar is
  /// a yellow house with a black outline.
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide / 24;
    canvas.save();
    canvas.scale(s, s);

    final List<Path> strokes = <Path>[];
    final List<Path> fills = <Path>[];
    final List<Path> accents = <Path>[];
    _build(glyph, strokes, fills, accents);

    if (fill != null) {
      final Paint fillPaint = Paint()
        ..color = fill!
        ..style = PaintingStyle.fill;
      for (final Path p in fills) {
        canvas.drawPath(p, fillPaint);
      }
      // Knock-outs (the Home door) take the outline colour.
      final Paint accentPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      for (final Path p in accents) {
        canvas.drawPath(p, accentPaint);
      }
    }

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final Path p in strokes) {
      canvas.drawPath(p, stroke);
    }
    canvas.restore();
  }

  void _build(
    FestiveGlyph glyph,
    List<Path> strokes,
    List<Path> fills,
    List<Path> accents,
  ) {
    switch (glyph) {
      case FestiveGlyph.basket:
        _basket(strokes, fills);
      case FestiveGlyph.diya:
        _diya(strokes, fills);
      case FestiveGlyph.party:
        _party(strokes, fills);
      case FestiveGlyph.headphones:
        _headphones(strokes, fills);
      case FestiveGlyph.beauty:
        _beauty(strokes, fills);
      case FestiveGlyph.gift:
        _gift(strokes, fills);
      case FestiveGlyph.home:
        _home(strokes, fills, accents);
      case FestiveGlyph.grid:
        _grid(strokes, fills);
      case FestiveGlyph.printer:
        _printer(strokes, fills);
    }
  }

  // A grocery basket with two bottles peeking over the rim.
  void _basket(List<Path> strokes, List<Path> fills) {
    final Path body = Path()
      ..moveTo(2.6, 10.4)
      ..lineTo(21.4, 10.4)
      ..lineTo(19.4, 19.4)
      ..quadraticBezierTo(19.1, 21, 17.5, 21)
      ..lineTo(6.5, 21)
      ..quadraticBezierTo(4.9, 21, 4.6, 19.4)
      ..close();
    strokes.add(body);

    final Path bottleA = Path()
      ..moveTo(6.4, 10.2)
      ..lineTo(6.4, 7.6)
      ..quadraticBezierTo(6.4, 6.2, 7.4, 6.2)
      ..lineTo(7.9, 6.2)
      ..lineTo(7.9, 4.6)
      ..lineTo(9.9, 4.6)
      ..lineTo(9.9, 6.2)
      ..lineTo(10.4, 6.2)
      ..quadraticBezierTo(11.4, 6.2, 11.4, 7.6)
      ..lineTo(11.4, 10.2);
    strokes.add(bottleA);

    final Path bottleB = Path()
      ..moveTo(13.4, 10.2)
      ..lineTo(13.4, 8.4)
      ..quadraticBezierTo(13.4, 7.2, 14.3, 7.2)
      ..lineTo(16.5, 7.2)
      ..quadraticBezierTo(17.4, 7.2, 17.4, 8.4)
      ..lineTo(17.4, 10.2);
    strokes.add(bottleB);
  }

  // A lotus diya: shallow bowl, rice grains on the rim, flame and sparkles.
  void _diya(List<Path> strokes, List<Path> fills) {
    final Path bowl = Path()
      ..moveTo(3.4, 13.6)
      ..quadraticBezierTo(3.6, 20.4, 12, 20.4)
      ..quadraticBezierTo(20.4, 20.4, 20.6, 13.6)
      ..close();
    fills.add(bowl);
    strokes.add(bowl);

    for (int i = 0; i < 5; i++) {
      final double x = 7.4 + i * 2.3;
      strokes.add(
        Path()..addOval(Rect.fromCircle(center: Offset(x, 15.4), radius: 0.55)),
      );
    }

    // Flame: a diamond with gently bowed sides.
    final Path flame = Path()
      ..moveTo(12, 3.4)
      ..quadraticBezierTo(15.4, 8.4, 12, 11.6)
      ..quadraticBezierTo(8.6, 8.4, 12, 3.4)
      ..close();
    fills.add(flame);
    strokes.add(flame);

    strokes.add(_sparkle(const Offset(17.6, 5.6), 1.9));
    strokes.add(_sparkle(const Offset(6.2, 7.2), 1.4));
  }

  // A party hat with two sparkles.
  void _party(List<Path> strokes, List<Path> fills) {
    final Path hat = Path()
      ..moveTo(6.6, 20.2)
      ..lineTo(11.2, 20.2)
      ..lineTo(15.4, 6.6)
      ..quadraticBezierTo(16.2, 4.4, 14.1, 4.2)
      ..close();
    fills.add(hat);
    strokes.add(hat);

    strokes.add(
      Path()
        ..moveTo(4.8, 20.2)
        ..lineTo(12.6, 20.2),
    );
    strokes.add(_sparkle(const Offset(19.2, 5.4), 2.2));
    strokes.add(_sparkle(const Offset(4.6, 11.2), 1.5));
  }

  void _headphones(List<Path> strokes, List<Path> fills) {
    final Path band = Path()
      ..moveTo(4.4, 15.2)
      ..lineTo(4.4, 13.2)
      ..arcToPoint(const Offset(19.6, 13.2),
          radius: const Radius.circular(7.6), clockwise: true)
      ..lineTo(19.6, 15.2);
    strokes.add(band);

    final Path cupLeft = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(2.6, 13.8, 4.6, 7.2),
        const Radius.circular(2.1),
      ));
    final Path cupRight = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(16.8, 13.8, 4.6, 7.2),
        const Radius.circular(2.1),
      ));
    fills.add(cupLeft);
    fills.add(cupRight);
    strokes.add(cupLeft);
    strokes.add(cupRight);
  }

  // A lipstick and a brush, crossed.
  void _beauty(List<Path> strokes, List<Path> fills) {
    final Path lipstick = Path()
      ..moveTo(6.2, 21)
      ..lineTo(6.2, 11.2)
      ..lineTo(10.4, 11.2)
      ..lineTo(10.4, 21)
      ..close();
    fills.add(lipstick);
    strokes.add(lipstick);
    strokes.add(
      Path()
        ..moveTo(6.2, 13.6)
        ..lineTo(10.4, 13.6),
    );

    final Path bullet = Path()
      ..moveTo(7.2, 11)
      ..lineTo(7.2, 7.4)
      ..lineTo(9.4, 4.8)
      ..lineTo(9.4, 11)
      ..close();
    strokes.add(bullet);

    final Path brush = Path()
      ..moveTo(13.4, 21)
      ..lineTo(15.6, 10.4)
      ..lineTo(16.9, 10.6)
      ..lineTo(15.4, 21)
      ..close();
    fills.add(brush);
    strokes.add(brush);
    strokes.add(
      Path()
        ..moveTo(15.4, 9.8)
        ..lineTo(17.6, 4)
        ..quadraticBezierTo(19.4, 5.2, 18.6, 7.8)
        ..lineTo(18.2, 9.4)
        ..close(),
    );
  }

  void _gift(List<Path> strokes, List<Path> fills) {
    final Path box = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.4, 11.4, 15.2, 9.2),
        const Radius.circular(1.6),
      ));
    final Path lid = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(3.4, 8.2, 17.2, 3.6),
        const Radius.circular(1.4),
      ));
    fills.add(box);
    fills.add(lid);
    strokes.add(box);
    strokes.add(lid);
    strokes.add(
      Path()
        ..moveTo(12, 11.4)
        ..lineTo(12, 20.4),
    );

    final Path bow = Path()
      ..moveTo(12, 8)
      ..quadraticBezierTo(8.2, 7.6, 8.4, 5.4)
      ..quadraticBezierTo(8.6, 3.4, 10.6, 4.4)
      ..quadraticBezierTo(11.8, 5.2, 12, 8)
      ..quadraticBezierTo(12.2, 5.2, 13.4, 4.4)
      ..quadraticBezierTo(15.4, 3.4, 15.6, 5.4)
      ..quadraticBezierTo(15.8, 7.6, 12, 8)
      ..close();
    strokes.add(bow);
  }

  void _home(List<Path> strokes, List<Path> fills, List<Path> accents) {
    final Path house = Path()
      ..moveTo(3.2, 11.2)
      ..lineTo(12, 3.4)
      ..lineTo(20.8, 11.2)
      ..lineTo(19.2, 11.2)
      ..lineTo(19.2, 19.4)
      ..quadraticBezierTo(19.2, 20.6, 18, 20.6)
      ..lineTo(6, 20.6)
      ..quadraticBezierTo(4.8, 20.6, 4.8, 19.4)
      ..lineTo(4.8, 11.2)
      ..close();
    fills.add(house);
    strokes.add(house);

    final Path door = Path()
      ..moveTo(10, 20.6)
      ..lineTo(10, 15.8)
      ..quadraticBezierTo(10, 14.6, 12, 14.6)
      ..quadraticBezierTo(14, 14.6, 14, 15.8)
      ..lineTo(14, 20.6);
    accents.add(door);
    strokes.add(door);
  }

  void _grid(List<Path> strokes, List<Path> fills) {
    for (final Offset c in const <Offset>[
      Offset(7.4, 7.4),
      Offset(16.6, 7.4),
      Offset(7.4, 16.6),
      Offset(16.6, 16.6),
    ]) {
      final Path circle = Path()..addOval(Rect.fromCircle(center: c, radius: 3.4));
      fills.add(circle);
      strokes.add(circle);
    }
  }

  void _printer(List<Path> strokes, List<Path> fills) {
    final Path sheet = Path()
      ..moveTo(6.8, 8.4)
      ..lineTo(6.8, 4.4)
      ..lineTo(17.2, 4.4)
      ..lineTo(17.2, 8.4);
    strokes.add(sheet);

    final Path body = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(3.4, 8.4, 17.2, 7.6),
        const Radius.circular(1.8),
      ));
    fills.add(body);
    strokes.add(body);

    final Path out = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(7.4, 14.2, 9.2, 6.2),
        const Radius.circular(1.2),
      ));
    fills.add(out);
    strokes.add(out);

    strokes.add(
      Path()..addOval(Rect.fromCircle(center: const Offset(17.4, 11.6), radius: 0.75)),
    );
  }

  static Path _sparkle(Offset center, double radius) {
    final Path p = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx + radius * 0.22, center.dy - radius * 0.22,
          center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx + radius * 0.22, center.dy + radius * 0.22,
          center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx - radius * 0.22, center.dy + radius * 0.22,
          center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx - radius * 0.22, center.dy - radius * 0.22,
          center.dx, center.dy - radius)
      ..close();
    return p;
  }

  @override
  bool shouldRepaint(FestiveGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.fill != fill;
}

/// Widget wrapper for [FestiveGlyphPainter] with a semantic label.
class FestiveGlyphIcon extends StatelessWidget {
  const FestiveGlyphIcon({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 22,
    this.strokeWidth = 1.7,
    this.fill,
    this.semanticLabel,
  });

  final FestiveGlyph glyph;
  final Color color;
  final double size;
  final double strokeWidth;
  final Color? fill;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget painted = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: FestiveGlyphPainter(
          glyph: glyph,
          color: color,
          strokeWidth: strokeWidth,
          fill: fill,
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: painted);
    return Semantics(label: semanticLabel, image: true, child: painted);
  }
}

/// Twinkling fairy lights.
///
/// One `AnimationController` per string drives every bulb; per-bulb phase
/// offsets come from the index, so the whole garland shimmers on a single
/// ticker and a single [CustomPaint]. The widget paints inside a
/// [RepaintBoundary] and only repaints itself, never its siblings.
class FairyLights extends StatefulWidget {
  const FairyLights.hanging({
    super.key,
    this.color = FestiveColors.bulb,
    this.lineColor = FestiveColors.goldLine,
    this.strings = 2,
    this.sag = 1,
    this.height = 86,
    this.intensity = 1,
  })  : _style = _FairyStyle.hanging,
        bulbCount = 0;

  const FairyLights.toran({
    super.key,
    this.color = FestiveColors.bulb,
    this.lineColor = FestiveColors.goldLine,
    this.height = 34,
    this.bulbCount = 22,
    this.intensity = 1,
  })  : _style = _FairyStyle.toran,
        strings = 1,
        sag = 1;

  final Color color;
  final Color lineColor;
  final int strings;
  final double sag;
  final double height;
  final double intensity;
  final int bulbCount;
  final _FairyStyle _style;

  @override
  State<FairyLights> createState() => _FairyLightsState();
}

enum _FairyStyle { hanging, toran }

class _FairyLightsState extends State<FairyLights> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the OS "remove animations" setting: the garland stays lit but
    // stops twinkling, and the ticker is parked so it costs nothing.
    if (FestiveMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 0.35;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _FairyLightsPainter(
            progress: _controller,
            style: widget._style,
            color: widget.color,
            lineColor: widget.lineColor,
            strings: widget.strings,
            sag: widget.sag,
            bulbCount: widget.bulbCount,
            intensity: widget.intensity,
          ),
        ),
      ),
    );
  }
}

class _FairyLightsPainter extends CustomPainter {
  _FairyLightsPainter({
    required this.progress,
    required this.style,
    required this.color,
    required this.lineColor,
    required this.strings,
    required this.sag,
    required this.bulbCount,
    required this.intensity,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final _FairyStyle style;
  final Color color;
  final Color lineColor;
  final int strings;
  final double sag;
  final int bulbCount;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value;
    // A unit-radius shader, reused for every bulb by scaling the canvas.
    // Creating one gradient per bulb per frame would allocate ~50 shaders at
    // 60 fps; this allocates one.
    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withAlpha((110 * intensity).round().clamp(0, 255).toInt()),
          color.withAlpha((34 * intensity).round().clamp(0, 255).toInt()),
          color.withAlpha(0),
        ],
        stops: const <double>[0, 0.42, 1],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
    if (style == _FairyStyle.hanging) {
      _paintHanging(canvas, size, t, glow);
    } else {
      _paintToran(canvas, size, t, glow);
    }
  }

  /// Two catenary strings that meet in the middle, exactly like the arc over
  /// the header in the reference.
  void _paintHanging(Canvas canvas, Size size, double t, Paint glow) {
    final Paint line = Paint()
      ..color = lineColor.withAlpha(190)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int s = 0; s < strings; s++) {
      final double depth = size.height * (0.5 + 0.28 * s) * sag;
      final double y0 = 4 + s * 3;
      final Path path = Path()..moveTo(-8, y0);
      const int steps = 40;
      for (int i = 0; i <= steps; i++) {
        final double x = -8 + (size.width + 16) * i / steps;
        final double p = (x + 8) / (size.width + 16);
        // sin(pi * p) dips the string in the middle of the viewport.
        final double y = y0 + depth * math.sin(math.pi * p);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, line);

      final int bulbs = 13 + s * 4;
      for (int i = 0; i < bulbs; i++) {
        final double p = (i + 0.5) / bulbs;
        final double x = -8 + (size.width + 16) * p;
        final double y = y0 + depth * math.sin(math.pi * p);
        final double phase = (t + (i * 0.137) + s * 0.31) % 1;
        _paintBulb(
          canvas,
          Offset(x, y),
          0.55 + 0.45 * math.sin(phase * math.pi * 2),
          glow,
        );
      }
    }
  }

  /// The toran over the banner: a scalloped wire with a lamp hanging from each
  /// dip.
  void _paintToran(Canvas canvas, Size size, double t, Paint glow) {
    final Paint line = Paint()
      ..color = lineColor.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final double base = size.height * 0.18;
    final double amp = size.height * 0.2;
    final double period = math.max(size.width / math.max(bulbCount, 1), 1.0);

    final Path wire = Path();
    for (double x = -period; x <= size.width + period; x += 1.5) {
      final double y = base + amp * math.sin(x / period * math.pi * 2);
      if (x <= -period + 1.5) {
        wire.moveTo(x, y);
      } else {
        wire.lineTo(x, y);
      }
    }
    canvas.drawPath(wire, line);

    for (int i = 0; i < bulbCount; i++) {
      final double x = period * (i + 0.5);
      final double y = base + amp * math.sin(x / period * math.pi * 2) + size.height * 0.1;
      // A hairline thread from the wire down to the lamp.
      canvas.drawLine(
        Offset(x, y - size.height * 0.1),
        Offset(x, y - 2),
        line,
      );
      final double phase = (t + i * 0.191) % 1;
      _paintBulb(
        canvas,
        Offset(x, y + 1.5),
        0.6 + 0.4 * math.sin(phase * math.pi * 2),
        glow,
        scale: 1.15,
      );
    }
  }

  void _paintBulb(
    Canvas canvas,
    Offset center,
    double twinkle,
    Paint glow, {
    double scale = 1,
  }) {
    final double glowRadius =
        (11 * scale * (0.72 + 0.42 * twinkle) * intensity.clamp(0.2, 1.4))
            .clamp(3.0, 44.0)
            .toDouble();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(glowRadius, glowRadius);
    canvas.drawCircle(Offset.zero, 1, glow);
    canvas.restore();

    // The lamp itself: a small rounded lozenge with a bright core.
    final Paint lamp = Paint()
      ..color = Color.lerp(color, Colors.white, 0.35)!
          .withAlpha((190 + 60 * twinkle).round().clamp(0, 255).toInt());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 3.6 * scale, height: 4.6 * scale),
        Radius.circular(1.4 * scale),
      ),
      lamp,
    );
  }

  @override
  bool shouldRepaint(_FairyLightsPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.color != color ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.strings != strings ||
      oldDelegate.bulbCount != bulbCount ||
      oldDelegate.intensity != intensity;
}

/// The patterned backdrop of the festival banner: a faint diamond lattice plus
/// a pink-and-gold mandala diya motif mirrored on both edges.
class FestiveBackdrop extends StatelessWidget {
  const FestiveBackdrop({
    super.key,
    required this.palette,
    this.showMotifs = true,
  });

  final FestivePalette palette;
  final bool showMotifs;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BackdropPainter(
          lattice: Colors.white.withAlpha(10),
          latticeDeep: Colors.black.withAlpha(16),
          motifPink: palette.pink,
          motifGold: palette.goldDeep,
          motifGlow: palette.gold,
          showMotifs: showMotifs,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.lattice,
    required this.latticeDeep,
    required this.motifPink,
    required this.motifGold,
    required this.motifGlow,
    required this.showMotifs,
  });

  final Color lattice;
  final Color latticeDeep;
  final Color motifPink;
  final Color motifGold;
  final Color motifGlow;
  final bool showMotifs;

  @override
  void paint(Canvas canvas, Size size) {
    _paintLattice(canvas, size);
    if (showMotifs) {
      final double unit = (size.width / 360).clamp(0.62, 1.4).toDouble();
      _paintMotif(canvas, Offset(-6 * unit, size.height * 0.30), 0.52 * unit, mirror: false);
      _paintMotif(canvas, Offset(size.width + 6 * unit, size.height * 0.30), 0.52 * unit,
          mirror: true);
    }
  }

  /// Rows of soft rotated squares, alternating light and shadow, so the banner
  /// is never a flat fill.
  void _paintLattice(Canvas canvas, Size size) {
    const double period = 46;
    final Paint soft = Paint()..color = lattice;
    final Paint deep = Paint()..color = latticeDeep;
    int row = 0;
    for (double y = -period; y < size.height + period; y += period * 0.62) {
      final double offset = row.isEven ? 0 : period / 2;
      for (double x = -period + offset; x < size.width + period; x += period) {
        final double s = period * 0.2;
        final Path diamond = Path()
          ..moveTo(x, y - s)
          ..lineTo(x + s, y)
          ..lineTo(x, y + s)
          ..lineTo(x - s, y)
          ..close();
        canvas.drawPath(diamond, row.isEven ? soft : deep);
      }
      row++;
    }
  }

  /// A chain of small squares forming a diamond, with a lotus diya inside —
  /// the motif that flanks the "Diwali" wordmark.
  void _paintMotif(Canvas canvas, Offset center, double scale, {required bool mirror}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(mirror ? -scale : scale, scale);

    final Paint chain = Paint()
      ..color = motifPink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final Paint chainFill = Paint()..color = motifPink;

    // Outer diamond of stacked squares.
    const double rx = 46;
    const double ry = 58;
    for (int edge = 0; edge < 4; edge++) {
      for (int i = 1; i < 9; i++) {
        final double t = i / 9;
        final Offset p = switch (edge) {
          0 => Offset(-rx + 2 * rx * t, -ry + 2 * ry * t),
          1 => Offset(rx - 2 * rx * t, ry - 2 * ry * t),
          2 => Offset(rx - 2 * rx * t, -ry + 2 * ry * t),
          _ => Offset(-rx + 2 * rx * t, ry - 2 * ry * t),
        };
        canvas.drawRect(
          Rect.fromCenter(center: p, width: 3.2, height: 3.2),
          chain,
        );
      }
    }

    // Solid diamonds at the four points.
    for (final Offset p in <Offset>[
      const Offset(0, -ry),
      const Offset(0, ry),
      const Offset(-rx, 0),
      const Offset(rx, 0),
    ]) {
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 6.4, height: 6.4),
        chainFill,
      );
      canvas.restore();
    }

    // The lotus diya.
    final double glow = 26;
    canvas.drawCircle(
      const Offset(0, -4),
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[motifGlow.withAlpha(90), motifGlow.withAlpha(0)],
        ).createShader(
          Rect.fromCircle(center: const Offset(0, -4), radius: glow),
        ),
    );

    final Path bowl = Path()
      ..moveTo(-15, 12)
      ..quadraticBezierTo(-13, 30, 0, 30)
      ..quadraticBezierTo(13, 30, 15, 12)
      ..close();
    canvas.drawPath(bowl, Paint()..color = motifPink);

    final Paint rice = Paint()..color = motifGlow;
    for (int i = 0; i < 7; i++) {
      canvas.drawCircle(Offset(-10.5 + i * 3.5, 15.6), 1.05, rice);
    }

    // Flame: a diamond that reads as a lamp wick.
    canvas.save();
    canvas.translate(0, -2);
    canvas.rotate(math.pi / 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 15, height: 15),
        const Radius.circular(4),
      ),
      Paint()..color = motifGlow,
    );
    canvas.restore();
    canvas.drawCircle(const Offset(0, -2), 3.2, Paint()..color = const Color(0xCC8A5A12));
    canvas.restore();

    // A smaller echo ring to the right of the motif.
    canvas.save();
    canvas.translate(center.dx + (mirror ? -78 : 78) * scale, center.dy + 22 * scale);
    canvas.scale(mirror ? -scale : scale, scale);
    const double ex = 30;
    const double ey = 40;
    for (int edge = 0; edge < 4; edge++) {
      for (int i = 1; i < 7; i++) {
        final double t = i / 7;
        final Offset p = switch (edge) {
          0 => Offset(-ex + 2 * ex * t, -ey + 2 * ey * t),
          1 => Offset(ex - 2 * ex * t, ey - 2 * ey * t),
          2 => Offset(ex - 2 * ex * t, -ey + 2 * ey * t),
          _ => Offset(-ex + 2 * ex * t, ey - 2 * ey * t),
        };
        canvas.drawRect(
          Rect.fromCenter(center: p, width: 2.6, height: 2.6),
          Paint()
            ..color = motifPink.withAlpha(200)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
    canvas.save();
    canvas.translate(-ex, 0);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 5.4, height: 5.4),
      Paint()..color = motifPink,
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.motifPink != motifPink ||
      oldDelegate.motifGold != motifGold ||
      oldDelegate.showMotifs != showMotifs;
}

/// The row of white diamonds that closes the festival banner — the design's
/// transition into the light content section.
class DiamondDivider extends StatelessWidget {
  const DiamondDivider({
    super.key,
    this.color = Colors.white,
    this.height = 12,
    this.period = 12.5,
    this.size = 6.4,
  });

  final Color color;
  final double height;
  final double period;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Decorative divider',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _DiamondDividerPainter(
              color: color,
              height: height,
              period: period,
              diamond: size,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiamondDividerPainter extends CustomPainter {
  const _DiamondDividerPainter({
    required this.color,
    required this.height,
    required this.period,
    required this.diamond,
  });

  final Color color;
  final double height;
  final double period;
  final double diamond;

  @override
  void paint(Canvas canvas, Size size) {
    // saveLayer + clear punches the holes so the divider works over the
    // banner's gradient, not just over a flat colour.
    canvas.saveLayer(Offset.zero & size, Paint());
    final Paint fill = Paint()..color = color;
    final double cy = size.height / 2;
    for (double x = period / 2; x < size.width + period; x += period) {
      canvas.save();
      canvas.translate(x, cy);
      canvas.rotate(math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: diamond, height: diamond),
          Radius.circular(diamond * 0.16),
        ),
        fill,
      );
      canvas.restore();
    }
    final Paint hole = Paint()..blendMode = BlendMode.clear;
    for (double x = period / 2; x < size.width + period; x += period) {
      canvas.save();
      canvas.translate(x, cy);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: diamond * 0.34, height: diamond * 0.34),
        hole,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DiamondDividerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.height != height ||
      oldDelegate.period != period ||
      oldDelegate.diamond != diamond;
}

/// The arch (pointed top and bottom) silhouette of the banner tiles.
class ArchTileClipper extends CustomClipper<Path> {
  const ArchTileClipper({
    this.topApex = 0.105,
    this.bottomApex = 0.09,
    this.corner = 0.085,
  });

  /// How far the top point rises, as a fraction of the tile height.
  final double topApex;

  /// How far the bottom point drops, as a fraction of the tile height.
  final double bottomApex;

  /// Corner rounding as a fraction of the tile width.
  final double corner;

  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double apexTop = h * topApex;
    final double apexBottom = h * bottomApex;
    final double c = math.min(w * corner, math.min(apexTop, apexBottom) * 1.4);

    final Path p = Path()
      ..moveTo(w * 0.5, 0)
      // Right shoulder of the roof.
      ..quadraticBezierTo(w * 0.5 + c * 0.7, apexTop * 0.55, w * 0.5 + c, apexTop)
      ..lineTo(w - c, apexTop)
      ..quadraticBezierTo(w, apexTop, w, apexTop + c)
      // Right wall.
      ..lineTo(w, h - apexBottom - c)
      ..quadraticBezierTo(w, h - apexBottom, w - c, h - apexBottom)
      // Bottom point.
      ..quadraticBezierTo(w * 0.5 + c * 0.9, h - apexBottom * 0.45, w * 0.5, h)
      ..quadraticBezierTo(w * 0.5 - c * 0.9, h - apexBottom * 0.45, c, h - apexBottom)
      ..quadraticBezierTo(0, h - apexBottom, 0, h - apexBottom - c)
      // Left wall.
      ..lineTo(0, apexTop + c)
      ..quadraticBezierTo(0, apexTop, c, apexTop)
      ..lineTo(w * 0.5 - c, apexTop)
      ..quadraticBezierTo(w * 0.5 - c * 0.7, apexTop * 0.55, w * 0.5, 0)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(ArchTileClipper oldClipper) =>
      oldClipper.topApex != topApex ||
      oldClipper.bottomApex != bottomApex ||
      oldClipper.corner != corner;
}

/// Strokes the arch outline in gold, following the same path as the clip.
class ArchTileBorderPainter extends CustomPainter {
  const ArchTileBorderPainter({
    required this.color,
    this.width = 1.4,
    this.topApex = 0.105,
    this.bottomApex = 0.09,
    this.corner = 0.085,
  });

  final Color color;
  final double width;
  final double topApex;
  final double bottomApex;
  final double corner;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = ArchTileClipper(
      topApex: topApex,
      bottomApex: bottomApex,
      corner: corner,
    ).getClip(size);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(ArchTileBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.width != width ||
      oldDelegate.topApex != topApex ||
      oldDelegate.bottomApex != bottomApex ||
      oldDelegate.corner != corner;
}

/// A soft four-point sparkle used as an accent around the wordmark and buttons.
class Sparkle extends StatelessWidget {
  const Sparkle({
    super.key,
    required this.size,
    required this.color,
    this.pulse = true,
  });

  final double size;
  final Color color;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final Widget star = CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
    if (!pulse || FestiveMotion.reduced(context)) {
      return ExcludeSemantics(child: star);
    }
    return _PulsingSparkle(size: size, color: color);
  }
}

class _PulsingSparkle extends StatefulWidget {
  const _PulsingSparkle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_PulsingSparkle> createState() => _PulsingSparkleState();
}

class _PulsingSparkleState extends State<_PulsingSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SparklePainter(color: widget.color),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.shortestSide / 2;
    final Offset c = size.center(Offset.zero);
    final Path p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.16, c.dy - r * 0.16, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.16, c.dy + r * 0.16, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.16, c.dy + r * 0.16, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.16, c.dy - r * 0.16, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.color != color;
}
