import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home's header after dark.
class NightSky {
  static const _prefKey = 'theme_night';

  /// What the person picked under Change Theme: night, day, or (null) whatever
  /// the clock says.
  static final ValueNotifier<bool?> forced = ValueNotifier<bool?>(null);

  /// Whether the header is dressed for night right now.
  static bool get active => forced.value ?? isNight();

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_prefKey)) forced.value = prefs.getBool(_prefKey);
    } catch (_) {
      // Best-effort: a prefs failure just falls back to the clock.
    }
  }

  static Future<void> setForced(bool night) async {
    forced.value = night;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, night);
    } catch (_) {
      // Best-effort: the choice above is already live for this session;
      // losing the saved copy only means the clock decides next launch.
    }
  }

  /// Night runs from 10 pm to 6 am, by the phone's clock.
  static bool isNight([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    return hour >= 22 || hour < 6;
  }
}

/// A night sky that looks like one: stars that shimmer faintly, layered clouds
/// drifting slowly and catching the moonlight, a moon with a halo, and — only
/// rarely — a meteor. It loops seamlessly, once every 96 seconds.
class NightSkyAnimation extends StatefulWidget {
  const NightSkyAnimation({super.key});

  @override
  State<NightSkyAnimation> createState() => _NightSkyAnimationState();
}

class _NightSkyAnimationState extends State<NightSkyAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NightSkyPainter.loop,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: NightSkyPainter(_controller)),
    );
  }
}

class NightSkyPainter extends CustomPainter {
  static const loop = Duration(seconds: 96);

  final Animation<double> progress;

  NightSkyPainter(this.progress) : super(repaint: progress);

  static const _moonLight = Color(0xFFFFF1CC);

  // The meteors in one loop: about one every 45 seconds, unevenly. Each is
  // (when in the loop, where it starts as a fraction of the width and height,
  // which way it heads). A meteor takes under a second.
  static const _meteors = [
    (at: 0.23, x: 0.80, y: 0.07, dir: -1.0),
    (at: 0.71, x: 0.30, y: 0.11, dir: 1.0),
  ];
  static const _meteorTime = 0.0085;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = progress.value;
    final moon = Offset(w * 0.66, h * 0.36);

