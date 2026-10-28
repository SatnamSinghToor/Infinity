import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'festive_art.dart';
import 'festive_data.dart';
import 'festive_tokens.dart';

/// Layout + palette context for the storefront.
///
/// The page computes the breakpoint, the content width and the type scale once
/// and publishes them here; descendants read them with [FestiveScope.of]
/// instead of every widget re-deriving them from [MediaQuery].
class FestiveScope extends InheritedWidget {
  const FestiveScope({
    super.key,
    required this.size,
    required this.palette,
    required this.contentWidth,
    required this.gutter,
    required super.child,
  });

  final FestiveSize size;
  final FestivePalette palette;

  /// Width the *content* may occupy: the window width on a phone, capped at
  /// [FestiveBreakpoints.maxContentWidth] on desktop.
  final double contentWidth;
  final double gutter;

  static FestiveScope of(BuildContext context) {
    final FestiveScope? scope =
        context.dependOnInheritedWidgetOfExactType<FestiveScope>();
    assert(scope != null, 'FestiveScope is missing above this widget.');
    return scope!;
  }

  /// Scales the phone type scale up on larger windows.
  double type(double value) => value * size.typeScale;

  @override
  bool updateShouldNotify(FestiveScope oldWidget) =>
      oldWidget.size != size ||
      oldWidget.palette != palette ||
      oldWidget.contentWidth != contentWidth ||
      oldWidget.gutter != gutter;
}

/// Publishes the page's [ScrollController] to every [FestiveReveal].
class FestiveRevealScope extends InheritedWidget {
  const FestiveRevealScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ScrollController controller;

  static ScrollController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FestiveRevealScope>()?.controller;

  @override
  bool updateShouldNotify(FestiveRevealScope oldWidget) =>
      oldWidget.controller != controller;
}

/// Scroll-triggered entrance: fade, rise and a hair of scale, once.
///
/// Driven by the page's own [ScrollController] (through [FestiveRevealScope]),
/// so it also works inside slivers and never depends on a scroll position that
/// does not exist yet. Reduced motion shows the content immediately.
class FestiveReveal extends StatefulWidget {
  const FestiveReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 26,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<FestiveReveal> createState() => _FestiveRevealState();
}

class _FestiveRevealState extends State<FestiveReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FestiveMotion.reveal,
  );

  ScrollController? _scroll;
  Timer? _delayTimer;
  bool _triggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollController? next = FestiveRevealScope.of(context);
    if (next != _scroll) {
      _scroll?.removeListener(_check);
      _scroll = next;
      _scroll?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_triggered || !mounted) return;
    if (_scroll == null) {
      // No host scroll view (widget tests, previews): show it.
      _trigger();
      return;
    }
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final double dy;
    final double screenHeight;
    try {
      dy = box.localToGlobal(Offset.zero).dy;
      screenHeight = MediaQuery.sizeOf(context).height;
    } catch (_) {
      return; // Between frames during teardown.
    }
    if (dy < screenHeight * 0.95 && dy > -box.size.height * 0.5) {
      _trigger();
    }
  }

  void _trigger() {
    if (_triggered || !mounted) return;
    _triggered = true;
    _scroll?.removeListener(_check);
    if (FestiveMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
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
      builder: (BuildContext context, Widget? child) {
        final double t = FestiveMotion.enter.transform(_controller.value);
        return Opacity(
          opacity: t.clamp(0, 1).toDouble(),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offsetY),
            child: child,
          ),
        );
      },
    );
  }
}

/// Tap target with pointer hover lift and touch press feedback.
///
/// Hover callbacks only fire for mouse/trackpad/stylus, so a phone scroll can
/// never leave a card stuck in its hover state.
class FestiveTap extends StatefulWidget {
  const FestiveTap({
    super.key,
    required this.child,
    this.onTap,
    this.hoverLift = 4,
    this.hoverScale = 1.0,
    this.pressedScale = 0.97,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double hoverLift;
  final double hoverScale;
  final double pressedScale;
  final String? semanticLabel;

  @override
  State<FestiveTap> createState() => _FestiveTapState();
}

class _FestiveTapState extends State<FestiveTap> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHover(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.onTap != null;
    Widget child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: interactive ? (_) => _setPressed(true) : null,
      onTapCancel: interactive ? () => _setPressed(false) : null,
      onTapUp: interactive ? (_) => _setPressed(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: FestiveMotion.fast,
        curve: FestiveMotion.enter,
        scale: _pressed
            ? widget.pressedScale
            : (_hovered ? widget.hoverScale : 1),
        child: AnimatedContainer(
          duration: FestiveMotion.fast,
          curve: FestiveMotion.enter,
          transform: Matrix4.translationValues(
            0,
            _hovered && !_pressed ? -widget.hoverLift : 0,
            0,
          ),
          child: widget.child,
        ),
      ),
    );

    if (interactive) {
      child = MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: child,
      );
    }

