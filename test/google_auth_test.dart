import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// "Continue with Google" stays hidden and does nothing until a Google
/// Cloud Web OAuth client id is actually built into the app — these pins
/// keep that self-disabling wired the same way push already does, and
/// keep the button off the login and register screens' own layout logic
/// (it renders nothing when unconfigured, so it never has to be laid out).
void main() {
  String read(String path) => File(path).readAsStringSync();

  test('the service will not run without a configured client id', () {
    final src = read('lib/services/google_auth_service.dart');
    expect(src, contains("String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID')"));
    expect(src, contains('static bool get isConfigured'));
    expect(src, contains('if (!isConfigured)'));
  });

  test('a first-time Google sign-in gets no special profile handling', () {
    // The database's own handle_new_user trigger does this for every new
    // auth.users row, whatever the sign-in method — signInWithGoogle only
    // has to load the profile once a session exists, not write one.
    final src = read('lib/providers/auth_provider.dart');
    expect(src, contains('Future<bool> signInWithGoogle()'));
    expect(src, contains('GoogleAuthService.signIn()'));
    expect(src, contains('_loadProfile(user.id)'));
  });

  test('the button renders nothing until the app is configured', () {
    final src = read('lib/screens/auth/google_auth_button.dart');
    expect(src, contains('if (!GoogleAuthService.isConfigured)'));
    expect(src, contains('return const SizedBox.shrink()'));
  });

  test('the button is on both the login and the register screen', () {
    expect(read('lib/screens/auth/login_screen.dart'),
        contains('const GoogleAuthButton()'));
    expect(read('lib/screens/auth/register_screen.dart'),
        contains('const GoogleAuthButton()'));
  });

  test('the client id reaches the release build, not just local runs', () {
    final ci = read('.gitlab-ci.yml');
    expect(ci, contains('--dart-define=GOOGLE_SERVER_CLIENT_ID='));
  });
}
