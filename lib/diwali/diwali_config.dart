/// One switch decides how the storefront is wired into the host app.
///
/// `false` (default): the existing Home screen stays exactly as it was. The
/// Diwali storefront is a chip on Home, plus the [kDiwaliRoute] named route.
/// On that tab the chip strip stays pinned, so switching back is one tap.
///
/// `true`: `MainShell` makes the storefront the Home tab itself and hides its
/// own bottom bar there, because the DiwaliPage route draws one of its own.
///
/// Either way the storefront is built entirely from Flutter widgets in this
/// folder — no HTML, no WebView, no new package dependency.
const bool kDiwaliAsHome = false;

/// Logical asset root. Every path used by the storefront is built from this,
/// so moving the folder is a one-line change plus one pubspec entry.
const String kDiwaliAssetRoot = 'assets/diwali';

/// The named route registered in `lib/main.dart`.
const String kDiwaliRoute = '/diwali';
