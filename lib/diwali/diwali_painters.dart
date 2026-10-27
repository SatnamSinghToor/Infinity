import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Custom painters for the parts of the reference that are illustration
/// rather than photography: fairy lights, the diamond rules, the bow, the
/// lotus, the lattice, and the arch outlines. Vector drawing keeps every
/// ornament sharp on a 3x phone and a 4K monitor alike.

/// The doorway/arch silhouette used by hero tiles, editorial cards and
/// brand cards. Cubic curves give the same soft dome as the reference.
Path diwaliArchPath(Size size, {double bottomRadius = 12}) {
  final w = size.width;
  final h = size.height;
  final r = math.min(bottomRadius, w / 6);
  final dome = math.min(h * 0.34, w * 0.62);
  final path = Path()
    ..moveTo(0, h - r)
    ..lineTo(0, dome)
    ..cubicTo(0, dome * 0.28, w * 0.16, 0, w * 0.5, 0)
    ..cubicTo(w * 0.84, 0, w, dome * 0.28, w, dome)
    ..lineTo(w, h - r)
    ..quadraticBezierTo(w, h, w - r, h)
    ..lineTo(r, h)
    ..quadraticBezierTo(0, h, 0, h - r)
    ..close();
  return path;
}

class DiwaliArchClipper extends CustomClipper<Path> {
  const DiwaliArchClipper({this.bottomRadius = 12});

  final double bottomRadius;

  @override
  Path getClip(Size size) => diwaliArchPath(size, bottomRadius: bottomRadius);

  @override
  bool shouldReclip(covariant DiwaliArchClipper oldClipper) =>
      oldClipper.bottomRadius != bottomRadius;
}

/// Draws a shadow shaped exactly like the arch — a rectangular BoxShadow
/// would leak out of the domed corners.
class DiwaliArchShadowPainter extends CustomPainter {
  const DiwaliArchShadowPainter({
    this.color = const Color(0x33000000),
    this.elevation = 7,
  });

  final Color color;
  final double elevation;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(diwaliArchPath(size), color, elevation, false);
  }

  @override
  bool shouldRepaint(covariant DiwaliArchShadowPainter old) =>
      old.color != color || old.elevation != elevation;
}

/// The six-pointed diamond (kite) behind each "Diyas & Candles" icon.
class DiwaliDiamondClipper extends CustomClipper<Path> {
  const DiwaliDiamondClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.32)
      ..lineTo(w, h * 0.72)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.72)
      ..lineTo(0, h * 0.32)
      ..close();
  }

  @override
  bool shouldReclip(covariant DiwaliDiamondClipper oldClipper) => false;
}

/// A draped string of bulbs. [phase] comes from a repeating AnimationController
/// so the bulbs twinkle out of sync with each other.
class DiwaliFairyLightsPainter extends CustomPainter {
  const DiwaliFairyLightsPainter({
    required this.phase,
    this.flip = false,
    this.bulbs = 25,
  });

  final double phase;
  final bool flip;
  final int bulbs;

  double _curve(double t) =>
      0.10 + 0.42 * (0.5 - 0.5 * math.cos(6 * math.pi * t));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    if (flip) {
      canvas.translate(0, h);
      canvas.scale(1, -1);
    }

    final wire = Path();
    for (var i = 0; i <= 80; i++) {
      final t = i / 80;
      final x = w * t;
      final y = h * _curve(t);
      if (i == 0) {
        wire.moveTo(x, y);
      } else {
        wire.lineTo(x, y);
      }
    }
    canvas.drawPath(
      wire,
      Paint()
        ..color = const Color(0xCC4A2A13)
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke,
    );

    for (var j = 1; j <= bulbs; j++) {
      final t = j / (bulbs + 1);
      final x = w * t;
      final y = h * _curve(t);
      final twinkle = 0.55 +
          0.45 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi + j * 0.72));
      final stem = h * 0.15;
      final cy = y + stem;

      canvas.drawLine(
        Offset(x, y),
        Offset(x, cy - 2),
        Paint()
          ..color = const Color(0xFF4B2A12)
          ..strokeWidth = 1.1,
      );
      canvas.drawCircle(
        Offset(x, cy),
        6.2,
        Paint()
          ..color = const Color(0xFFFFC65C)
              .withAlpha((0.22 * twinkle * 255).round().clamp(0, 255).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(x, cy),
        3.0,
        Paint()..color = Color.lerp(const Color(0xFFB8752C),
            const Color(0xFFFFE6A2), twinkle)!,
      );
      canvas.drawCircle(
        Offset(x - 0.9, cy - 1.1),
        1.0,
        Paint()..color = const Color(0xE6FFF6D6),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DiwaliFairyLightsPainter old) =>
      old.phase != phase || old.flip != flip || old.bulbs != bulbs;
}

/// The faint diamond lattice printed into the dark hero.
class DiwaliLatticePainter extends CustomPainter {
  const DiwaliLatticePainter({this.spacing = 26, this.opacity = 0.09});

  final double spacing;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD696)
          .withAlpha((opacity * 255).round().clamp(0, 255).toInt())
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final step = spacing;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DiwaliLatticePainter old) =>
      old.spacing != spacing || old.opacity != opacity;
}

/// The repeated hollow-diamond rule between editorial sections.
class DiwaliDiamondRulePainter extends CustomPainter {
  const DiwaliDiamondRulePainter({
    this.color = const Color(0xFFA80B4B),
    this.filled = false,
    this.step = 16,
  });

