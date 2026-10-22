import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One UPI payment app installed on the phone.
class InstalledUpiApp {
  final String package;
  final String label;
  final Uint8List? icon;

  const InstalledUpiApp({
    required this.package,
    required this.label,
    this.icon,
  });
}

/// The UPI apps Android says are on this phone: they all answer the
/// `upi://` scheme, so the checkout can offer each of them as its own
/// payment option with the app's real launcher icon.
class PaymentChoice {
  PaymentChoice._();

  /// The UPI apps on the phone; loaded once and kept here.
  static List<InstalledUpiApp> apps = const [];

  /// What the picker shows: the real apps, or a plain UPI row when the
  /// phone reports none (so paying by UPI is never lost).
  static List<InstalledUpiApp> get list => apps.isEmpty
      ? const [InstalledUpiApp(package: 'upi', label: 'UPI')]
      : apps;

  /// Where the user stands in [list ... card ... cash]. Starts on 0.
  static int index = 0;

  /// Nothing picked yet: the cart still shows Select Payment Method. Set
  /// the moment a row on the picker is tapped, and the bar flips to the
  /// chosen method + Place Order.
  static bool chosen = false;

  /// Whether the checkout would spend wallet money (picker's switch).
  static bool useWallet = false;

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    apps = await UpiAppsService.installed();
  }

  static List<String> get _codes =>
      [for (final _ in list) 'upi', 'card', 'cod'];

  static int get _clamped => index.clamp(0, _codes.length - 1);

  /// The server's payment code: 'upi' for every UPI app, then card, cash.
  static String get code => _codes[_clamped];

  /// What the cart's bar reads: "PhonePe UPI", "Card" or "Cash on Delivery".
  static String get label {
    final i = _clamped;
    if (i < list.length) {
      final app = list[i];
      return app.package == 'upi' ? app.label : '${app.label} UPI';
    }
    return i == list.length ? 'Card' : 'Cash on Delivery';
  }

  /// The real launcher icon of the chosen UPI app; null for card and cash.
  static Uint8List? get icon =>
      _clamped < list.length ? list[_clamped].icon : null;
}

class UpiAppsService {
  static const MethodChannel _channel = MethodChannel('duggu/upi_apps');

  static Future<List<InstalledUpiApp>> installed() async {
    try {
      final rows = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'list',
      );
      final apps = <InstalledUpiApp>[];
      for (final row in (rows ?? const <Map<dynamic, dynamic>>[])) {
        final package = row['package'] as String? ?? '';
        if (package.isEmpty) continue;
        Uint8List? iconBytes;
        try {
          final encoded = (row['icon'] as String? ?? '').trim();
          if (encoded.isNotEmpty) {
            // Line breaks and spaces are not part of the data; a broken
            // icon must never take the whole list down with it.
            iconBytes = base64Decode(
              encoded.replaceAll(RegExp(r'\s'), ''),
            );
          }
        } catch (_) {
          iconBytes = null;
        }
        apps.add(
          InstalledUpiApp(
            package: package,
            label: row['label'] as String? ?? package,
            icon: iconBytes,
          ),
        );
      }
      debugPrint('[upi] ${apps.length} apps: '
          '${apps.map((a) => a.label).join(', ')}');
      return apps;
    } catch (e) {
      debugPrint('[upi] list failed: $e');
      // Not Android, no apps, or the channel failed: the checkout falls
      // back to the plain single UPI row.
      return const <InstalledUpiApp>[];
    }
  }
}
