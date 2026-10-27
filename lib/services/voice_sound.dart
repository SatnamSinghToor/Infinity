import 'package:flutter/services.dart';

/// The voice sheet's own sounds, in place of the speech recogniser's beep.
///
/// Android's recogniser beeps every time it starts or stops listening, and the
/// sheet restarts it after every pause — so a short list was a string of
/// beeps. There is no switch for that beep, so while the sheet listens the
/// phone's music, system and notification streams are muted (MainActivity
/// only ever unmutes what it muted, and always unmutes when the app goes to
/// the background), and a soft chime plays at the start and at the end
/// instead. On a platform without the channel all of this quietly does
/// nothing.
class VoiceSound {
  const VoiceSound._();

  static const _channel = MethodChannel('duggu/voice_sound');
  static const _start = 'assets/sounds/voice_start.wav';
  static const _done = 'assets/sounds/voice_done.wav';

  /// Long enough for the start chime to ring out before its stream is muted.
  static const _chimeLength = Duration(milliseconds: 420);

  /// Long enough for the recogniser's closing beep to fall on a muted stream.
  static const _stopBeepLength = Duration(milliseconds: 600);

  /// Whether a listening session is on; [end] can arrive while [begin] is
  /// still waiting for its chime, and must win.
  static bool _active = false;
  static bool _muted = false;

  /// Before listening starts: the chime, then silence for the recogniser.
  static Future<void> begin() async {
    if (_active) return;
    _active = true;
    await _call('play', {'asset': _start});
    await Future<void>.delayed(_chimeLength);
    if (!_active) return;
    _muted = true;
    await _call('muteBeep');
  }

  /// After listening has stopped. [success] rings the closing chime.
  static Future<void> end({bool success = false}) async {
    if (!_active) return;
    _active = false;
    if (_muted) {
      _muted = false;
      await Future<void>.delayed(_stopBeepLength);
      await _call('unmuteBeep');
    }
    if (success) await _call('play', {'asset': _done});
  }

  static Future<void> _call(String method, [Map<String, Object?>? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // iOS, and tests: there is no beep to replace there.
    } on PlatformException {
      // A sound is never worth failing the search over.
    }
  }
}
