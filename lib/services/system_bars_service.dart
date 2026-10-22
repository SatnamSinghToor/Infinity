import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The phone's own three-key strip (recents, home, back).
///
/// Flutter asks the window for edge-to-edge, and a see-through bar makes
/// the phone paint white glyphs over whatever is behind it. This keeps the
/// strip white with dark glyphs on it, and reports the strip's height so
/// the app's own bottom bars can stay clear of the keys.
class SystemBars {
  SystemBars._();

  static const MethodChannel _channel = MethodChannel('duggu/system_bars');

  static DateTime _lastCall = DateTime.fromMillisecondsSinceEpoch(0);

  /// The strip's height in logical pixels, as the window reports it.
  /// Flutter's own viewPadding cannot be trusted here: when the window has
  /// already taken the strip, the padding reads zero while the keys are
  /// still on screen.
  static double stripHeight = 0;

  /// Asks the window to keep the strip white with dark glyphs. Flutter
  /// re-asserts its own edge-to-edge setup as screens change, so this is
  /// re-asked now and then; the last word wins.
  static void apply() {
    final now = DateTime.now();
    if (now.difference(_lastCall) < const Duration(seconds: 2)) return;
    _lastCall = now;
    _channel.invokeMethod('apply').then((value) {
      if (value is int && value > 0) {
        final dpr = WidgetsBinding.instance.platformDispatcher.views.first
            .devicePixelRatio;
        stripHeight = value / dpr;
      }
    }).catchError((_) {});
  }
}
