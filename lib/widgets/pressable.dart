import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Makes any button answer the finger: it dips a little while pressed and
/// springs back on release, and a tap gives a light haptic tick.
///
/// It only listens to the pointer ([Listener]), so it never takes part in
/// the gesture arena: the wrapped button handles its own tap exactly as
/// before. A disabled Material button (`onPressed: null`) does not dip.
/// Shape and colour are the button's own; nothing about its look changes
/// except the brief press.
class Pressable extends StatefulWidget {
  final Widget child;

  /// Whether pressing does anything. When null it is read from [child]:
  /// a Material button or an [IconButton] without an `onPressed` is
  /// disabled, anything else is taken as enabled.
  final bool? enabled;

  /// How far the button shrinks while held.
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    this.enabled,
    this.pressedScale = 0.95,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  /// Further than this and the finger was scrolling, not tapping.
  static const _slop = 18.0;

  bool _down = false;
  Offset? _start;

  bool get _enabled {
    final explicit = widget.enabled;
    if (explicit != null) return explicit;
    final child = widget.child;
    if (child is ButtonStyleButton) return child.enabled;
    if (child is IconButton) return child.onPressed != null;
    return true;
  }

  void _press(PointerDownEvent event) {
    if (!_enabled) return;
    _start = event.position;
    setState(() => _down = true);
  }

  void _move(PointerMoveEvent event) {
    final start = _start;
    if (!_down || start == null) return;
    if ((event.position - start).distance > _slop) _release();
  }

  void _lift(PointerUpEvent event) {
    final wasTap = _down;
    _release();
    if (wasTap) HapticFeedback.selectionClick();
  }

  void _release() {
    _start = null;
    if (_down && mounted) setState(() => _down = false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _press,
      onPointerMove: _move,
      onPointerUp: _lift,
      onPointerCancel: (_) => _release(),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
