import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Whether a festival is a Ganesh one, and so gets [GaneshFaceArt].
bool isGaneshFestival(String? title) =>
    (title ?? '').toLowerCase().contains('ganesh');

/// Lord Ganesha's face, drawn as the border of a heading: a golden ear at
/// each side, an eye either side of the small line above the title, and a
/// tilak on top. The ears sway, the eyes blink now and then and the tilak
/// glows.
///
/// It is drawn on a 1080 x 300 canvas scaled to the width it is given; put
/// the heading's text over its middle.
class GaneshFaceArt extends StatefulWidget {
  const GaneshFaceArt({super.key});

  @override
  State<GaneshFaceArt> createState() => _GaneshFaceArtState();
}

class _GaneshFaceArtState extends State<GaneshFaceArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AspectRatio(
        aspectRatio: 1080 / 300,
        child: CustomPaint(painter: _GaneshPainter(_controller)),
      ),
    );
  }
}

class _GaneshPainter extends CustomPainter {
  final Animation<double> t;

  _GaneshPainter(this.t) : super(repaint: t);

  static const _gold = Color(0xFFFFB13B);
  static const _earLight = Color(0xFFFFDFA0);
  static const _earDeep = Color(0xFFFFB84D);

  /// The left ear in the 1080 x 300 canvas: a rounded leaf that points down
  /// and in towards the face.
  static Path _ear() {
    return Path()
      ..moveTo(14, 26)
      ..cubicTo(90, 14, 190, 52, 218, 172)
      ..cubicTo(196, 214, 96, 214, 54, 160)
      ..cubicTo(22, 118, 6, 66, 14, 26)
      ..close();
  }

  void _paintEar(Canvas canvas, double sway) {
    // Pivot near where the ear meets the head.
    const pivot = Offset(200, 150);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(sway);
    canvas.translate(-pivot.dx, -pivot.dy);

    final outer = _ear();
    canvas.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_earDeep, _earLight],
        ).createShader(const Rect.fromLTWH(0, 10, 230, 210)),
    );
    // The inner ear: a smaller copy, a little deeper in colour.
    canvas.save();
    canvas.translate(38, 30);
    canvas.scale(0.78);
    canvas.drawPath(
      outer,
      Paint()..color = _earDeep.withOpacity(0.45),
    );
    canvas.restore();
    canvas.restore();
  }

  void _paintEye(Canvas canvas, double open) {
    const iris = Offset(325, 76);
    canvas.save();
    // Blinking squashes the eye towards its lower lid.
    canvas.translate(iris.dx, iris.dy);
    canvas.scale(1, open);
    canvas.translate(-iris.dx, -iris.dy);

    final line = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;
    // The brow sweeping in from the side, and the lower lid.
    canvas.drawPath(
      Path()
        ..moveTo(212, 38)
        ..cubicTo(262, 34, 302, 46, 322, 64),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(296, 88)
        ..quadraticBezierTo(346, 96, 380, 122),
      line..strokeWidth = 7,
    );
    canvas.drawCircle(iris, 13, Paint()..color = _gold);
    canvas.restore();
  }

  void _paintTilak(Canvas canvas, double glow) {
    const dot = Offset(543, 26);
    canvas.drawCircle(
      dot,
      16,
      Paint()
        ..color = _gold.withOpacity(0.18 + 0.22 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(dot, 8, Paint()..color = _gold);
    final line = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    canvas.drawPath(
      Path()
        ..moveTo(512, 46)
        ..quadraticBezierTo(543, 60, 574, 46),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(500, 60)
        ..quadraticBezierTo(543, 78, 586, 60),
      line,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 1080;
    canvas.save();
    canvas.scale(scale);

    final phase = t.value;
    final sway = 0.05 * math.sin(phase * 2 * math.pi * 2.5);
    // A blink in the last part of every cycle.
    final blink = phase > 0.9 && phase < 0.97
        ? 1 - 0.85 * math.sin((phase - 0.9) / 0.07 * math.pi)
        : 1.0;
    final glow = (math.sin(phase * 2 * math.pi * 3) + 1) / 2;

    // Left ear, eye; then the same mirrored for the right.
    for (final mirrored in [false, true]) {
      canvas.save();
      if (mirrored) {
        canvas.translate(1080, 0);
        canvas.scale(-1, 1);
      }
      _paintEar(canvas, sway);
      _paintEye(canvas, blink);
      canvas.restore();
    }
    _paintTilak(canvas, glow);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GaneshPainter old) => false;
}
