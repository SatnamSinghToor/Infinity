import 'package:url_launcher/url_launcher.dart';

/// What a delivery partner does in another app: call someone, and — when
/// the in-app route isn't enough — turn-by-turn voice navigation. The run
/// list still opens the app's own map first (DeliveryNavigateScreen); this
/// is the button on that screen for handing the route to Google Maps.
class LaunchActions {
  const LaunchActions._();

  /// Opens the dialler with [phone] pre-filled. Returns whether a dialler
  /// app answered — a phone number typed into a form is not always a real,
  /// reachable one, and the caller decides what to say when this is false.
  static Future<bool> call(String phone) async {
    final digits = phone.trim();
    if (digits.isEmpty) return false;
    return launchUrl(Uri(scheme: 'tel', path: digits));
  }

  /// Turn-by-turn directions to [lat],[lng] in Google Maps (or the browser
  /// when it isn't installed). Returns whether anything opened.
  static Future<bool> directions(double lat, double lng) {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      'travelmode': 'driving',
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