    _stars(canvas, w, h, t);
    _moon(canvas, moon, t);
    // Far clouds first, nearest last; the far ones are fainter and slower.
    _clouds(canvas, w, h, t, seed: 11, y: 0.20, trips: 1, alpha: 0.075);
    _clouds(canvas, w, h, t, seed: 23, y: 0.52, trips: 2, alpha: 0.10);
    _clouds(canvas, w, h, t, seed: 37, y: 0.36, trips: 3, alpha: 0.13);
    for (final m in _meteors) {
      _meteor(canvas, w, h, t, m.at, m.x, m.y, m.dir);
    }
    _skyline(canvas, w, h);
  }

  /// A fixed (seeded) scatter of pin-pricks of different brightness and tint.
  /// Each shimmers a little, irregularly — two slow beats added together —
  /// and never blinks out.
  void _stars(Canvas canvas, double w, double h, double t) {
    final rnd = math.Random(7);
    const tints = [
      Color(0xFFFFFFFF),
      Color(0xFFDCE6FF),
      Color(0xFFFFF0DC),
    ];
    for (var i = 0; i < 46; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h * 0.74;
      final bright = math.pow(rnd.nextDouble(), 2.4).toDouble(); // few bright
      final tint = tints[rnd.nextInt(tints.length)];
      final a = rnd.nextDouble(), b = rnd.nextDouble();
      // Whole cycles per loop keep the loop seamless (about 3-8 s each).
      final c1 = 12 + rnd.nextInt(14), c2 = 20 + rnd.nextInt(20);
      final shimmer = 0.6 * math.sin(2 * math.pi * (t * c1 + a)) +
          0.4 * math.sin(2 * math.pi * (t * c2 + b));
      final level =
          (0.55 + 0.25 * shimmer).clamp(0.2, 1.0) * (0.55 + 0.45 * bright);
      final radius = 0.6 + 0.9 * bright;
      final at = Offset(x, y);
      if (bright > 0.35) {
        // A faint halo round the brighter ones.
        final halo = Rect.fromCircle(center: at, radius: radius * 5);
        canvas.drawCircle(
          at,
          radius * 5,
          Paint()
            ..shader = RadialGradient(
              colors: [
                tint.withValues(alpha: 0.22 * level),
                tint.withValues(alpha: 0),
              ],
            ).createShader(halo),
        );
      }
      canvas.drawCircle(
          at, radius, Paint()..color = tint.withValues(alpha: level));
    }
  }

  /// A bank of clouds: each a cluster of overlapping soft puffs, so the outline
  /// is lumpy rather than an oval. They are slate-blue, and warm to the colour
  /// of the moon where they pass near it. [trips] is how many times the bank
  /// crosses the sky per loop (a whole number, so the loop has no seam).
  void _clouds(
    Canvas canvas,
    double w,
    double h,
    double t, {
    required int seed,
    required double y,
    required int trips,
    required double alpha,
  }) {
    final rnd = math.Random(seed);
    const groups = 3;
    for (var g = 0; g < groups; g++) {
      final cw = w * (0.42 + rnd.nextDouble() * 0.3);
      final phase = (g / groups + rnd.nextDouble() * 0.15);
      final travel = w + cw;
      final cx = ((phase + t * trips) % 1.0) * travel - cw / 2;
      final baseY = h * (y + (rnd.nextDouble() - 0.5) * 0.16);
      final puffs = 9 + rnd.nextInt(4);
      for (var p = 0; p < puffs; p++) {
        final u = (p + rnd.nextDouble() * 0.6) / puffs; // along the cloud
        final belly = math.sin(math.pi * u); // taller in the middle
        final px = cx + (u - 0.5) * cw;
        final pr = h * (0.05 + 0.09 * belly * (0.6 + rnd.nextDouble() * 0.6));
        final py = baseY + (rnd.nextDouble() - 0.55) * pr * 0.9;
        final centre = Offset(px, py);
        // Warmer near the moon.
        final near =
            (1 - (centre - Offset(w * 0.66, h * 0.36)).distance / (w * 0.42))
                .clamp(0.0, 1.0);
        final colour =
            Color.lerp(const Color(0xFFA9B4CE), _moonLight, near * 0.7)!;
        final rect = Rect.fromCenter(
          center: centre,
          width: pr * 3.4,
          height: pr * 1.9,
        );
        canvas.drawOval(
          rect,
          Paint()
            ..shader = RadialGradient(
              colors: [
                colour.withValues(alpha: alpha * (0.7 + 0.5 * near)),
                colour.withValues(alpha: 0),
              ],
            ).createShader(rect),
        );
      }
    }
  }

  /// A nearly full moon: warm shaded disc, a few craters and maria, and a
  /// halo that breathes very slowly.
  void _moon(Canvas canvas, Offset c, double t) {
    const r = 13.0;
    final breath = 0.5 + 0.5 * math.sin(2 * math.pi * t * 12); // ~8 s a breath

    final halo = Rect.fromCircle(center: c, radius: 46);
    canvas.drawCircle(
      c,
      46,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _moonLight.withValues(alpha: 0.20 + 0.06 * breath),
            _moonLight.withValues(alpha: 0.06),
            _moonLight.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 1],
        ).createShader(halo),
    );

    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.35),
          radius: 1.05,
          colors: [Color(0xFFFFFAE8), Color(0xFFF1E4B8), Color(0xFFD9C994)],
          stops: [0, 0.6, 1],
        ).createShader(disc),
    );

    // Maria and craters, faint, clipped to the disc.
    canvas.save();
    canvas.clipPath(Path()..addOval(disc));
    final mark = Paint()
      ..color = const Color(0xFFB9A874).withValues(alpha: 0.38);
    canvas.drawCircle(c + const Offset(-3.5, -2.5), 4.6, mark);
    canvas.drawCircle(c + const Offset(3.8, 1.5), 3.6, mark);
    canvas.drawCircle(c + const Offset(-1.5, 6.5), 2.3, mark);
    final crater = Paint()
      ..color = const Color(0xFFA89660).withValues(alpha: 0.32);
    canvas.drawCircle(c + const Offset(5.5, -5), 1.6, crater);
    canvas.drawCircle(c + const Offset(-7, 3.5), 1.4, crater);
    canvas.drawCircle(c + const Offset(0.5, -8), 1.1, crater);
    // A soft shadow on the lower right gives it roundness.
    canvas.drawCircle(
      c + const Offset(7, 6),
      r,
      Paint()..color = const Color(0xFF151B2B).withValues(alpha: 0.22),
    );
    canvas.restore();
  }

  /// A meteor: a thin bright streak with a long fading tail, crossing the sky
  /// at a shallow angle in well under a second.
  void _meteor(
    Canvas canvas,
    double w,
    double h,
    double t,
    double at,
    double fx,
    double fy,
    double dir,
  ) {
    final p = ((t - at) % 1.0) / _meteorTime;
    if (p < 0 || p > 1) return;
    final start = Offset(w * fx, h * fy);
    final travel = Offset(dir * w * 0.34, h * 0.17);
    final head = start + travel * p;
    final tail = head - travel * 0.5;
    // Fades in fast and out slowly, as a burning meteor does.
    final fade = math.pow(math.sin(math.pi * math.pow(p, 0.7)), 1.2).toDouble();
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment(dir < 0 ? 1 : -1, -1),
          end: Alignment(dir < 0 ? -1 : 1, 1),
          colors: [
            Colors.white.withValues(alpha: 0),
            const Color(0xFFEAF1FF).withValues(alpha: 0.9 * fade),
          ],
        ).createShader(Rect.fromPoints(tail, head).inflate(1)),
    );
    canvas.drawCircle(
      head,
      1.1,
      Paint()..color = Colors.white.withValues(alpha: fade),
    );
  }

  /// Rooftops along the bottom, a few windows lit.
  void _skyline(Canvas canvas, double w, double h) {
    final building = Paint()
      ..color = const Color(0xFF0F1420).withValues(alpha: 0.55);
    final window = Paint()
      ..color = const Color(0xFFFFD66B).withValues(alpha: 0.55);
    final sky = math.Random(3);
    var x = w * 0.42;
    while (x < w) {
      final bw = 16 + sky.nextDouble() * 22;
      final bh = 12 + sky.nextDouble() * 30;
      canvas.drawRect(Rect.fromLTWH(x, h - bh, bw, bh), building);
      for (var wy = h - bh + 5; wy < h - 4; wy += 8) {
        for (var wx = x + 4; wx < x + bw - 4; wx += 7) {
          if (sky.nextDouble() > 0.65) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, 2.4, 3), window);
          }
        }
      }
      x += bw + 2;
    }
  }

  @override
  bool shouldRepaint(NightSkyPainter oldDelegate) => false;
}
