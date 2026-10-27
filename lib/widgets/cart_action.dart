import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';

/// A single, consistent add / ± quantity button used by every product card,
/// shelf, cart row, voice-search row and the product-detail page.
///
/// When the product is not in the cart it shows an "ADD" button. When it is
/// in the cart it shows a − quantity + stepper. Cards use the solid primary
/// fill; large placements (the product page's buy bar) pass [outline] for a
/// white chip with an orange border, and a taller [height]. Product cards
/// pass [bagButton] for the square orange button with a shopping bag on it
/// that the card design is built around.
class CartAction extends StatelessWidget {
  final Product product;

  /// When true the widget never shows the ADD state — used in the cart screen
  /// and other places where the item is guaranteed to already be in the cart.
  final bool alwaysShowStepper;

  /// When true the ADD button is shown disabled (for out-of-stock products).
  final bool enabled;

  /// Explicit width override. When null the standard [_width] is used. A
  /// [bagButton]'s ADD state ignores it — that button is square, one [height]
  /// on a side — and takes this width only once the ± stepper appears, so
  /// [addWidth] is there for the cases where the ADD state should be wider
  /// too (the three-across shelf's full-width pill).
  final double? width;

  /// The ADD state's width, when it should be something other than the square
  /// [bagButton]. Ignored by every other look.
  final double? addWidth;

  /// Control height; cards keep the compact default.
  final double height;

  /// White background with an orange border and orange glyphs.
  final bool outline;

  /// The product-card look: a square orange button carrying a shopping bag
  /// in place of the word ADD, with the same orange behind the ± stepper.
  final bool bagButton;

  /// With [bagButton]: the ADD state is a white square with an orange
  /// border and an orange +, the way grocery shelves draw it over the
  /// product photo. The stepper it turns into is the same orange pill.
  final bool plusButton;

  /// How many sizes the product comes in. Two or more write "N Opt" under
  /// the +, the way the shelves say there is a choice to make.
  final int options;

  /// Replaces what ADD does — the product card opens the Choose Variant
  /// sheet here for a product sold in several sizes.
  final VoidCallback? onChoose;

  const CartAction({
    super.key,
    required this.product,
    this.alwaysShowStepper = false,
    this.enabled = true,
    this.width,
    this.addWidth,
    this.height = _height,
    this.outline = false,
    this.bagButton = false,
    this.plusButton = false,
    this.options = 0,
    this.onChoose,
  });

  /// Finds the ADD button in tests, whatever it is drawn as.
  static const addKey = ValueKey('cart-action-add');

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final quantity = cart.getQuantity(product.id);
    final adding = quantity == 0 && !alwaysShowStepper;

    // Every tap answers at once: the button dips under the finger, the
    // phone ticks, and the new state slides in. Without that a tap that
    // worked looked exactly like one that did not.
    final child = adding
        ? _addButton(
            enabled: product.isAvailable && enabled,
            onTap: () {
              HapticFeedback.lightImpact();
              if (onChoose != null) {
                onChoose!();
              } else if (!cart.addToCart(product)) {
                _stockLimit(context);
              }
            },
          )
        : _buildStepper(
            quantity: quantity,
            onMinus: () {
              HapticFeedback.selectionClick();
              cart.decreaseQuantity(product.id);
            },
            onPlus: () {
              HapticFeedback.selectionClick();
              if (!cart.increaseQuantity(product.id)) _stockLimit(context);
            },
          );

