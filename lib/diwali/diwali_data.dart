import 'diwali_config.dart';

/// Immutable content models for the Diwali storefront.
///
/// Keeping copy and imagery in one file means a content edit never touches a
/// widget, and the whole page can be driven by a CMS later by swapping these
/// const lists for a repository.

/// A single product card. [price] and [mrp] keep their display formatting
/// (`₹1,499`) while [priceValue] gives the cart a plain integer.
class DiwaliProduct {
  const DiwaliProduct({
    required this.name,
    required this.image,
    required this.qty,
    required this.price,
    required this.mrp,
    this.offer = '',
    this.highlight = false,
    this.chip = '',
    this.rating = 0,
    this.reviews = '',
    this.time = '16 mins',
    this.stock = '',
    this.isAd = false,
    this.badge = '',
    this.similar = true,
    this.variants = '',
  });

  final String name;
  final String image;
  final String qty;
  final String price;
  final String mrp;
  final String offer;
  final bool highlight;
  final String chip;
  final int rating;
  final String reviews;
  final String time;
  final String stock;
  final bool isAd;
  final String badge;
  final bool similar;
  final String variants;

  String get asset => '$kDiwaliAssetRoot/$image.jpg';

  int get priceValue =>
      int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// Stable identity for the cart even when two rails show the same item.
  String get id => '$image|$name';

  bool matches(String query) =>
      query.isEmpty || name.toLowerCase().contains(query);
}

/// An arch-shaped editorial card inside a banner.
class DiwaliArchItem {
  const DiwaliArchItem(this.image, this.title, this.subtitle);

  final String image;
  final String title;
  final String subtitle;

  String get asset => '$kDiwaliAssetRoot/$image.jpg';
}

/// A small square category tile (outfit, pooja, festive home…).
class DiwaliTile {
  const DiwaliTile(this.image, this.label);

  final String image;
  final String label;

  String get asset => '$kDiwaliAssetRoot/$image.jpg';
}

/// A diamond-shaped "Diyas & Candles" entry.
class DiwaliDiamond {
  const DiwaliDiamond(this.image, this.label);

  final String image;
  final String label;

  String get asset => '$kDiwaliAssetRoot/$image.jpg';
}

class DiwaliCalendarItem {
  const DiwaliCalendarItem(this.image, this.day, this.month, this.label);

  final String image;
  final String day;
  final String month;
  final String label;

  String get asset => '$kDiwaliAssetRoot/$image.jpg';
}

class DiwaliBrand {
  const DiwaliBrand(this.image, this.name, this.logo);

  final String image;
  final String name;
  final String logo;

  String get asset => '$kDiwaliAssetRoot/$image.jpg';
}

class DiwaliGiftChip {
  const DiwaliGiftChip(this.image, this.label, {this.selected = false});

  final String image;
  final String label;
  final bool selected;

  String get asset => '$kDiwaliAssetRoot/$image.jpg';
}

/// The six tabs in the festive header.
enum DiwaliTabIcon { all, diya, party, electronics, beauty, gift }

class DiwaliTab {
  const DiwaliTab(this.label, this.icon);

  final String label;
  final DiwaliTabIcon icon;
}

class DiwaliCatalog {
  const DiwaliCatalog._();

  static const List<DiwaliTab> tabs = [
    DiwaliTab('All', DiwaliTabIcon.all),
    DiwaliTab('Diwali', DiwaliTabIcon.diya),
    DiwaliTab('Party', DiwaliTabIcon.party),
    DiwaliTab('Electronics', DiwaliTabIcon.electronics),
    DiwaliTab('Beauty', DiwaliTabIcon.beauty),
    DiwaliTab('Gifting', DiwaliTabIcon.gift),
  ];

  /// Hero arch tiles, in reading order.
  static const List<DiwaliTile> heroTiles = [
    DiwaliTile('diya-3', 'Lights, Diya & Decor'),
    DiwaliTile('decor-3', 'Home Makeover'),
    DiwaliTile('hamper-1', 'Sweets & Hampers'),
    DiwaliTile('hamper-2', 'Diwali Gift Shop'),
    DiwaliTile('appliance-1', 'Appliances & Gadgets'),
    DiwaliTile('ethnic-2', 'Festive Ready'),
  ];

