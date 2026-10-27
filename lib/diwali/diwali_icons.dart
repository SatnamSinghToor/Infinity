import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'diwali_data.dart';
import 'diwali_painters.dart';

/// Small hand-drawn line icons. Material's default set is close but not
/// identical to the reference; drawing the handful that sit in the header and
/// tab bar keeps those two high-visibility rows faithful.

/// One uniform stroke style shared by every glyph below.
Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..style = PaintingStyle.stroke;

/// The six circular tab-strip glyphs.
class DiwaliTabGlyph extends StatelessWidget {
  const DiwaliTabGlyph({
    super.key,
    required this.icon,
    this.color = const Color(0xFF790131),
    this.size = 30,
  });

  final DiwaliTabIcon icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _DiwaliTabGlyphPainter(icon, color)),
      );
}

class _DiwaliTabGlyphPainter extends CustomPainter {
  const _DiwaliTabGlyphPainter(this.icon, this.color);

  final DiwaliTabIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = _stroke(color, w * 0.058);

    switch (icon) {
      case DiwaliTabIcon.all:
        // Four rounded tiles — the "All" grid.
        for (final dx in [0.16, 0.56]) {
          for (final dy in [0.16, 0.56]) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(w * dx, h * dy, w * 0.28, h * 0.28),
                Radius.circular(w * 0.055),
              ),
              p,
            );
          }
        }
        break;

      case DiwaliTabIcon.diya:
        // A bowl and its flame.
        final bowl = Path()
          ..moveTo(w * 0.12, h * 0.54)
          ..quadraticBezierTo(w * 0.5, h * 0.98, w * 0.88, h * 0.54)
          ..close();
        canvas.drawPath(bowl, p);
        canvas.drawLine(
          Offset(w * 0.10, h * 0.54),
          Offset(w * 0.90, h * 0.54),
          p,
        );
        final flame = Path()
          ..moveTo(w * 0.5, h * 0.08)
          ..cubicTo(w * 0.66, h * 0.24, w * 0.66, h * 0.40, w * 0.5, h * 0.46)
          ..cubicTo(w * 0.34, h * 0.40, w * 0.34, h * 0.24, w * 0.5, h * 0.08)
          ..close();
        canvas.drawPath(flame, p);
        break;

      case DiwaliTabIcon.party:
        // Party popper with confetti.
        final cone = Path()
          ..moveTo(w * 0.16, h * 0.84)
          ..lineTo(w * 0.62, h * 0.26)
          ..lineTo(w * 0.76, h * 0.40)
          ..lineTo(w * 0.30, h * 0.90)
          ..close();
        canvas.drawPath(cone, p);
        for (final o in <Offset>[
          Offset(w * 0.72, h * 0.14),
          Offset(w * 0.88, h * 0.26),
          Offset(w * 0.60, h * 0.10),
          Offset(w * 0.90, h * 0.50),
        ]) {
          canvas.drawCircle(o, w * 0.03, p..style = PaintingStyle.fill);
        }
        canvas.drawLine(
          Offset(w * 0.36, h * 0.58),
          Offset(w * 0.50, h * 0.72),
          _stroke(color, w * 0.05),
        );
        break;

      case DiwaliTabIcon.electronics:
        // A TV / monitor on a stand.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14, h * 0.18, w * 0.72, h * 0.52),
            Radius.circular(w * 0.05),
          ),
          p,
        );
        canvas.drawLine(
          Offset(w * 0.5, h * 0.70),
          Offset(w * 0.5, h * 0.84),
          p,
        );
        canvas.drawLine(
          Offset(w * 0.32, h * 0.86),
          Offset(w * 0.68, h * 0.86),
          p,
        );
        break;

      case DiwaliTabIcon.beauty:
        // Lipstick in its case.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.32, h * 0.42, w * 0.36, h * 0.46),
            Radius.circular(w * 0.03),
          ),
          p,
        );
        final tip = Path()
          ..moveTo(w * 0.32, h * 0.42)
          ..lineTo(w * 0.32, h * 0.22)
          ..quadraticBezierTo(w * 0.50, h * 0.04, w * 0.64, h * 0.20)
          ..lineTo(w * 0.68, h * 0.42)
          ..close();
        canvas.drawPath(tip, p);
        canvas.drawLine(
          Offset(w * 0.32, h * 0.62),
          Offset(w * 0.68, h * 0.62),
          p,
        );
        break;

      case DiwaliTabIcon.gift:
        // Gift box with ribbon and bow.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.16, h * 0.40, w * 0.68, h * 0.46),
            Radius.circular(w * 0.04),
          ),
          p,
        );
        canvas.drawLine(
          Offset(w * 0.12, h * 0.40),
          Offset(w * 0.88, h * 0.40),
          p,
        );
        canvas.drawLine(
          Offset(w * 0.5, h * 0.40),
          Offset(w * 0.5, h * 0.86),
          p,
        );
        for (final dx in [-0.13, 0.13]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(w * (0.5 + dx), h * 0.28),
              width: w * 0.20,
              height: h * 0.20,
            ),
            p,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DiwaliTabGlyphPainter old) =>
      old.icon != icon || old.color != color;
}

