import 'package:flutter/widgets.dart';

import 'diwali_data.dart';

/// All interactive state for the Diwali page.
///
/// A plain [ChangeNotifier] (no third-party state package) means the module
/// drops into any host app without touching its dependency graph. Widgets
/// subscribe through [DiwaliScope.of] and rebuild only when values they read
/// actually change because each mutator guards against no-op updates.
class DiwaliStore extends ChangeNotifier {
  final Map<String, int> _quantities = <String, int>{};
  final Set<String> _wishlist = <String>{};

  String _query = '';
  String _address = 'Sector 32, Ludhiana';
  int _tabIndex = 0;
  int _giftChipIndex = 0;
  bool _voiceListening = false;
  bool _cartOpen = false;

  // ---- Cart -------------------------------------------------------------

  int quantityOf(DiwaliProduct product) => _quantities[product.id] ?? 0;

  void add(DiwaliProduct product) {
    final id = product.id;
    _quantities[id] = (_quantities[id] ?? 0) + 1;
    notifyListeners();
  }

  void remove(DiwaliProduct product) {
    final id = product.id;
    final current = _quantities[id] ?? 0;
    if (current <= 1) {
      _quantities.remove(id);
    } else {
      _quantities[id] = current - 1;
    }
    notifyListeners();
  }

  void clearCart() {
    if (_quantities.isEmpty) return;
    _quantities.clear();
    notifyListeners();
  }

  bool get hasCart => _quantities.isNotEmpty;

  int get cartCount =>
      _quantities.values.fold(0, (sum, qty) => sum + qty);

  /// Ordered line items for the cart sheet.
  List<({DiwaliProduct product, int quantity})> get cartLines {
    final result = <({DiwaliProduct product, int quantity})>[];
    final seen = <String>{};
    // A product can be featured in two rails; it is still one cart line.
    for (final rail in DiwaliCatalog.allRails) {
      for (final product in rail) {
        final qty = _quantities[product.id];
        if (qty != null && qty > 0 && seen.add(product.id)) {
          result.add((product: product, quantity: qty));
        }
      }
    }
    return result;
  }

  int get cartTotal {
    var total = 0;
    for (final line in cartLines) {
      total += line.product.priceValue * line.quantity;
    }
    return total;
  }

  int get cartSavings {
    var saved = 0;
    for (final line in cartLines) {
      final mrp =
          int.tryParse(line.product.mrp.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final discount = mrp - line.product.priceValue;
      if (discount > 0) saved += discount * line.quantity;
    }
    return saved;
  }

  bool get cartOpen => _cartOpen;

  void setCartOpen(bool value) {
    if (_cartOpen == value) return;
    _cartOpen = value;
    notifyListeners();
  }

  // ---- Wishlist ---------------------------------------------------------

  bool isWishlisted(DiwaliProduct product) => _wishlist.contains(product.id);

  void toggleWishlist(DiwaliProduct product) {
    if (!_wishlist.remove(product.id)) {
      _wishlist.add(product.id);
    }
    notifyListeners();
  }

  // ---- Search -----------------------------------------------------------

  String get query => _query;

  int get resultCount => DiwaliCatalog.matchCount(_query);

  void setQuery(String value) {
    final next = value.trim();
    if (_query == next) return;
    _query = next;
    notifyListeners();
  }

  void clearQuery() => setQuery('');

  List<DiwaliProduct> searchResults() {
    if (_query.isEmpty) return const <DiwaliProduct>[];
    final matches = <DiwaliProduct>[];
    final seen = <String>{};
    for (final rail in DiwaliCatalog.allRails) {
      for (final product in rail) {
        if (product.matches(_query.toLowerCase()) &&
            seen.add(product.id)) {
          matches.add(product);
        }
      }
    }
    return matches;
  }

  // ---- Header -----------------------------------------------------------

  String get address => _address;

  void setAddress(String value) {
    if (_address == value) return;
    _address = value;
    notifyListeners();
  }

  int get tabIndex => _tabIndex;

  void selectTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  int get giftChipIndex => _giftChipIndex;

  void selectGiftChip(int index) {
    if (_giftChipIndex == index) return;
    _giftChipIndex = index;
    notifyListeners();
  }

  bool get voiceListening => _voiceListening;

  void setVoiceListening(bool value) {
    if (_voiceListening == value) return;
    _voiceListening = value;
    notifyListeners();
  }
}

/// Lets any descendant read and listen to the store without a package
/// dependency. `of` registers for rebuilds; `read` does not.
class DiwaliScope extends InheritedNotifier<DiwaliStore> {
  const DiwaliScope({
    super.key,
    required DiwaliStore store,
    required super.child,
  }) : super(notifier: store);

  static DiwaliStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<DiwaliScope>();
    assert(scope != null, 'DiwaliScope is missing above this widget.');
    return scope!.notifier!;
  }

  static DiwaliStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DiwaliScope>()?.notifier;
}
