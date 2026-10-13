import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/reset_password_screen.dart';
import 'push_service.dart';

/// The one link that would otherwise leave the app for a browser: the
/// password-reset email, which Supabase sends as
/// com.duggustore.app://reset-password#access_token=...&type=recovery (see
/// AuthProvider.sendPasswordReset). Android and iOS are told to hand that
/// scheme to this app in AndroidManifest.xml and Info.plist; this service
/// turns the link into a session and opens ResetPasswordScreen.
class DeepLinkService {
  const DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static bool _started = false;
  static bool _appReady = false;
  static final List<Uri> _pendingUris = [];

  /// Called once from main(), after the first frame — so
  /// PushService.navigatorKey has a context to read the AuthProvider from.
  static Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final initial = await _appLinks.getInitialAppLink();
      if (initial != null) await _handle(initial);
    } catch (e) {
      debugPrint('Initial deep link failed: $e');
    }
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object e) => debugPrint('Deep link stream error: $e'),
    );
  }

  /// Called by the app when the provider tree is ready (e.g., from main.dart
  /// after the first frame). Processes any pending deep links.
  static void markAppReady() {
    _appReady = true;
    for (final uri in _pendingUris) {
      unawaited(_handle(uri));
    }
    _pendingUris.clear();
  }

  /// Not called in the app itself (the listener lives for the app's whole
  /// life) — here so a test can tear it down between runs.
  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
    _appReady = false;
    _pendingUris.clear();
  }

  static Future<void> _handle(Uri uri) async {
    if (uri.host != 'reset-password') return;

    // If app isn't ready yet, queue the URI and process later.
    if (!_appReady) {
      _pendingUris.add(uri);
      return;
    }

    final context = PushService.navigatorKey?.currentContext;
    if (context == null) return;
    try {
      final auth = context.read<AuthProvider>();
      final isRecovery = await auth.completeAuthCallback(uri);
      if (!isRecovery || !context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
    } catch (e) {
      debugPrint('Handling reset-password link failed: $e');
    }
  }
}