/// Icons in the persistent bottom navigation.
enum DiwaliNavIcon { home, categories, cart, profile }

class DiwaliNavGlyph extends StatelessWidget {
  const DiwaliNavGlyph({
    super.key,
    required this.icon,
    required this.color,
    this.size = 25,
    this.badge = 0,
  });

  final DiwaliNavIcon icon;
  final Color color;
  final double size;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(painter: _DiwaliNavGlyphPainter(icon, color)),
            ),
          ),
          if (badge > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFE23744),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiwaliNavGlyphPainter extends CustomPainter {
  const _DiwaliNavGlyphPainter(this.icon, this.color);

  final DiwaliNavIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = _stroke(color, w * 0.07);

    switch (icon) {
      case DiwaliNavIcon.home:
        final roof = Path()
          ..moveTo(w * 0.10, h * 0.46)
          ..lineTo(w * 0.50, h * 0.12)
          ..lineTo(w * 0.90, h * 0.46);
        canvas.drawPath(roof, p);
        final body = Path()
          ..moveTo(w * 0.18, h * 0.42)
          ..lineTo(w * 0.18, h * 0.88)
          ..lineTo(w * 0.82, h * 0.88)
          ..lineTo(w * 0.82, h * 0.42);
        canvas.drawPath(body, p);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.42, h * 0.60, w * 0.16, h * 0.28),
            Radius.circular(w * 0.015),
          ),
          p,
        );
        break;

      case DiwaliNavIcon.categories:
        for (final dx in [0.12, 0.56]) {
          for (final dy in [0.12, 0.56]) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(w * dx, h * dy, w * 0.32, h * 0.32),
                Radius.circular(w * 0.07),
              ),
              p,
            );
          }
        }
        break;

      case DiwaliNavIcon.cart:
        final bag = Path()
          ..moveTo(w * 0.16, h * 0.36)
          ..lineTo(w * 0.84, h * 0.36)
          ..lineTo(w * 0.78, h * 0.90)
          ..lineTo(w * 0.22, h * 0.90)
          ..close();
        canvas.drawPath(bag, p);
        final handle = Path()
          ..moveTo(w * 0.34, h * 0.36)
          ..quadraticBezierTo(w * 0.34, h * 0.12, w * 0.50, h * 0.12)
          ..quadraticBezierTo(w * 0.66, h * 0.12, w * 0.66, h * 0.36);
        canvas.drawPath(handle, p);
        break;

      case DiwaliNavIcon.profile:
        canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.16, p);
        final shoulders = Path()
          ..moveTo(w * 0.16, h * 0.88)
          ..quadraticBezierTo(w * 0.16, h * 0.56, w * 0.50, h * 0.56)
          ..quadraticBezierTo(w * 0.84, h * 0.56, w * 0.84, h * 0.88);
        canvas.drawPath(shoulders, p);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DiwaliNavGlyphPainter old) =>
      old.icon != icon || old.color != color;
}