  static const List<DiwaliProduct> festiveVibes = [
    DiwaliProduct(
      name: 'Decorated Clay Divine Diya Set by Aravi',
      image: 'diya-3',
      qty: '12 pcs',
      price: '₹189',
      mrp: '₹350',
      offer: 'Price Drop',
      highlight: true,
      chip: '2" x 2"',
    ),
    DiwaliProduct(
      name: 'Decorated Clay Diya Set by House Of Festivals',
      image: 'diya-2',
      qty: '3 pcs',
      price: '₹179',
      mrp: '₹350',
      offer: '₹171 OFF',
      chip: '3.1"',
    ),
    DiwaliProduct(
      name: 'Decorated Clay Dual Shaded Diya Set by Aravi',
      image: 'diya-4',
      qty: '12 pcs',
      price: '₹189',
      mrp: '₹350',
      offer: 'Price Drop',
      highlight: true,
      chip: '2.5" x 2.5" x 0.8"',
    ),
    DiwaliProduct(
      name: 'Hand Painted Clay Diya Set by House Of Festivals',
      image: 'diya-1',
      qty: '12 pcs',
      price: '₹199',
      mrp: '₹399',
      offer: '50% OFF',
      chip: '4 cm',
    ),
    DiwaliProduct(
      name: 'Kuber Deepak Oil Lamp Set by Aravi',
      image: 'diya-5',
      qty: '21 pcs',
      price: '₹149',
      mrp: '₹299',
      offer: '₹150 OFF',
      chip: 'Cotton wicks',
    ),
  ];

  static const List<DiwaliProduct> entrance = [
    DiwaliProduct(
      name: 'Urli Soy Wax Candle Set (Vanilla, Oudh) by Auradecor',
      image: 'urli-1',
      qty: '2 pcs',
      price: '₹565',
      mrp: '₹2,500',
      offer: '₹600 OFF',
      chip: 'Soy Wax',
      rating: 4,
      reviews: '362',
      stock: '1 left',
    ),
    DiwaliProduct(
      name: 'Elegant Urli Bowl for Festive & Pooja Decor',
      image: 'urli-3',
      qty: '1 pc',
      price: '₹399',
      mrp: '₹999',
      offer: '₹600 OFF',
      chip: 'Metal | 10" x 10"',
      rating: 4,
      reviews: '82',
      stock: '2 left',
    ),
    DiwaliProduct(
      name: 'Urli Scented Candle (Myrrh & Amber) Set by Pa',
      image: 'candle-2',
      qty: '3 pcs',
      price: '₹399',
      mrp: '₹899',
      offer: '₹500 OFF',
      chip: 'Soy Wax',
    ),
    DiwaliProduct(
      name: 'Flower Shaped Urli Stand Set - Aksharveda',
      image: 'urli-2',
      qty: '2 pcs',
      price: '₹449',
      mrp: '₹700',
      offer: '₹251 OFF',
      chip: 'Steel',
    ),
    DiwaliProduct(
      name: 'Ganesha Shadow Diyas with Attached Stand',
      image: 'brassdiya-5',
      qty: '1 pc',
      price: '₹279',
      mrp: '₹450',
      offer: '₹171 OFF',
      chip: 'Steel',
    ),
    DiwaliProduct(
      name: 'Lotus Diya Standing Urli Bowl Set',
      image: 'urli-5',
      qty: '2 pcs',
      price: '₹599',
      mrp: '₹1,000',
      offer: '₹401 OFF',
      chip: 'Steel',
    ),
  ];

  static const List<DiwaliProduct> gifts = [
    DiwaliProduct(
      name: 'Ferrero Rocher Golden Diya Chocolate Gift Pack',
      image: 'chocolate-1',
      qty: '200 g',
      price: '₹999',
      mrp: '₹1,499',
      offer: '₹500 OFF',
      badge: 'Limited edition',
    ),
    DiwaliProduct(
      name: 'Orika Grill & Chill Diwali Gift Box with Marinades',
      image: 'hamper-4',
      qty: '76 g',
      price: '₹499',
      mrp: '₹799',
      offer: '₹300 OFF',
      badge: 'GIFT READY BOX',
      stock: '2 left',
    ),
    DiwaliProduct(
      name: 'Cadbury Celebrations Kesar Pista Milky Mithai',
      image: 'chocolate-5',
      qty: '108 g',
      price: '₹229',
      mrp: '₹300',
      offer: '23% OFF on MRP',
    ),
    DiwaliProduct(
      name: 'Luxury Diwali Hamper with Dry Fruits & Chocolates',
      image: 'hamper-1',
      qty: '1 box',
      price: '₹799',
      mrp: '₹1,299',
      offer: '₹500 OFF',
    ),
    DiwaliProduct(
      name: 'Assorted Chocolate & Sweet Celebration Box',
      image: 'chocolate-3',
      qty: '93 g',
      price: '₹349',
      mrp: '₹499',
      offer: '30% OFF',
    ),
  ];

