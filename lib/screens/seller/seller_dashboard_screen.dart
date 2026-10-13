import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import '../../widgets/app_network_image.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/notification_bell.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/format.dart';
import '../../utils/safe_state.dart';
import '../../widgets/role_bottom_nav.dart';
import '../../widgets/role_common.dart';
import 'add_product_screen.dart';
import 'seller_more_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_product_detail_screen.dart';
import 'seller_products_screen.dart';
import 'store_profile_screen.dart';
import '../../widgets/pressable.dart';

/// The seller's Home tab: a quick-glance overview (stats, alerts, quick
/// actions, short previews of products/orders) plus a bottom nav to the
/// full Products, Orders, and More screens. Deep product/order management
/// lives in those dedicated screens now, not crammed into this one.
class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orders = [];
  double? _avgRating;
  int _ratingCount = 0;
  double _netEarnings = 0;

  /// Every order the store has had, newest first; the recent list shows
  /// the first few and the chart the last week of them.
  int _orderCount = 0;

  /// Whether the last load failed. Told apart from "nothing here", because a
  /// seller on a weak connection must not be shown an empty shop.
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final products = await SupabaseService.client
          .from('products')
          .select(
            'id, name, price, stock, is_active, image_url, image_urls, '
            'categories(name)',
          )
          .eq('seller_id', userId)
          .order('created_at', ascending: false);
      final orders = await SupabaseService.client
          .from('orders')
          .select('id, status, total_amount, created_at, seller_payout')
          .eq('seller_id', userId)
          .order('created_at', ascending: false)
          .limit(1000);

      final productIds =
          products.map((p) => p['id'] as String).toList(growable: false);
      List<Map<String, dynamic>> reviews = [];
      if (productIds.isNotEmpty) {
        reviews = List<Map<String, dynamic>>.from(
          await SupabaseService.client
              .from('reviews')
              .select('rating')
              .inFilter('product_id', productIds),
        );
      }

      safeSetState(() {
        _products = List<Map<String, dynamic>>.from(products);
        _orders = List<Map<String, dynamic>>.from(orders);
        _orderCount = _orders.length;
        _ratingCount = reviews.length;
        _avgRating = reviews.isEmpty
            ? null
            : reviews.fold<num>(0, (sum, r) => sum + (r['rating'] as num)) /
                reviews.length;
        _netEarnings =
            _orders.where((o) => o['status'] == 'delivered').fold<double>(
                  0,
                  (sum, o) =>
                      sum + ((o['seller_payout'] as num?)?.toDouble() ?? 0),
                );
      });
    } catch (_) {
      // Remember it: the screen says so, and offers to try again, instead of
      // looking like a shop with nothing in it.
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  int _stockOf(Map<String, dynamic> p) => (p['stock'] as num?)?.toInt() ?? 0;

  int get _soldOutCount => _products.where((p) => _stockOf(p) <= 0).length;

  /// Still on sale, but five or fewer left.
  int get _lowStockCount => _products.where((p) {
        final stock = _stockOf(p);
        return stock > 0 && stock <= 5;
      }).length;

  /// What each of the last seven days sold, oldest first, today last.
  /// Cancelled orders never count as a sale.
  List<double> get _weekSales {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = List<double>.filled(7, 0);
    for (final o in _orders) {
      if (o['status'] == 'cancelled') continue;
      final at = DateTime.tryParse(o['created_at'] as String? ?? '');
      if (at == null) continue;
      final ago = today.difference(DateUtils.dateOnly(at.toLocal())).inDays;
      if (ago < 0 || ago > 6) continue;
      days[6 - ago] += (o['total_amount'] as num?)?.toDouble() ?? 0;
    }
    return days;
  }

  /// How many products the store has in each category, most first.
  List<(String, int)> get _categoryCounts {
    final counts = <String, int>{};
    for (final p in _products) {
      final name =
          ((p['categories'] as Map?)?['name'] as String?)?.trim() ?? '';
      final key = name.isEmpty ? '—' : name;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final list = [for (final e in counts.entries) (e.key, e.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return list;
  }

  Future<void> _addProduct() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (saved == true) _load();
  }

  void _goToTab(int index) {
    if (index == 0) return;
    Widget screen;
    switch (index) {
      case 1:
        screen = const SellerProductsScreen();
        break;
      case 2:
        screen = const SellerOrdersScreen();
        break;
      default:
        screen = const SellerMoreScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      extendBody: true,
      appBar: GradientAppBar(
        title: Text(l10n.sellerDashTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: const [NotificationBell()],
      ),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: 0,
        onTap: _goToTab,
        items: [
          (
            outline: Iconsax.home,
            filled: Iconsax.home_copy,
            label: l10n.sellerDashNavHome,
          ),
          (
            outline: Iconsax.shopping_bag,
            filled: Iconsax.shopping_bag,
            label: l10n.sellerDashNavProducts,
          ),
          (
            outline: Iconsax.receipt,
            filled: Iconsax.receipt_copy,
            label: l10n.sellerDashNavOrders,
          ),
          (
            outline: Iconsax.profile_circle,
            filled: Iconsax.profile_circle,
            label: l10n.sellerDashNavMore,
          ),
        ],
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.sellerDashLoading,
        failed: _loadFailed,
        errorTitle: l10n.sellerDashLoadFailed,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Text(
                l10n.sellerDashHi(auth.userName),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.sellerDashSub,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.75,
                children: [
                  _StatTile(
                    label: l10n.sellerDashStatOrders,
                    value: '$_orderCount',
                    icon: Iconsax.receipt_2,
                    tint: const Color(0xFF3F7EF7),
                    onTap: () => _goToTab(2),
                  ),
                  _StatTile(
                    label: l10n.sellerDashStatProducts,
                    value: '${_products.length}',
                    icon: Iconsax.box,
                    tint: const Color(0xFF8E5CF7),
                    onTap: () => _goToTab(1),
                  ),
                  _StatTile(
                    label: l10n.sellerDashBalance,
                    value: formatRupees(_netEarnings),
                    icon: Iconsax.wallet_3,
                    tint: const Color(0xFF1E9E6A),
                    onTap: () => _goToTab(3),
                  ),
                  _StatTile(
                    label: _avgRating == null
                        ? l10n.sellerDashNoReviews
                        : l10n.sellerDashReviewCount(_ratingCount),
                    value: _avgRating?.toStringAsFixed(1) ?? '—',
                    icon: Iconsax.star_1,
                    tint: const Color(0xFFF2A516),
                    onTap: () => _goToTab(3),
                  ),
                  _StatTile(
                    label: l10n.sellerDashSoldOut,
                    value: '$_soldOutCount',
                    icon: Iconsax.box_remove,
                    tint: const Color(0xFFE5484D),
                    onTap: () => _goToTab(1),
                  ),
                  _StatTile(
                    label: l10n.sellerDashLowStockTile,
                    value: '$_lowStockCount',
                    icon: Iconsax.warning_2,
                    tint: AppConstants.primaryColor,
                    onTap: () => _goToTab(1),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _WeekSalesCard(sales: _weekSales),
              if (_products.isNotEmpty) ...[
                const SizedBox(height: 14),
                _CategoryCountCard(counts: _categoryCounts),
              ],
              const SizedBox(height: 22),
              Text(
                l10n.sellerDashQuickActions,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Iconsax.add_square,
                      label: l10n.sellerDashAddProduct,
                      onTap: _addProduct,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Iconsax.box_tick,
                      label: l10n.sellerDashStatOrders,
                      onTap: () => _goToTab(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Iconsax.shop,
                      label: l10n.sellerDashStore,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreProfileScreen(),
                        ),
                      ).then((_) => _load()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.sellerDashMyProducts,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Pressable(
                      child: TextButton(
                    onPressed: () => _goToTab(1),
                    child: Text(l10n.sellerDashViewAll,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                ],
              ),
              const SizedBox(height: 8),
              if (_products.isEmpty)
                RoleEmpty(
                  icon: Iconsax.shopping_bag,
                  title: l10n.sellerDashNoProducts,
                  message: l10n.sellerDashNoProductsBody,
                )
              else
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _products.length.clamp(0, 8),
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      final imageUrl = p['image_url'] as String?;
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SellerProductDetailScreen(product: p),
                          ),
                        ).then((_) => _load()),
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 84,
                                  height: 64,
                                  child: (imageUrl == null || imageUrl.isEmpty)
                                      ? Container(
                                          color: AppConstants.accentColor
                                              .withValues(alpha: 0.3),
                                        )
                                      : ColoredBox(
                                          color: Colors.white,
                                          child: AppNetworkImage(
                                            imageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: AppConstants.accentColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p['name'] as String? ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formatRupees((p['price'] as num?) ?? 0),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.sellerDashRecentOrders,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Pressable(
                      child: TextButton(
                    onPressed: () => _goToTab(2),
                    child: Text(l10n.sellerDashViewAll,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
                ],
              ),
              const SizedBox(height: 8),
              if (_orders.isEmpty)
                RoleEmptyNote(
                  icon: Iconsax.receipt,
                  message: l10n.sellerDashNoOrdersBody,
                )
              else
                ..._orders.take(5).map(
                      (o) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            l10n.sellerDashOrderNumber(
                              (o['id'] as String).substring(0, 8),
                            ),
                          ),
                          subtitle: Text(o['status'] as String? ?? ''),
                          trailing: Text(
                              formatRupees((o['total_amount'] as num?) ?? 0)),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
        child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppConstants.primaryColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ));
  }
}

/// One of the dashboard's six figures: a tinted icon, the number, and what
/// it counts. Tapping it opens the list behind the number.
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.2,
                        color: AppConstants.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last seven days' sales as bars, today on the right, with the
/// week's total over them.
class _WeekSalesCard extends StatelessWidget {
  final List<double> sales;

  const _WeekSalesCard({required this.sales});

  static String _short(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = sales.fold<double>(0, (a, b) => a + b);
    final top = sales.fold<double>(0, (a, b) => b > a ? b : a);
    final today = DateUtils.dateOnly(DateTime.now());
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sellerDashWeekSales,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.sellerDashWeekTotal(formatRupees(total)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppConstants.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              sales[i] > 0 ? _short(sales[i]) : '',
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: top <= 0 ? 0 : sales[i] / top,
                            ),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (_, f, __) => Container(
                              height: 4 + 96 * f,
                              decoration: BoxDecoration(
                                color: i == 6
                                    ? AppConstants.primaryColor
                                    : AppConstants.primaryColor
                                        .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            days[today.subtract(Duration(days: 6 - i)).weekday -
                                1],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  i == 6 ? FontWeight.w800 : FontWeight.w500,
                              color: AppConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How many products sit in each category, as bars against the biggest.
class _CategoryCountCard extends StatelessWidget {
  final List<(String, int)> counts;

  const _CategoryCountCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top = counts.isEmpty ? 1 : counts.first.$2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sellerDashCategoryCount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final (name, count) in counts.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: count / top,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFEFEFEF),
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 26,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