/// Compact four-point star used around section headings and chips.
class DiwaliSparkle extends StatelessWidget {
  const DiwaliSparkle({
    super.key,
    this.color = const Color(0xFFA80B4B),
    this.size = 14,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: DiwaliSparklePainter(color: color)),
      );
}

/// A string of twinkling bulbs. [progress] is 0..1 from a looping controller.
class DiwaliFairyLights extends StatelessWidget {
  const DiwaliFairyLights({
    super.key,
    required this.progress,
    this.height = 44,
    this.flip = false,
    this.bulbs = 25,
  });

  final double progress;
  final double height;
  final bool flip;
  final int bulbs;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: DiwaliFairyLightsPainter(
            phase: progress,
            flip: flip,
            bulbs: bulbs,
          ),
        ),
      );
}

/// A diamond rule (optionally filled) with sparkle ends.
class DiwaliDiamondRule extends StatelessWidget {
  const DiwaliDiamondRule({
    super.key,
    this.color = const Color(0xFFA80B4B),
    this.filled = false,
    this.step = 16,
    this.height = 9,
    this.width = double.infinity,
  });

  final Color color;
  final bool filled;
  final double step;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: DiwaliDiamondRulePainter(
            color: color,
            filled: filled,
            step: step,
          ),
        ),
      );
}

/// Decorative lotus emblem.
class DiwaliLotus extends StatelessWidget {
  const DiwaliLotus({
    super.key,
    this.color = const Color(0xFFA80B4B),
    this.size = 22,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: DiwaliLotusPainter(color: color)),
      );
}

/// Satin ribbon illustration for the gifting banner.
class DiwaliBow extends StatelessWidget {
  const DiwaliBow({super.key, this.width = 82, this.height = 54});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: const CustomPaint(painter: DiwaliBowPainter()),
      );
}

/// A tiny diya used as an ornament inside price-drop banners.
class DiwaliDiyaMark extends StatelessWidget {
  const DiwaliDiyaMark({super.key, this.size = 34, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _DiyaMarkPainter(color)),
      );
}

class _DiyaMarkPainter extends CustomPainter {
  const _DiyaMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..color = color;
    final bowl = Path()
      ..moveTo(w * 0.06, h * 0.58)
      ..quadraticBezierTo(w * 0.5, h * 1.06, w * 0.94, h * 0.58)
      ..close();
    canvas.drawPath(bowl, p);
    final flame = Path()
      ..moveTo(w * 0.5, h * 0.02)
      ..cubicTo(w * 0.68, h * 0.24, w * 0.64, h * 0.40, w * 0.5, h * 0.48)
      ..cubicTo(w * 0.36, h * 0.40, w * 0.32, h * 0.24, w * 0.5, h * 0.02)
      ..close();
    canvas.drawPath(flame, p);
    for (final dx in [0.10, 0.30, 0.50, 0.70, 0.90]) {
      canvas.drawCircle(
        Offset(w * dx, h * 0.56),
        w * 0.035,
        Paint()..color = const Color(0xFFFFD166),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiyaMarkPainter old) => old.color != color;
}

/// A small circular arrow button (carousel next / brand scroll).
class DiwaliCircleButton extends StatelessWidget {
  const DiwaliCircleButton({
    super.key,
    required this.onTap,
    this.icon = Icons.arrow_forward_ios_rounded,
    this.size = 34,
    this.color = const Color(0xFF790131),
    this.background = Colors.white,
  });

  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return _DiwaliHoverButton(
      onTap: onTap,
      borderRadius: size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: size * 0.5, color: color),
      ),
    );
  }
}

/// Shared hover/lift wrapper. Kept here so the micro-interaction is
/// consistent between cards, rails and buttons.
class _DiwaliHoverButton extends StatefulWidget {
  const _DiwaliHoverButton({
    required this.onTap,
    required this.child,
    required this.borderRadius,
  });

  final VoidCallback onTap;
  final Widget child;
  final double borderRadius;

  @override
  State<_DiwaliHoverButton> createState() => _DiwaliHoverButtonState();
}

class _DiwaliHoverButtonState extends State<_DiwaliHoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.07 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A simple angle used by the "Explore" chevrons.
double get diwaliGoldenAngle => math.pi / 5;