    // Only one state is ever on screen, drawn at full strength from its
    // first frame: the bag swaps for the stepper the moment the tap lands
    // and then pops into size. A cross-fade used to keep the old bag
    // visible under a still-transparent stepper, so a tap looked like it did
    // nothing while each further tap quietly added one more.
    final popped = _Pop(key: ValueKey(adding), child: child);
    // A card's square bag grows into a wider stepper. That room is held
    // for it from the start, bag on its right-hand edge, so tapping ADD
    // never takes width from the name and price beside it — they used to
    // shrink to fit the moment the stepper appeared.
    final stepperWidth = width;
    if (bagButton &&
        addWidth == null &&
        stepperWidth != null &&
        stepperWidth.isFinite) {
      return SizedBox(
        width: stepperWidth,
        child: Align(alignment: Alignment.centerRight, child: popped),
      );
    }
    return popped;
  }

  /// The + was pressed at the stock limit: say so instead of doing
  /// nothing.
  void _stockLimit(BuildContext context) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).cartStockLimit(product.stock),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  static const double _height = 36;
  static const double _width = 88;
  static const double _iconSize = 15;
  static const double _borderRadius = 10;

  /// Dark ink stays clear on the lighter orange and slate fills.
  static const Color _bagGlyph = AppConstants.textPrimaryColor;

  bool get _large => height > _height;

  /// What the pill is filled with.
  Color get _fill =>
      bagButton ? AppConstants.accentColor : AppConstants.primaryColor;

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: outline ? Colors.white : _fill,
      borderRadius: BorderRadius.circular(_borderRadius),
      border: outline
          ? Border.all(color: AppConstants.primaryColor, width: 1)
          : null,
      boxShadow: bagButton
          ? [
              BoxShadow(
                color: AppConstants.accentColor.withOpacity(0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  Color get _glyph {
    if (outline) return AppConstants.primaryColor;
    return _bagGlyph;
  }

  Widget _addButton({required VoidCallback onTap, required bool enabled}) {
    // The bag button is square unless a wider ADD state was asked for; the
    // ADD word takes the standard width.
    final buttonWidth = addWidth ?? (bagButton ? height : (width ?? _width));
    if (bagButton && plusButton) {
      final plusWidth = options >= 2 ? buttonWidth + 8 : buttonWidth;
      return _Pressable(
        key: addKey,
        onTap: enabled ? onTap : null,
        child: Container(
          height: height,
          width: plusWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? AppConstants.primaryColor
                  : AppConstants.primaryColor.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: options >= 2
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.add_copy,
                      size: 15,
                      color: AppConstants.primaryColor,
                    ),
                    Text(
                      '$options Opt',
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                )
              : Icon(
                  Iconsax.add_copy,
                  size: _large ? 22 : 20,
                  color: enabled
                      ? AppConstants.primaryColor
                      : AppConstants.primaryColor.withOpacity(0.35),
                ),
        ),
      );
    }
    return _Pressable(
      key: addKey,
      onTap: enabled ? onTap : null,
      child: Container(
        height: height,
        width: buttonWidth,
        decoration: !enabled
            ? BoxDecoration(
                color: _fill.withOpacity(0.25),
                borderRadius: BorderRadius.circular(_borderRadius),
              )
            : _decoration(),
        alignment: Alignment.center,
        child: bagButton
            ? Icon(
                Iconsax.shopping_bag,
                size: _large ? 20 : 17,
                color: enabled
                    ? AppConstants.textPrimaryColor
                    : AppConstants.textSecondaryColor,
              )
            : Text(
                'ADD',
                style: GoogleFonts.poppins(
                  fontSize: _large ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: !enabled
                      ? AppConstants.textSecondaryColor
                      : outline
                          ? AppConstants.primaryColor
                          : AppConstants.textPrimaryColor,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }

  Widget _buildStepper({
    required int quantity,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    // The quantity label and the gaps around it sit inside this card; if a
    // tap lands on them it must stop here — otherwise it falls through to
    // whatever wrapped the button (product cards open their detail page).
    //
    // It is also a roller, like a volume wheel with its numbers printed on
    // it: while a finger turns it, the − and + give way to a strip of
    // numbers that rolls with the finger, and whichever number reaches the
    // middle is the quantity. The − and + still work as plain taps.
    final countStyle = GoogleFonts.poppins(
      fontSize: _large ? 15 : 13,
      fontWeight: FontWeight.w600,
      color: _glyph,
    );
    return _Roller(
      quantity: quantity,
      maxQuantity: product.stock,
      style: countStyle,
      onMinus: onMinus,
      onPlus: onPlus,
      height: height,
      width: addWidth ?? width ?? _width,
      decoration: _decoration(),
      controls: Row(
        children: [
          _stepButton(Iconsax.minus_copy, onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _Count(quantity: quantity, style: countStyle),
          ),
          _stepButton(Iconsax.add_copy, onPlus),
        ],
      ),
    );
  }

  /// Every − / + fills its third of the pill, so there is no dead spot
  /// between the icon and the quantity where a tap could slip past to the
  /// card behind the button.
  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: _Pressable(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Icon(
              icon,
              size: _large ? 17 : _iconSize,
              color: _glyph,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tap target that dips under the finger: it shrinks a little while held
/// and springs back on release, so every press is seen to land.
class _Pressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _Pressable({super.key, required this.onTap, required this.child});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onTap == null || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.88 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// The quantity, rolling up when it grows and down when it shrinks.
class _Count extends StatefulWidget {
  final int quantity;
  final TextStyle style;

  const _Count({required this.quantity, required this.style});

  @override
  State<_Count> createState() => _CountState();
}

class _CountState extends State<_Count> {
  bool _up = true;

  @override
  void didUpdateWidget(_Count old) {
    super.didUpdateWidget(old);
    if (old.quantity != widget.quantity) {
      _up = widget.quantity > old.quantity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) {
          // The new number comes in from the side it moved towards; the old
          // one leaves the other way.
          final incoming = child.key == ValueKey(widget.quantity);
          final from = Offset(0, (_up == incoming) ? 0.6 : -0.6);
          return SlideTransition(
            position: Tween(begin: from, end: Offset.zero).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(
          '${widget.quantity}',
          key: ValueKey(widget.quantity),
          style: widget.style,
        ),
      ),
    );
  }
}

/// Springs its child in from a little smaller whenever it first appears.
/// The child is visible at every step, so even a frozen animation still
/// shows the right button.
class _Pop extends StatefulWidget {
  final Widget child;

  const _Pop({super.key, required this.child});

  @override
  State<_Pop> createState() => _PopState();
}

class _PopState extends State<_Pop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  late final Animation<double> _scale = Tween<double>(begin: 0.82, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// The stepper as a number wheel. A horizontal drag rolls a strip of
/// quantities across its face, with the finger, the way a time picker's
/// wheel moves: pushing it left brings the bigger numbers in from the
/// right (+1 for every notch), pushing it right brings the smaller ones in
/// (−1). Each step ticks under the finger. While it is still, it shows the
/// usual − quantity + controls. A tap anywhere that is not − or + stops
/// here rather than falling through to the card behind it.
class _Roller extends StatefulWidget {
  final int quantity;
  final int maxQuantity;
  final TextStyle style;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final double height;
  final double width;
  final BoxDecoration decoration;
  final Widget controls;

  const _Roller({
    required this.quantity,
    required this.maxQuantity,
    required this.style,
    required this.onMinus,
    required this.onPlus,
    required this.height,
    required this.width,
    required this.decoration,
    required this.controls,
  });

  /// How far the finger travels for one step.
  static const double notch = 14;

  @override
  State<_Roller> createState() => _RollerState();
}

class _RollerState extends State<_Roller> {
  /// Travel since the last step, carried over between drag updates. It is
  /// also how far the number strip sits off its resting place.
  double _pending = 0;
  bool _turning = false;

  void _drag(DragUpdateDetails details) {
    setState(() => _pending += details.delta.dx);
    while (_pending <= -_Roller.notch) {
      _pending += _Roller.notch;
      widget.onPlus();
    }
    while (_pending >= _Roller.notch) {
      _pending -= _Roller.notch;
      widget.onMinus();
    }
  }

  void _settle() {
    if (mounted) {
      setState(() {
        _pending = 0;
        _turning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      // Counted from where the finger first landed, so the travel it takes
      // to be recognised as a turn is not lost from the first notch.
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragStart: (_) => setState(() => _turning = true),
      onHorizontalDragUpdate: _drag,
      onHorizontalDragEnd: (_) => _settle(),
      onHorizontalDragCancel: _settle,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: widget.decoration,
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: _turning ? 0 : 1,
              duration: const Duration(milliseconds: 120),
              child: widget.controls,
            ),
            if (_turning)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRect(
                    child: _NumberStrip(
                      quantity: widget.quantity,
                      maxQuantity: widget.maxQuantity,
                      shift: _pending / _Roller.notch,
                      style: widget.style,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The numbers printed round the wheel: the quantity in the middle, full
/// size, and its neighbours towards the ends, smaller and fainter the way a
/// cylinder's far side turns away. [shift] is how many numbers' worth the
/// strip has rolled off centre, in the direction of the finger.
class _NumberStrip extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final double shift;
  final TextStyle style;

  const _NumberStrip({
    required this.quantity,
    required this.maxQuantity,
    required this.shift,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final half = box.maxWidth / 2;
        // Room for about three numbers across the face at once.
        final spacing = box.maxWidth / 3;
        final slots = <Widget>[];
        for (var k = -3; k <= 3; k++) {
          final value = quantity + k;
          if (value < 0 || value > maxQuantity) continue;
          final along = (k + shift) * spacing;
          final t = (along / (half + spacing * 0.5)).clamp(-1.0, 1.0);
          // Onto the face of a cylinder: bunched and faded near the ends.
          final x = half + half * math.sin(t * math.pi / 2);
          final facing = math.cos(t * math.pi / 2);
          if (facing <= 0.05) continue;
          slots.add(
            Positioned(
              left: x - spacing / 2,
              width: spacing,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: facing,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * facing,
                    child: Text(
                      '$value',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: style,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Stack(clipBehavior: Clip.hardEdge, children: slots);
      },
    );
  }
}
