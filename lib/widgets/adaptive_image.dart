import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Shows [image] in a box that takes the photo's own shape, so nothing is
/// cropped (unlike a fixed-height box with `BoxFit.cover`).
///
/// The box is as wide as the space it's given, and as tall as the photo's
/// aspect ratio needs. If [maxHeight] would be exceeded (tall photos), the box
/// shrinks in width instead so it still matches the photo. Extreme ratios
/// (panoramas, thin strips) are clamped to [minAspectRatio]..[maxAspectRatio]
/// and letterboxed rather than producing a huge or sliver-thin box.
class AdaptiveImage extends StatefulWidget {
  final ImageProvider image;
  final double? maxHeight;
  final double placeholderAspectRatio;
  final double minAspectRatio;
  final double maxAspectRatio;
  final BorderRadius borderRadius;
  final Color backgroundColor;

  /// Drawn on top of the photo, inside its box (e.g. an "edit" badge).
  final Widget? overlay;

  const AdaptiveImage({
    super.key,
    required this.image,
    this.maxHeight,
    this.placeholderAspectRatio = 1.5,
    this.minAspectRatio = 0.4,
    this.maxAspectRatio = 3.5,
    this.borderRadius = BorderRadius.zero,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.overlay,
  });

  @override
  State<AdaptiveImage> createState() => _AdaptiveImageState();
}

class _AdaptiveImageState extends State<AdaptiveImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _ratio;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(AdaptiveImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _ratio = null;
      _failed = false;
      _resolve();
    }
  }

  void _resolve() {
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _unsubscribe();
    _stream = stream;
    _listener = ImageStreamListener(
      (info, _) {
        final w = info.image.width;
        final h = info.image.height;
        if (mounted && w > 0 && h > 0) {
          setState(() {
            _ratio = w / h;
            _failed = false;
          });
        }
      },
      onError: (_, __) {
        if (mounted) setState(() => _failed = true);
      },
    );
    stream.addListener(_listener!);
  }

  void _unsubscribe() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = (_ratio ?? widget.placeholderAspectRatio)
            .clamp(widget.minAspectRatio, widget.maxAspectRatio)
            .toDouble();
        var width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        var height = width / ratio;
        final maxHeight = widget.maxHeight;
        if (maxHeight != null && height > maxHeight) {
          height = maxHeight;
          width = maxHeight * ratio;
        }

        final Widget content;
        if (_ratio == null) {
          content = Center(
            child: _failed
                ? Icon(Iconsax.image_copy, color: Colors.grey[500])
                : const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          );
        } else {
          content = Image(image: widget.image, fit: BoxFit.contain);
        }

        return Align(
          heightFactor: 1,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: widget.backgroundColor, child: content),
                  if (widget.overlay != null) widget.overlay!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
