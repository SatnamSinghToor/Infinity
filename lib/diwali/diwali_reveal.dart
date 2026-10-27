import 'dart:async';

import 'package:flutter/material.dart';

/// Provides the storefront's [ScrollController] to every [DiwaliReveal].
///
/// An explicit controller is more predictable than walking up to
/// `Scrollable.of(context)`: it works inside nested slivers, nested scroll
/// views and modal sheets, and it never registers a rebuild dependency on a
/// scroll position that is not there yet.
class DiwaliRevealScope extends InheritedWidget {
  const DiwaliRevealScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ScrollController controller;

  static ScrollController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DiwaliRevealScope>()?.controller;

  @override
  bool updateShouldNotify(covariant DiwaliRevealScope oldWidget) =>
      oldWidget.controller != controller;
}

/// Scroll-triggered entrance animation.
///
/// Each reveal listens to the page's scroll offset and starts its fade/slide
/// the first time its top edge enters the bottom 95% of the viewport. The
/// stagger comes from [delay]. When the OS requests reduced motion, content
/// appears immediately with no animation.
class DiwaliReveal extends StatefulWidget {
  const DiwaliReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 620),
    this.offsetY = 26,
    this.scaleFrom = 0.985,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double scaleFrom;

  @override
  State<DiwaliReveal> createState() => _DiwaliRevealState();
}

class _DiwaliRevealState extends State<DiwaliReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  ScrollController? _scroll;
  Timer? _delayTimer;
  bool _triggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = DiwaliRevealScope.of(context);
    if (next != _scroll) {
      _scroll?.removeListener(_check);
      _scroll = next;
      _scroll?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_triggered || !mounted) return;
    final scroll = _scroll;
    if (scroll == null) {
      // No host scroll view (e.g. an isolated widget test): reveal at once.
      _trigger();
      return;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final double dy;
    try {
      dy = box.localToGlobal(Offset.zero).dy;
    } catch (_) {
      return;
    }
    final double screenHeight;
    try {
      screenHeight = MediaQuery.sizeOf(context).height;
    } catch (_) {
      // The element can be between frames (hot reload, test teardown).
      return;
    }
    final visible =
        dy < screenHeight * 0.95 && dy > -box.size.height * 0.5;
    if (visible) _trigger();
  }

  void _trigger() {
    if (_triggered || !mounted) return;
    _triggered = true;
    _scroll?.removeListener(_check);
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    if (reduceMotion || widget.duration == Duration.zero) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      // A cancellable Timer (rather than Future.delayed) means a widget that
      // scrolls out of view or is disposed mid-stagger leaves no pending
      // timer behind — widget tests and hot restarts stay clean.
      _delayTimer?.cancel();
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _scroll?.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offsetY),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// A gentle lift + shadow for pointer devices. On touch it is a no-op, so
/// mobile scrolling never triggers a hover flash.
class DiwaliHoverLift extends StatefulWidget {
  const DiwaliHoverLift({
    super.key,
    required this.child,
    this.lift = 5,
    this.borderRadius = 18,
    this.onTap,
  });

  final Widget child;
  final double lift;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  State<DiwaliHoverLift> createState() => _DiwaliHoverLiftState();
}

class _DiwaliHoverLiftState extends State<DiwaliHoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform:
            Matrix4.translationValues(0, _hovered ? -widget.lift : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _hovered
              ? const [
                  BoxShadow(
                    color: Color(0x2B390014),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
    if (widget.onTap == null) return child;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

/// A pressable wrapper that gives consistent 96 ms ink-less feedback.
class DiwaliTap extends StatefulWidget {
  const DiwaliTap({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 12,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final double pressedScale;

  @override
  State<DiwaliTap> createState() => _DiwaliTapState();
}

class _DiwaliTapState extends State<DiwaliTap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 96),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: widget.child,
        ),
      ),
    );
  }
}
