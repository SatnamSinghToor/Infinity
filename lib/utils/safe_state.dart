import 'package:flutter/widgets.dart';

extension SafeSetState<T extends StatefulWidget> on State<T> {
  /// [setState], but a no-op once the screen has been closed. Use it after an
  /// `await` (network loads, uploads), where the user may have left already.
  void safeSetState(VoidCallback fn) {
    // The extension lives outside the State class, but this is exactly what
    // it is for: setState behind a mounted check.
    // ignore: invalid_use_of_protected_member
    if (mounted) setState(fn);
  }
}
