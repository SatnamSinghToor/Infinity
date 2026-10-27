import 'package:flutter/material.dart';
import 'app_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../utils/constants.dart';

/// The product's photos: a column of thumbnails on the left (when there is
/// more than one photo) and the chosen photo big in a rounded card beside it.
/// Swiping the big photo or tapping a thumbnail changes it. With no photo it
/// shows [placeholder] in the same card.
class ProductGallery extends StatefulWidget {
  final List<String> urls;
  final Widget? placeholder;

  /// Handed over by the card this page was opened from: the big photo then
  /// flies out of that card into this frame instead of just appearing.
  final Object? heroTag;

  const ProductGallery({
    super.key,
    required this.urls,
    this.placeholder,
    this.heroTag,
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  static const _height = 340.0;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _photo(String url) {
    return AppNetworkImage(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(Iconsax.gallery, size: 40, color: Colors.grey[400]),
      ),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    final hasThumbs = urls.length > 1;

    return Container(
      width: double.infinity,
      color: AppConstants.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SizedBox(
        height: _height,
        child: Row(
          children: [
            if (hasThumbs) ...[
              SizedBox(
                width: 76,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    child: Container(
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: i == _page
                              ? AppConstants.primaryColor
                              : const Color(0xFFE4E4E4),
                          width: i == _page ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(3),
                      child: AppNetworkImage(
                        urls[i],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E4E4)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _frame(urls),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The photo inside the frame. The one on show carries the hero tag, so the
  /// flight is between the card and the big frame and nothing else.
  Widget _frame(List<String> urls) {
    if (urls.isEmpty) {
      final empty = widget.placeholder ?? const SizedBox.shrink();
      return _flight(empty);
    }
    return PageView.builder(
      controller: _controller,
      itemCount: urls.length,
      onPageChanged: (i) => setState(() => _page = i),
      itemBuilder: (_, i) {
        final page = Padding(
          padding: const EdgeInsets.all(8),
          child: _photo(urls[i]),
        );
        return i == _page ? _flight(page) : page;
      },
    );
  }

  Widget _flight(Widget child) {
    final tag = widget.heroTag;
    if (tag == null) return child;
    return Hero(tag: tag, child: child);
  }
}