  static const List<DiwaliProduct> lights = [
    DiwaliProduct(
      name: 'Warm White 10 m Pixel Light by WAAN',
      image: 'lights-1',
      qty: '36 Bulbs',
      price: '₹69',
      mrp: '₹299',
      offer: 'Price Drop',
      highlight: true,
      chip: 'Adapter',
      variants: '3 options',
      rating: 4,
      reviews: '3,836',
      similar: false,
    ),
    DiwaliProduct(
      name: 'Warm White 2.5 x 0.7 m Star Curtain String Lights',
      image: 'lights-2',
      qty: '96 Bulbs',
      price: '₹319',
      mrp: '₹799',
      chip: '12 pcs | 2 Pin Plug',
      rating: 4,
      reviews: '149',
      similar: false,
    ),
    DiwaliProduct(
      name: 'Multicolour 10 m Pixel Light by WAAN',
      image: 'lights-3',
      qty: '36 Bulbs',
      price: '₹79',
      mrp: '₹299',
      offer: 'Price Drop',
      highlight: true,
      variants: '2 options',
      rating: 4,
      reviews: '546',
      similar: false,
    ),
    DiwaliProduct(
      name: 'Copper Wire Fairy String Lights with Remote',
      image: 'lights-4',
      qty: '100 LED',
      price: '₹249',
      mrp: '₹699',
      offer: '64% OFF',
      variants: '2 options',
      rating: 4,
      reviews: '1,204',
      similar: false,
    ),
    DiwaliProduct(
      name: 'Globe String Lights Warm White (USB)',
      image: 'lights-5',
      qty: '40 LED',
      price: '₹199',
      mrp: '₹499',
      offer: '60% OFF',
      rating: 4,
      reviews: '918',
      similar: false,
    ),
  ];

  static const List<DiwaliProduct> warmth = [
    DiwaliProduct(
      name: 'Pearl & Bead Door Hanging with Bell - Satvik',
      image: 'toran-1',
      qty: '2 pcs',
      price: '₹299',
      mrp: '₹799',
      offer: '₹500 OFF',
      chip: 'Plastic | 54" x 2"',
    ),
    DiwaliProduct(
      name: 'Flower Shaped Urli Stand Set - Aksharveda',
      image: 'urli-2',
      qty: '2 pcs',
      price: '₹449',
      mrp: '₹700',
      offer: '₹251 OFF',
      chip: 'Steel',
    ),
    DiwaliProduct(
      name: 'Urli Scented Candle (Myrrh & Amber) Set',
      image: 'candle-4',
      qty: '3 pcs',
      price: '₹399',
      mrp: '₹899',
      offer: '₹500 OFF',
      chip: 'Soy Wax',
    ),
    DiwaliProduct(
      name: 'Marigold Toran with Bells for Entrance',
      image: 'toran-2',
      qty: '1 pc',
      price: '₹349',
      mrp: '₹699',
      offer: '50% OFF',
      chip: '5 ft',
    ),
    DiwaliProduct(
      name: 'Designer Tealight Candle Gift Set',
      image: 'candle-5',
      qty: '8 pcs',
      price: '₹279',
      mrp: '₹599',
      offer: '₹320 OFF',
      chip: 'Unscented',
    ),
  ];

