/// The tag that lets a product photo fly from its card to the product's page.
///
/// A Hero flight needs the very same tag on both ends, and the product id
/// alone will not do: the home screen shows one product on several shelves,
/// and two heroes with one tag inside a route is an error. So every card
/// keeps a tag of its own — a plain Object — and hands it over the moment it
/// is pressed. The product's page picks that tag up as it opens and flies from
/// exactly that card.
///
/// A page opened without a card — from a banner, an order, a shared link —
/// finds no handed-over tag and quietly uses the product id, which simply
/// means there is no card to fly from and the page opens the usual way.
class ProductHero {
  static final Map<String, Object> _tags = {};

  /// A card saying "a press is starting here".
  static void handOver(String productId, Object tag) {
    _tags[productId] = tag;
  }

  /// The tag the product's page should fly from, if a card is waiting.
  static Object tagFor(String productId) => _tags[productId] ?? productId;
}
