import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

enum PwnedPasswordStatus { safe, breached, unavailable }

/// Checks a password against HIBP's free Pwned Passwords range endpoint.
/// The password and full hash stay on device: only the first five SHA-1
/// characters are sent, and matching suffixes are compared locally.
class PwnedPasswordService {
  static Future<PwnedPasswordStatus> check(String password) async {
    try {
      final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
      final prefix = hash.substring(0, 5);
      final suffix = hash.substring(5);
      final response = await http
          .get(
            Uri.https('api.pwnedpasswords.com', '/range/$prefix'),
            headers: const {
              'Add-Padding': 'true',
              'User-Agent': 'InfinityApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return PwnedPasswordStatus.unavailable;

      for (final line in const LineSplitter().convert(response.body)) {
        final separator = line.indexOf(':');
        if (separator <= 0) continue;
        if (line.substring(0, separator).toUpperCase() == suffix) {
          final count = int.tryParse(line.substring(separator + 1).trim()) ?? 0;
          if (count > 0) return PwnedPasswordStatus.breached;
        }
      }
      return PwnedPasswordStatus.safe;
    } catch (_) {
      return PwnedPasswordStatus.unavailable;
    }
  }
}
