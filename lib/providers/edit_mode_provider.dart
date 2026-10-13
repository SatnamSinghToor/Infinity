import 'package:flutter/foundation.dart';

/// Whether the admin is editing the store from the customer app itself.
///
/// While it is on, every part of the app that an admin can change shows a
/// pencil (see `EditBadge`). It starts off each time the admin opens the
/// store, so the app behaves exactly like the customer's until they switch it
/// on.
class EditModeProvider extends ChangeNotifier {
  bool _enabled = false;

  bool get enabled => _enabled;

  void set(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  void toggle() => set(!_enabled);
}
