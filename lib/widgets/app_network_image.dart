import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A picture from the web, used everywhere in place of `Image.network`:
///
/// * it is kept on the phone's disk, so it appears at once the next time and
///   does not download again after the app is closed (a big help on a slow
///   connection);
/// * until it arrives a soft placeholder is shown, and it fades in;
/// * very large photos are decoded no bigger than [_maxDecodeWidth], which
///   keeps a phone with little memory from struggling on a screen of tiles.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  /// Photos are shown at most this wide, so nothing needs more than this.
  static const _maxDecodeWidth = 900;

  const AppNetworkImage(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Image(
      image: CachedNetworkImageProvider(url, maxWidth: _maxDecodeWidth),
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        if (frame == null) {
          // Not here yet: a faint tile, so the space does not look empty.
          return SizedBox(
            width: width,
            height: height,
            child: const ColoredBox(color: Color(0x0F000000)),
          );
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 250),
          builder: (context, opacity, _) =>
              Opacity(opacity: opacity, child: child),
        );
      },
    );
  }
}
