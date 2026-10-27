import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/constants.dart';
import '../../utils/tokens.dart';

/// Rounded, outlined field used on the login and sign-up screens — the same
/// corners and padding as the fields inside the app, so signing in does not
/// look like a different, bigger app.
InputDecoration authFieldDecoration({
  String? hint,
  Widget? prefix,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    hintText: hint,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: border(const Color(0xFFE4E4E4)),
    focusedBorder: border(AppConstants.primaryColor),
    border: border(const Color(0xFFE4E4E4)),
  );
}

/// White status bar with dark icons, for screens whose top is white.
const whiteStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.white,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

/// A small tricolour, drawn rather than an emoji so it shows on every phone:
/// saffron, white and green bands, with the navy Ashoka Chakra — a wheel of
/// 24 spokes — in the middle of the white band.
class IndiaFlag extends StatelessWidget {
  const IndiaFlag({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: const SizedBox(
        width: 26,
        height: 18,
        child: CustomPaint(painter: _IndiaFlagPainter()),
      ),
    );
  }
}

class _IndiaFlagPainter extends CustomPainter {
  const _IndiaFlagPainter();

  static const _saffron = Color(0xFFFF9933);
  static const _green = Color(0xFF138808);
  static const _navy = Color(0xFF000080);

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.height / 3;
    final fill = Paint()..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, band),
      fill..color = _saffron,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, band, size.width, band),
      fill..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, band * 2, size.width, band),
      fill..color = _green,
    );

    // The chakra is three quarters of the white band's height across.
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = band * 0.75 / 2;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = _navy
      ..isAntiAlias = true;
    canvas.drawCircle(centre, radius, line..strokeWidth = radius * 0.22);
    line.strokeWidth = radius * 0.1;
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      canvas.drawLine(
        centre,
        centre + Offset(math.cos(angle), math.sin(angle)) * radius,
        line,
      );
    }
    canvas.drawCircle(centre, radius * 0.2, fill..color = _navy);
  }

  @override
  bool shouldRepaint(_IndiaFlagPainter oldDelegate) => false;
}

/// The "flag +91" box beside a phone number field.
class PhoneCodeChip extends StatelessWidget {
  const PhoneCodeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // As tall as the field beside it.
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Row(
        children: [
          const IndiaFlag(),
          const SizedBox(width: 8),
          Text(
            '+91',
            maxLines: 1,
            style: GoogleFonts.poppins(
                fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
