import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase/supabase.dart'
    show AuthException, AuthResponse, OAuthProvider;

import 'supabase_service.dart';

/// "Continue with Google": the native account picker, then a Supabase
/// session from the ID token it returns. Supabase's own trigger
/// (`handle_new_user`, in the database) creates the `profiles` row for a
/// first-time Google sign-in exactly as it does for an email sign-up — this
/// only has to get a session, not write a profile.
class GoogleAuthService {
  const GoogleAuthService._();

  /// The Google Cloud **Web** OAuth client's ID — not a secret, just an
  /// identifier (same kind of thing as the Razorpay key or the Firebase
  /// `api_key` already checked in) — but until it's set, this feature must
  /// stay off rather than fail confusingly on every tap. Set it once
  /// Authentication → Providers → Google is turned on in the Supabase
  /// dashboard: see supabase/README.md.
  static const _serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static bool get isConfigured => _serverClientId.isNotEmpty;

  static bool _initialized = false;

  /// google_sign_in 7.x is a singleton configured through one exact
  /// `initialize()` call — there is no constructor to pass the server
  /// client id into any more. Idempotent: every entry point awaits this.
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    _initialized = true;
  }

  /// Runs the account picker and exchanges the result for a Supabase
  /// session. Returns null on a plain cancel (the picker closed with
  /// nothing chosen) — not an error, so nothing is said about it. Any other
  /// failure is rethrown as an [AuthException] so the caller can show the
  /// same "couldn't sign in" message it already shows for email/password.
  ///
  /// google_sign_in 7.x API: `authenticate()` instead of `signIn()`, cancel
  /// surfaces as a [GoogleSignInException] with code `canceled`, and the
  /// access token needs a separate authorization call (only the idToken is
  /// guaranteed by authentication alone).
  static Future<AuthResponse?> signIn() async {
    if (!isConfigured) {
      throw const AuthException(
        'Google sign-in is not set up yet on this build.',
      );
    }
    final account = await _authenticateOrNull();
    if (account == null) return null; // the picker was dismissed

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException(
        "Google didn't return a usable sign-in token. Try again.",
      );
    }

    // Supabase's Google flow works with the idToken; the access token is
    // optional and only attached when Google already has a cached
    // authorization for the email scope (no extra prompt).
    String? accessToken;
    try {
      final authorization = await account.authorizationClient
          .authorizationForScopes(const ['email']);
      accessToken = authorization?.accessToken;
    } catch (_) {
      // No authorization — Supabase accepts the idToken by itself.
    }

    return SupabaseService.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Wraps [GoogleSignIn.authenticate]: returns null when the user closed
  /// the picker, and rethrows other failures as the [AuthException] the
  /// callers already know how to show.
  static Future<GoogleSignInAccount?> _authenticateOrNull() async {
    try {
      await _ensureInitialized();
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthException(
        e.description ?? 'Google sign-in failed (${e.code.name}).',
      );
    }
  }

  /// Only clears Google's own cached account — not the app's session. A
  /// mismatch between the two (signed out of Infinity, still cached in
  /// Google) would otherwise skip the picker on the next attempt and
  /// silently sign the same account back in.
  static Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google sign-out failed: $e');
    }
  }
}