  final Color color;
  final bool filled;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1;
    final cy = size.height / 2;
    final halfH = math.min(3.4, size.height * 0.36);
    final halfW = step * 0.38;
    for (var x = step / 2; x < size.width; x += step) {
      final path = Path()
        ..moveTo(x, cy - halfH)
        ..lineTo(x + halfW, cy)
        ..lineTo(x, cy + halfH)
        ..lineTo(x - halfW, cy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DiwaliDiamondRulePainter old) =>
      old.color != color || old.filled != filled || old.step != step;
}

/// The satin bow that crowns "Thoughtful Gifts for All".
class DiwaliBowPainter extends CustomPainter {
  const DiwaliBowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final bowGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFDC86B0), Color(0xFF9C2A62)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final left = Path()
      ..moveTo(cx - w * 0.02, h * 0.5)
      ..cubicTo(w * 0.30, h * 0.06, w * 0.05, h * 0.02, 0, h * 0.28)
      ..cubicTo(-w * 0.05, h * 0.55, w * 0.24, h * 0.78,
          cx - w * 0.02, h * 0.5)
      ..close();
    final right = Path()
      ..moveTo(cx + w * 0.02, h * 0.5)
      ..cubicTo(w * 0.70, h * 0.06, w * 0.95, h * 0.02, w, h * 0.28)
      ..cubicTo(w * 1.05, h * 0.55, w * 0.76, h * 0.78,
          cx + w * 0.02, h * 0.5)
      ..close();
    canvas.drawPath(left, Paint()..shader = bowGradient);
    canvas.drawPath(right, Paint()..shader = bowGradient);

    final tails = Path()
      ..moveTo(cx - w * 0.09, h * 0.48)
      ..lineTo(w * 0.20, h * 0.98)
      ..lineTo(w * 0.40, h * 0.98)
      ..lineTo(cx, h * 0.55)
      ..lineTo(w * 0.60, h * 0.98)
      ..lineTo(w * 0.80, h * 0.98)
      ..lineTo(cx + w * 0.09, h * 0.48)
      ..close();
    canvas.drawPath(tails, Paint()..color = const Color(0xFFB84C7F));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.5),
        width: w * 0.14,
        height: h * 0.26,
      ),
      Paint()..color = const Color(0xFFE7A8C4),
    );
    canvas.drawCircle(
      Offset(cx, h * 0.5),
      h * 0.045,
      Paint()..color = const Color(0xFFFFF0DA),
    );
  }

  @override
  bool shouldRepaint(covariant DiwaliBowPainter old) => false;
}

/// A stylised lotus used beside "Festive Calendar".
class DiwaliLotusPainter extends CustomPainter {
  const DiwaliLotusPainter({this.color = const Color(0xFFA80B4B)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;
    final centre = Path()
      ..moveTo(w * 0.5, h * 0.10)
      ..cubicTo(w * 0.28, h * 0.34, w * 0.30, h * 0.66, w * 0.5, h * 0.84)
      ..cubicTo(w * 0.70, h * 0.66, w * 0.72, h * 0.34, w * 0.5, h * 0.10)
      ..close();
    final left = Path()
      ..moveTo(w * 0.44, h * 0.32)
      ..cubicTo(w * 0.12, h * 0.32, w * 0.02, h * 0.62, w * 0.10, h * 0.78)
      ..cubicTo(w * 0.22, h * 0.86, w * 0.38, h * 0.68, w * 0.46, h * 0.52)
      ..close();
    final right = Path()
      ..moveTo(w * 0.56, h * 0.32)
      ..cubicTo(w * 0.88, h * 0.32, w * 0.98, h * 0.62, w * 0.90, h * 0.78)
      ..cubicTo(w * 0.78, h * 0.86, w * 0.62, h * 0.68, w * 0.54, h * 0.52)
      ..close();
    canvas.drawPath(left, paint..color = color.withAlpha(158));
    canvas.drawPath(right, paint..color = color.withAlpha(158));
    canvas.drawPath(centre, paint..color = color);
    final base = Path()
      ..moveTo(w * 0.06, h * 0.84)
      ..cubicTo(w * 0.30, h * 0.98, w * 0.70, h * 0.98, w * 0.94, h * 0.84)
      ..cubicTo(w * 0.72, h * 1.02, w * 0.28, h * 1.02, w * 0.06, h * 0.84)
      ..close();
    canvas.drawPath(base, paint..color = color.withAlpha(115));
  }

  @override
  bool shouldRepaint(covariant DiwaliLotusPainter old) => old.color != color;
}

/// The four-pointed sparkle flanking every editorial heading.
class DiwaliSparklePainter extends CustomPainter {
  const DiwaliSparklePainter({this.color = const Color(0xFFA80B4B)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.62, h * 0.38)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.62, h * 0.62)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.38, h * 0.62)
      ..lineTo(0, h * 0.5)
      ..lineTo(w * 0.38, h * 0.38)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    final dot = Paint()..color = color;
    for (final p in <Offset>[
      Offset(w * 0.12, h * 0.12),
      Offset(w * 0.88, h * 0.12),
      Offset(w * 0.12, h * 0.88),
      Offset(w * 0.88, h * 0.88),
    ]) {
      canvas.drawRect(
        Rect.fromCenter(center: p, width: w * 0.11, height: h * 0.11),
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DiwaliSparklePainter old) => old.color != color;
}