  static const List<DiwaliProduct> celebrations = [
    DiwaliProduct(
      name: 'Shubh Labh Swastik & Charan Sticker (Gold)',
      image: 'rangoli-2',
      qty: '6 pcs',
      price: '₹79',
      mrp: '₹199',
      offer: '₹120 OFF',
    ),
    DiwaliProduct(
      name: 'Lakshmi Charan Sticker (Red) - DiaCraft',
      image: 'rangoli-3',
      qty: '10 pcs',
      price: '₹49',
      mrp: '₹100',
      offer: '51% OFF on MRP',
    ),
    DiwaliProduct(
      name: 'Divine Footprints Mandala Floor Sticker',
      image: 'rangoli-1',
      qty: '1 pc',
      price: '₹51',
      mrp: '₹249',
      offer: '₹198 OFF',
    ),
    DiwaliProduct(
      name: 'Colourful Acrylic Rangoli Set for Floor Decor',
      image: 'rangoli-4',
      qty: '38 pcs',
      price: '₹199',
      mrp: '₹599',
      offer: '66% OFF',
    ),
    DiwaliProduct(
      name: 'Lotus Rangoli Floor Stickers - Self Adhesive',
      image: 'rangoli-5',
      qty: '11 pcs',
      price: '₹149',
      mrp: '₹399',
      offer: '62% OFF',
    ),
  ];

  static const List<DiwaliProduct> corner = [
    DiwaliProduct(
      name: 'myTrident Comfort Living Hand Towel 400 GSM',
      image: 'towel-1',
      qty: '2 pcs',
      price: '₹199',
      mrp: '₹399',
      chip: 'Red',
      rating: 5,
      reviews: '1,012',
      isAd: true,
      similar: false,
    ),
    DiwaliProduct(
      name: 'Rooted Single Red Rose Dried Flower Bouquet',
      image: 'rose-2',
      qty: 'Dried',
      price: '₹119',
      mrp: '₹299',
      chip: '1 Stem',
      rating: 4,
      reviews: '6,014',
      similar: false,
    ),
    DiwaliProduct(
      name: 'myTrident Comfort Living Hand Towel 400 GSM',
      image: 'towel-3',
      qty: '2 pcs',
      price: '₹199',
      mrp: '₹399',
      offer: 'Half Price',
      chip: '400 GSM',
      rating: 4,
      reviews: '1,232',
      stock: '1 left',
      isAd: true,
      similar: false,
    ),
    DiwaliProduct(
      name: 'Artificial Red Rose Bouquet in Ceramic Vase',
      image: 'rose-3',
      qty: '1 pc',
      price: '₹449',
      mrp: '₹899',
      offer: '50% OFF',
      chip: 'Ceramic',
      rating: 4,
      reviews: '814',
      similar: false,
    ),
    DiwaliProduct(
      name: 'Premium Cotton Hand Towel Gift Set',
      image: 'towel-2',
      qty: '3 pcs',
      price: '₹299',
      mrp: '₹599',
      offer: '50% OFF',
      chip: '100% Cotton',
      rating: 4,
      reviews: '2,106',
      similar: false,
    ),
  ];

  static const List<DiwaliProduct> rituals = [
    DiwaliProduct(
      name: 'Shri Ram Darbar Photo Frame for Pooja',
      image: 'pooja-1',
      qty: '1 pc',
      price: '₹199',
      mrp: '₹399',
      offer: '50% OFF',
      chip: '8.6 inch',
    ),
    DiwaliProduct(
      name: 'Loban Cups & Dhoop for Daily Pooja',
      image: 'brassdiya-1',
      qty: '12 pcs',
      price: '₹99',
      mrp: '₹199',
      offer: '50% OFF',
      chip: 'Herbal',
    ),
    DiwaliProduct(
      name: 'Panchmeva Hawan Samagri with Pooja Kit',
      image: 'pooja-3',
      qty: '1 kit',
      price: '₹149',
      mrp: '₹299',
      offer: '50% OFF',
      chip: '200 g',
    ),
    DiwaliProduct(
      name: 'Classic Kaju Katli Indian Mithai Gift Box',
      image: 'sweets-1',
      qty: '200 g',
      price: '₹249',
      mrp: '₹399',
      offer: '₹150 OFF',
      chip: 'Cashew',
    ),
    DiwaliProduct(
      name: 'Traditional Brass Akhand Diya with Glass Cover',
      image: 'brassdiya-3',
      qty: '1 pc',
      price: '₹299',
      mrp: '₹599',
      offer: '50% OFF',
      chip: 'Brass',
    ),
  ];

  static const List<DiwaliArchItem> festiveShopping = [
    DiwaliArchItem('decor-2', 'Festive Home', 'Set your space aglow'),
    DiwaliArchItem('hamper-3', 'Hosting Ready', 'Serve up a festive feast'),
    DiwaliArchItem('sweets-2', 'Sweet Shop', 'Savour tempting treats'),
    DiwaliArchItem('hamper-5', 'Gifting Corner', 'Gifts for your loved ones'),
  ];

