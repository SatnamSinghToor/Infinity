import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'pressable.dart';

/// The voice-search button that sits beside Home's search bar: a square just
/// like the bar (same white, outline and corner radius) with a waveform on it. The waveform rests as five black bars, then
/// every few seconds turns orange, dances like a live voice level and throws
/// off a couple of sparkles, before settling again.
class VoiceSearchButton extends StatefulWidget {
  final VoidCallback onTap;

  /// Same height as the search bar next to it.
  static const size = 46.0;

  /// The corner radius shared with the search bar, so the two match.
  static const radius = 14.0;

  /// The search bar's outline, reused here.
  static const borderColor = Color(0xFFE7E9F6);

  const VoiceSearchButton({super.key, required this.onTap});

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  )..repeat();

  bool _pressed = false;

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search by voice or photo',
      child: Pressable(
          child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            width: VoiceSearchButton.size,
            height: VoiceSearchButton.size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(VoiceSearchButton.radius),
              border:
                  Border.all(color: VoiceSearchButton.borderColor, width: 1.2),
            ),
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, _) => CustomPaint(
                painter: _WavePainter(_loop.value),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

class _WavePainter extends CustomPainter {
  /// Where we are in the loop, 0–1.
  final double t;

  const _WavePainter(this.t);

  // Resting heights of the five bars.
  static const _rest = [9.0, 15.0, 22.0, 21.0, 11.0];
  static const _barWidth = 2.5;
  static const _pitch = 4.8;

  /// 0 while resting, 1 while dancing, easing in and out at the edges.
  static double _activity(double t) {
    const start = 0.40, end = 0.88, ease = 0.06;
    if (t < start || t > end) return 0;
    if (t < start + ease) return Curves.easeOut.transform((t - start) / ease);
    if (t > end - ease) return Curves.easeIn.transform((end - t) / ease);
    return 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = _activity(t);
    final center = size.center(Offset.zero);
    final spin = t * 2 * math.pi * 6;

    for (var i = 0; i < _rest.length; i++) {
      // While dancing each bar swings between about a third and full height
      // on its own rhythm.
      final swing = 0.62 + 0.38 * math.sin(spin * (0.8 + i * 0.23) + i * 1.9);
      final height = _rest[i] * (1 - a) + (_rest[i] * 1.15 * swing + 2) * a;

      const rest = Color(0xFF1B1B1B);
      // Dark orange on the left through to light orange on the right.
      final orange = Color.lerp(
        const Color(0xFFA04000),
        AppConstants.primaryColor,
        i / (_rest.length - 1),
      )!;
      final paint = Paint()..color = Color.lerp(rest, orange, a)!;

      final dx = (i - (_rest.length - 1) / 2) * _pitch;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(dx, 0),
          width: _barWidth,
          height: height,
        ),
        const Radius.circular(_barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }

    if (a > 0) {
      // Two sparkles that twinkle while the bars dance.
      _sparkle(
        canvas,
        center + const Offset(14, -15),
        2.6,
        a * (0.5 + 0.5 * math.sin(spin * 0.5)),
      );
      _sparkle(
        canvas,
        center + const Offset(-14, 13),
        4.4,
        a * (0.5 + 0.5 * math.sin(spin * 0.5 + 2.4)),
      );
    }
  }

  /// A four-pointed star.
  void _sparkle(Canvas canvas, Offset at, double radius, double strength) {
    if (strength <= 0.02) return;
    final r = radius * (0.6 + 0.4 * strength);
    final inner = r * 0.28;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final rad = i.isEven ? r : inner;
      final p = at + Offset(math.cos(angle) * rad, math.sin(angle) * rad);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color =
            AppConstants.primaryColor.withOpacity(strength.clamp(0, 1)),
    );
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => oldDelegate.t != t;
}
