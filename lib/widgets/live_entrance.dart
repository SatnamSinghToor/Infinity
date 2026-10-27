import 'package:flutter/material.dart';

/// Fades, grows and slides a row in the first time its [id] is seen by this
/// screen — once for every row already there when a live list first loads,
/// and again for one a realtime update adds later. Without this, a row a
/// realtime watch inserted just appeared between frames like any other
/// rebuild; this is what makes "live" visible rather than merely true.
///
/// [seen] is one `Set` shared by every row on the same screen (kept on the
/// State, alongside the list itself) so a row that has already played its
/// entrance never replays it on an unrelated rebuild.
class LiveEntrance extends StatefulWidget {
  final String id;
  final Set<String> seen;
  final Widget child;

  const LiveEntrance({
    super.key,
    required this.id,
    required this.seen,
    required this.child,
  });

  @override
  State<LiveEntrance> createState() => _LiveEntranceState();
}

class _LiveEntranceState extends State<LiveEntrance>
    with SingleTickerProviderStateMixin {
  late final bool _isNew = widget.seen.add(widget.id);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: _isNew ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (_isNew) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizeTransition(
        sizeFactor: curved,
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(curved),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