  static const List<DiwaliArchItem> vibrantDecor = [
    DiwaliArchItem('decor-1', 'Table Styling', 'Get urli, flowers & more'),
    DiwaliArchItem('rangoli-4', 'Floor Decor', 'Rangoli colours & stickers'),
    DiwaliArchItem('decor-4', 'Festive Corners', 'Make every nook shine'),
    DiwaliArchItem('glasses-2', 'Dining Edit', 'Serve in style'),
  ];

  static const List<DiwaliArchItem> diwaliGifting = [
    DiwaliArchItem('hamper-1', 'Festive Gifts', 'Find the perfect surprise'),
    DiwaliArchItem('decor-5', 'Home & Living', 'Gifts that feel like home'),
    DiwaliArchItem('appliance-2', 'Electronics', 'Smart little surprises'),
  ];

  static const List<DiwaliGiftChip> giftChips = [
    DiwaliGiftChip('hamper-1', 'Artisanal\ngift boxes', selected: true),
    DiwaliGiftChip('candle-1', 'Aroma &\nDiffusers'),
    DiwaliGiftChip('appliance-1', 'Appliances'),
    DiwaliGiftChip('chocolate-4', 'Gift\n& Kits'),
    DiwaliGiftChip('appliance-3', 'Audio &\nAccessories'),
  ];

  static const List<DiwaliDiamond> diyasAndCandles = [
    DiwaliDiamond('rangoli-2', 'Designer Diya'),
    DiwaliDiamond('brassdiya-3', 'Akhand Diya'),
    DiwaliDiamond('candle-1', 'Tealight Candles'),
    DiwaliDiamond('candle-5', 'Floating Candles'),
    DiwaliDiamond('brassdiya-2', 'Brass Diya'),
    DiwaliDiamond('candle-3', 'Wax Diya'),
    DiwaliDiamond('candle-4', 'Pillar Candles'),
    DiwaliDiamond('candle-2', 'Jar Candles'),
  ];

  static const List<DiwaliCalendarItem> calendar = [
    DiwaliCalendarItem('urli-3', '29', 'OCT', 'Karwa Chauth'),
    DiwaliCalendarItem('pooja-1', '1', 'NOV', 'Ahoi Ashtami'),
    DiwaliCalendarItem('sweets-3', 'N', 'OV', 'Dhanteras'),
  ];

  static const List<DiwaliBrand> brands = [
    DiwaliBrand('glasses-1', 'Nestasia', 'nestasia'),
    DiwaliBrand('decor-5', 'Chumbak', 'CHUMBAK'),
    DiwaliBrand('chocolate-1', 'Ferrero', 'Ferrero'),
  ];

  static const List<DiwaliTile> festiveHome = [
    DiwaliTile('decor-5', 'Home Makeover'),
    DiwaliTile('decor-2', 'Artful Decor'),
    DiwaliTile('rose-3', 'Flowers & Vases'),
    DiwaliTile('glasses-1', 'Dining Essentials'),
  ];

  static const List<DiwaliTile> diwaliOutfit = [
    DiwaliTile('ethnic-1', 'Kurta & Saree'),
    DiwaliTile('ethnic-2', 'Jewellery'),
    DiwaliTile('beauty-1', 'Makeup Essentials'),
    DiwaliTile('beauty-2', 'Haircare & Skincare'),
  ];

  static const List<DiwaliTile> poojaEssentials = [
    DiwaliTile('pooja-1', 'Idols & Photos'),
    DiwaliTile('brassdiya-1', 'Hawan Needs'),
    DiwaliTile('sweets-1', 'Indian Sweets'),
    DiwaliTile('pooja-4', 'Mandir Decor'),
  ];

  /// Every rail, in page order — used by search to compute a result count.
  static const List<List<DiwaliProduct>> allRails = [
    festiveVibes,
    entrance,
    gifts,
    lights,
    warmth,
    celebrations,
    corner,
    rituals,
  ];

  static int matchCount(String query) {
    if (query.isEmpty) return -1;
    final needle = query.toLowerCase();
    var total = 0;
    for (final rail in allRails) {
      for (final product in rail) {
        if (product.matches(needle)) total++;
      }
    }
    return total;
  }
}
