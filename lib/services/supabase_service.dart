import 'package:supabase/supabase.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://rtceqrzicxrxaajfrerl.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0Y2VxcnppY3hyeGFhamZyZXJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwMTQ1ODYsImV4cCI6MjEwMzU5MDU4Nn0.sq_6imej_OhQYDXMEcZfkxyIuRKSxDYnqQCo-lWccL4';

  static final SupabaseClient client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    // The default PKCE auth flow needs an async storage implementation to
    // stash the code verifier; we don't provide one (no OAuth/deep-link
    // flows here), so every signUp/signIn crashed with a null-check error.
    // The implicit flow doesn't need that storage at all.
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      // Keep user sessions alive by rotating JWTs before expiry. Resume
      // recovery below handles the case where mobile OS suspension paused
      // the refresh timer in the background.
      autoRefreshToken: true,
    ),
  );
}