    if (widget.semanticLabel != null) {
      child = Semantics(button: interactive, label: widget.semanticLabel, child: child);
    }
    return child;
  }
}

/// The "Surge applicable" pill next to the delivery promise.
class SurgePill extends StatelessWidget {
  const SurgePill({
    super.key,
    required this.label,
    required this.color,
    required this.accent,
  });

  final String label;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 4, 9, 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(46),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.trending_up_rounded, size: 11, color: accent),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FestiveType.body(
                10.5,
                color: color,
                weight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dark strip at the top of the screen: brand, delivery promise, address,
/// search field and voice button.
class FestiveHeader extends StatelessWidget {
  const FestiveHeader({
    super.key,
    required this.copy,
    required this.palette,
    required this.typeScale,
    required this.onSearchTap,
    required this.onVoiceTap,
    required this.onAddressTap,
    required this.onWalletTap,
    required this.onProfileTap,
    this.voiceListening = false,
    this.horizontalPadding = FestiveMetrics.headerHorizontal,
  });

  final FestiveCopy copy;
  final FestivePalette palette;
  final double typeScale;
  final VoidCallback onSearchTap;
  final VoidCallback onVoiceTap;
  final VoidCallback onAddressTap;
  final VoidCallback onWalletTap;
  final VoidCallback onProfileTap;
  final bool voiceListening;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      copy.brand,
                      style: FestiveType.body(
                        13 * typeScale,
                        color: Colors.white,
                        weight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    _EtaRow(copy: copy, typeScale: typeScale),
                    const SizedBox(height: 2),
                    _AddressRow(
                      copy: copy,
                      typeScale: typeScale,
                      onTap: onAddressTap,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _WalletButton(
                      balance: copy.walletBalance,
                      onTap: onWalletTap,
                      scale: typeScale,
                    ),
                    const SizedBox(width: 8),
                    _ProfileButton(onTap: onProfileTap, scale: typeScale),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: FestiveSearchBar(
                  hints: copy.searchHints,
                  onTap: onSearchTap,
                  typeScale: typeScale,
                ),
              ),
              const SizedBox(width: 6),
              VoiceSearchButton(
                listening: voiceListening,
                onTap: onVoiceTap,
                size: FestiveMetrics.searchBarHeight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EtaRow extends StatelessWidget {
  const _EtaRow({required this.copy, required this.typeScale});

  final FestiveCopy copy;
  final double typeScale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Text(
            copy.eta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FestiveType.body(
              28 * typeScale,
              color: Colors.white,
              weight: FontWeight.w800,
              height: 1.12,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SurgePill(
          label: copy.surgeLabel,
          color: Colors.white,
          accent: Colors.white.withAlpha(235),
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.copy,
    required this.typeScale,
    required this.onTap,
  });

  final FestiveCopy copy;
  final double typeScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Deliver to ${copy.addressTag}, ${copy.addressLine}. Change address',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: copy.addressTag,
                      style: FestiveType.body(
                        15 * typeScale,
                        color: Colors.white,
                        weight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    TextSpan(
                      text: ' - ${copy.addressLine}',
                      style: FestiveType.body(
                        15 * typeScale,
                        color: Colors.white,
                        weight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 22 * typeScale,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletButton extends StatelessWidget {
  const _WalletButton({
    required this.balance,
    required this.onTap,
    required this.scale,
  });

  final int balance;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double d = 36 * scale;
    return Semantics(
      button: true,
      label: 'Wallet balance ${rupee(balance)}. Open wallet',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: d + 4,
          height: d + 12,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: <Widget>[
              Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(38)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: d * 0.56,
                      color: const Color(0xFFD6B23B),
                    ),
                    Text(
                      '₹',
                      style: FestiveType.body(
                        d * 0.28,
                        color: const Color(0xFF3A2C00),
                        weight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: d * 0.22, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(38)),
                  ),
                  child: Text(
                    rupee(balance),
                    style: FestiveType.body(
                      d * 0.32,
                      color: Colors.white,
                      weight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap, required this.scale});

  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double d = 40 * scale;
    return Semantics(
      button: true,
      label: 'Account',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(38)),
          ),
          child: Icon(Icons.person_rounded, size: d * 0.62, color: Colors.white),
        ),
      ),
    );
  }
}

/// The search field. It is a button, not a text field: tapping it opens the
/// search sheet, exactly like the storefront it recreates.
class FestiveSearchBar extends StatefulWidget {
  const FestiveSearchBar({
    super.key,
    required this.hints,
    required this.onTap,
    required this.typeScale,
  });

  final List<String> hints;
  final VoidCallback onTap;
  final double typeScale;

  @override
  State<FestiveSearchBar> createState() => _FestiveSearchBarState();
}

class _FestiveSearchBarState extends State<FestiveSearchBar> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.hints.length < 2) return;
    _timer = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.hints.length);
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = FestiveMotion.reduced(context);
    final String hint = widget.hints.isEmpty ? 'Search' : widget.hints[_index];
    return Semantics(
      button: true,
      label: 'Search for products',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FestiveMetrics.searchRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: SizedBox(
            height: FestiveMetrics.searchBarHeight,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 10),
                Icon(
                  Icons.search,
                  size: 22 * widget.typeScale,
                  color: const Color(0xFF1B1B1B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: reduce ? Duration.zero : FestiveMotion.base,
                      switchInCurve: FestiveMotion.enter,
                      switchOutCurve: FestiveMotion.exit,
                      transitionBuilder: (Widget child, Animation<double> anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      layoutBuilder: (Widget? current, List<Widget> previous) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: <Widget>[
                            ...previous,
                            if (current != null) current,
                          ],
                        );
                      },
                      child: Text(
                        'Search "$hint"',
                        key: ValueKey<String>(hint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FestiveType.body(
                          15 * widget.typeScale,
                          color: const Color(0xFF1F1F1F),
                          weight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The animated equaliser tile next to the search field.
class VoiceSearchButton extends StatefulWidget {
  const VoiceSearchButton({
    super.key,
    required this.listening,
    required this.onTap,
    this.size = FestiveMetrics.searchBarHeight,
  });

  final bool listening;
  final VoidCallback onTap;
  final double size;

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (FestiveMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 0.35;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = FestiveMotion.reduced(context);
    return Semantics(
      button: true,
      label: widget.listening ? 'Stop voice search' : 'Search with your voice',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: FestiveMotion.fast,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFFFFFFF), Color(0xFFFFF8EC)],
            ),
            borderRadius: BorderRadius.circular(FestiveMetrics.searchRadius),
            border: Border.all(
              color: widget.listening
                  ? const Color(0xFF0C831F)
                  : const Color(0x14000000),
              width: widget.listening ? 1.6 : 1,
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return CustomPaint(
                painter: _EqualizerPainter(
                  progress: reduce ? 0.35 : _controller.value,
                  listening: widget.listening,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  const _EqualizerPainter({required this.progress, required this.listening});

  final double progress;
  final bool listening;

  @override
  void paint(Canvas canvas, Size size) {
    const List<double> base = <double>[0.34, 0.62, 0.95, 0.58, 0.4];
    final double barWidth = size.width * 0.06;
    final double gap = size.width * 0.055;
    final double totalWidth =
        base.length * barWidth + (base.length - 1) * gap;
    final double left = (size.width - totalWidth) / 2;
    final Paint paint = Paint()
      ..color = const Color(0xFF1E6B33)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (int i = 0; i < base.length; i++) {
      final double phase = progress * 2 * math.pi + i * 0.9;
      final double wobble = listening ? 0.28 : 0.1;
      final double factor =
          (base[i] * (1 + wobble * math.sin(phase))).clamp(0.12, 1.0).toDouble();
      final double h = size.height * 0.42 * factor;
      final double x = left + i * (barWidth + gap) + barWidth / 2;
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint,
      );
    }

    // The little green "listening" dot in the corner of the tile.
    if (listening) {
      canvas.drawCircle(
        Offset(size.width * 0.78, size.height * 0.24),
        size.width * 0.035,
        Paint()..color = const Color(0xFF0C831F),
      );
    }
  }

  @override
  bool shouldRepaint(_EqualizerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.listening != listening;
}

/// The six-icon category strip with the animated white indicator.
class FestiveTabStrip extends StatelessWidget {
  const FestiveTabStrip({
    super.key,
    required this.categories,
    required this.index,
    required this.onSelected,
    required this.typeScale,
    required this.contentWidth,
  });

  final List<FestiveCategory> categories;
  final int index;
  final ValueChanged<int> onSelected;
  final double typeScale;
  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    final double per = contentWidth / categories.length;
    final bool fits = per >= 56;

    final List<Widget> items = <Widget>[
      for (int i = 0; i < categories.length; i++)
        _TabItem(
          category: categories[i],
          selected: i == index,
          typeScale: typeScale,
          onTap: () => onSelected(i),
        ),
    ];

    final Widget row = fits
        ? Row(
            children: <Widget>[
              for (final Widget item in items) Expanded(child: item),
            ],
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: <Widget>[
                for (final Widget item in items) SizedBox(width: 62, child: item),
              ],
            ),
          );

    return SizedBox(
      height: FestiveMetrics.tabStripHeight,
      child: row,
    );
  }
}

class _TabItem extends StatefulWidget {
  const _TabItem({
    required this.category,
    required this.selected,
    required this.typeScale,
    required this.onTap,
  });

  final FestiveCategory category;
  final bool selected;
  final double typeScale;
  final VoidCallback onTap;

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color color = widget.selected
        ? Colors.white
        : Colors.white.withAlpha(205);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.category.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: FestiveMotion.fast,
            color: _hovered && !widget.selected
                ? Colors.white.withAlpha(16)
                : Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedScale(
                  duration: FestiveMotion.fast,
                  scale: widget.selected ? 1.08 : 1,
                  child: FestiveGlyphIcon(
                    glyph: widget.category.glyph,
                    color: color,
                    size: 21 * widget.typeScale,
                    strokeWidth: 1.6,
                    fill: widget.selected
                        ? Colors.white.withAlpha(26)
                        : Colors.white.withAlpha(14),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: FestiveType.body(
                    11 * widget.typeScale,
                    color: color,
                    height: 1.1,
                    weight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: FestiveMotion.base,
                  curve: FestiveMotion.enter,
                  height: 4,
                  width: widget.selected ? 34 * widget.typeScale : 0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation of the storefront, including the red Zomato chip.
class FestiveBottomBar extends StatelessWidget {
  const FestiveBottomBar({
    super.key,
    required this.destinations,
    required this.index,
    required this.onSelected,
    required this.palette,
    this.onZomatoTap,
    this.showZomato = true,
  });

  final List<FestiveNavDestination> destinations;
  final int index;
  final ValueChanged<int> onSelected;
  final FestivePalette palette;
  final VoidCallback? onZomatoTap;
  final bool showZomato;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.navSurface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(palette.isDark ? 120 : 26),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: palette.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: FestiveMetrics.navBarHeight,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == index,
                    palette: palette,
                    onTap: () => onSelected(i),
                  ),
                ),
              if (showZomato)
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 2),
                  child: ZomatoChip(onTap: onZomatoTap, palette: palette),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final FestiveNavDestination destination;
  final bool selected;
  final FestivePalette palette;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.selected;
    final Color labelColor =
        active ? widget.palette.navActive : widget.palette.navInactive;
    return Semantics(
      button: true,
      selected: active,
      label: widget.destination.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: FestiveMotion.fast,
            decoration: BoxDecoration(
              color: _hovered ? labelColor.withAlpha(14) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AnimatedScale(
                  duration: FestiveMotion.base,
                  curve: FestiveMotion.spring,
                  scale: active ? 1.06 : 1,
                  child: FestiveGlyphIcon(
                    glyph: widget.destination.glyph,
                    color: labelColor,
                    size: 21,
                    strokeWidth: active ? 1.9 : 1.7,
                    fill: active
                        ? (widget.destination.glyph == FestiveGlyph.home
                            ? FestiveColors.homeFill
                            : widget.palette.gold.withAlpha(70))
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FestiveType.body(
                    10.5,
                    color: labelColor,
                    weight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The red rounded "zomato" tile that sits at the end of the nav bar.
class ZomatoChip extends StatelessWidget {
  const ZomatoChip({super.key, this.onTap, required this.palette});

  final VoidCallback? onTap;
  final FestivePalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Order food on Zomato',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 52,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.zomato,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'zomato',
            style: FestiveType.body(
              12.5,
              color: Colors.white,
              weight: FontWeight.w800,
              style: FontStyle.italic,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating "view cart" bar that rises above the nav once something is in
/// the basket.
class FestiveCartBar extends StatelessWidget {
  const FestiveCartBar({
    super.key,
    required this.count,
    required this.total,
    required this.onTap,
    required this.palette,
  });

  final int count;
  final int total;
  final VoidCallback onTap;
  final FestivePalette palette;

  @override
  Widget build(BuildContext context) {
    return FestiveTap(
      onTap: onTap,
      pressedScale: 0.985,
      semanticLabel: '$count items in cart, total ${rupee(total)}. View cart',
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.add,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_rounded,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'}',
                    style: FestiveType.body(
                      11,
                      color: Colors.white.withAlpha(230),
                      weight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    rupee(total),
                    style: FestiveType.body(
                      15,
                      color: Colors.white,
                      weight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'View cart',
              style: FestiveType.body(
                13,
                color: Colors.white,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
