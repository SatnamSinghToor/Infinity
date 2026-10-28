/// The Diwali festival home screen — a self-contained module.
///
/// Drop `lib/diwali_festive/` into a Flutter app, make sure the fonts and
/// `assets/diwali/` are declared in `pubspec.yaml`, then:
///
/// ```dart
/// MaterialApp(
///   routes: <String, WidgetBuilder>{
///     kDiwaliFestiveRoute: (_) => const DiwaliFestiveScreen(),
///   },
/// )
/// ```
///
/// The module imports only `package:flutter/*`; it has no third-party
/// dependencies and no code generation.
library;

export 'festive_art.dart';
export 'festive_cards.dart';
export 'festive_data.dart';
export 'festive_home.dart';
export 'festive_sheets.dart';
export 'festive_store.dart';
export 'festive_tokens.dart';
export 'festive_widgets.dart';

/// Named route for the festival storefront.
const String kDiwaliFestiveRoute = '/diwali-festive';
