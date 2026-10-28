import 'package:flutter/widgets.dart';

import 'festive_data.dart';

/// Screen state for the Diwali storefront: the selected category, the live
/// search query, the voice listening flag, the cart and the wishlist.
///
/// A plain [ChangeNotifier] behind an [InheritedNotifier] — the same pattern
/// the rest of the app uses — so only the widgets that read a value rebuild.
/// Swapping in Provider / Riverpod later means replacing [FestiveStoreScope],
/// not the widgets.
class FestiveStore extends ChangeNotifier {
  FestiveStore({int initialTab = 1}) : _tabIndex = initialTab;

  int _tabIndex;

  /// Index into `FestiveContent.categories`; the design opens on "Diwali".
  int get tabIndex => _tabIndex;
  set tabIndex(int value) {
    if (value == _tabIndex) return;
    _tabIndex = value;
    notifyListeners();
  }

  String _query = '';
  String get query => _query;
  set query(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  bool _voiceListening = false;
  bool get voiceListening => _voiceListening;
  set voiceListening(bool value) {
    if (value == _voiceListening) return;
    _voiceListening = value;
    notifyListeners();
  }

  final Map<String, FestiveProduct> _cart = <String, FestiveProduct>{};
  final Map<String, int> _quantities = <String, int>{};
  final Set<String> _wishlist = <String>{};

  List<FestiveProduct> get cartLines => _cart.values.toList(growable: false);
  Iterable<String> get wishlistIds => _wishlist;
  bool get hasCart => _cart.isNotEmpty;

  int get cartCount =>
      _quantities.values.fold<int>(0, (int sum, int qty) => sum + qty);

  int get cartTotal => _cart.entries.fold<int>(
        0,
        (int sum, MapEntry<String, FestiveProduct> e) =>
            sum + e.value.price * (_quantities[e.key] ?? 0),
      );

  int get cartSavings => _cart.entries.fold<int>(
        0,
        (int sum, MapEntry<String, FestiveProduct> e) =>
            sum + (e.value.mrp - e.value.price) * (_quantities[e.key] ?? 0),
      );

  int quantityOf(FestiveProduct product) => _quantities[product.id] ?? 0;

  bool isWishlisted(FestiveProduct product) => _wishlist.contains(product.id);

  void add(FestiveProduct product) {
    _cart[product.id] = product;
    _quantities[product.id] = (_quantities[product.id] ?? 0) + 1;
    notifyListeners();
  }

  void remove(FestiveProduct product) {
    final int next = (_quantities[product.id] ?? 0) - 1;
    if (next <= 0) {
      _quantities.remove(product.id);
      _cart.remove(product.id);
    } else {
      _quantities[product.id] = next;
    }
    notifyListeners();
  }

  void removeLine(FestiveProduct product) {
    _quantities.remove(product.id);
    _cart.remove(product.id);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _quantities.clear();
    notifyListeners();
  }

  /// Returns the new wishlist state so the caller can animate the heart.
  bool toggleWishlist(FestiveProduct product) {
    final bool added = _wishlist.add(product.id);
    if (!added) _wishlist.remove(product.id);
    notifyListeners();
    return added;
  }

  /// Everything the search sheet can find, de-duplicated by id.
  late final List<FestiveProduct> allProducts = <String, FestiveProduct>{
    for (final FestiveRail rail in FestiveContent.rails)
      for (final FestiveProduct product in rail.products) product.id: product,
  }.values.toList(growable: false);

  List<FestiveProduct> resultsFor(String rawQuery) {
    final String q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return allProducts.take(6).toList(growable: false);
    return allProducts
        .where((FestiveProduct p) =>
            p.name.toLowerCase().contains(q) ||
            p.unit.toLowerCase().contains(q))
        .toList(growable: false);
  }
}

/// `InheritedNotifier` so descendants rebuild when the store changes, without
/// a rebuild of the whole page.
class FestiveStoreScope extends InheritedNotifier<FestiveStore> {
  const FestiveStoreScope({
    super.key,
    required FestiveStore store,
    required super.child,
  }) : super(notifier: store);

  static FestiveStore of(BuildContext context) {
    final FestiveStoreScope? scope =
        context.dependOnInheritedWidgetOfExactType<FestiveStoreScope>();
    assert(scope != null, 'FestiveStoreScope is missing above this widget.');
    return scope!.notifier!;
  }
}
