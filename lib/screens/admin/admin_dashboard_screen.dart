import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../utils/format.dart';
import '../../utils/safe_state.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/role_bottom_nav.dart';
import '../../widgets/role_common.dart';
import '../../providers/edit_mode_provider.dart';
import '../auth/login_screen.dart';
import '../main_shell.dart';
import 'admin_categories_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_users_screen.dart';
import '../../widgets/pressable.dart';

/// The admin's Home tab: platform-wide stats and a Recent Orders preview.
/// User management and the approval queues (returns/issues/sponsored
/// slots) live behind the bottom nav now, instead of five unlabeled
/// app-bar icons.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  int _productCount = 0;
  int _orderCount = 0;
  Map<String, int> _roleCounts = {};
  List<Map<String, dynamic>> _recentOrders = [];

  /// Whether the counts failed to load. Zero products and a failed count are
  /// very different things to an admin.
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    safeSetState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final client = SupabaseService.client;
      // Counted by the database — downloading every row just to count them
      // stops being accurate once a table passes the API's 1000-row limit.
      final productCount = await client.from('products').count();
      final orderCount = await client.from('orders').count();
      final sellerCount =
          await client.from('profiles').count().eq('role', 'seller');
      final deliveryCount =
          await client.from('profiles').count().eq('role', 'delivery');
      final recent = await client
          .from('orders')
          .select('id, status, total_amount, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      safeSetState(() {
        _productCount = productCount;
        _orderCount = orderCount;
        _roleCounts = {'seller': sellerCount, 'delivery': deliveryCount};
        _recentOrders = List<Map<String, dynamic>>.from(recent);
      });
    } catch (_) {
      safeSetState(() => _loadFailed = true);
    }
    safeSetState(() => _isLoading = false);
  }

  /// Opens the customer app for the admin to edit; edit mode starts off and
  /// is switched off again when they come back.
  Future<void> _openStoreEditor() async {
    final editMode = context.read<EditModeProvider>()..set(false);
    MainShell.tab.value = MainShell.home;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
    editMode.set(false);
  }

  void _goToTab(int index) {
    if (index == 0) return;
    final screen =
        index == 1 ? const AdminUsersScreen() : const AdminModerationScreen();
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
        title: Text(l10n.adminDashTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: [
          const NotificationBell(),
          Pressable(
              child: IconButton(
            icon: const Icon(Iconsax.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )),
        ],
      ),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: 0,
        onTap: _goToTab,
        items: [
          (
            outline: Iconsax.home,
            filled: Iconsax.home_copy,
            label: l10n.adminDashNavHome,
          ),
          (
            outline: Iconsax.people,
            filled: Iconsax.people,
            label: l10n.adminDashNavUsers,
          ),
          (
            outline: Iconsax.shield_tick,
            filled: Iconsax.shield_tick,
            label: l10n.adminDashNavModeration,
          ),
        ],
      ),
      body: RoleBody(
        loading: _isLoading,
        loadingMessage: l10n.adminDashLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminDashLoadFailed,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
                children: [
                  RoleStatCard(
                    label: l10n.adminDashStatProducts,
                    value: '$_productCount',
                    icon: Iconsax.shopping_bag,
                  ),
                  RoleStatCard(
                    label: l10n.adminDashStatOrders,
                    value: '$_orderCount',
                    icon: Iconsax.receipt,
                  ),
                  RoleStatCard(
                    label: l10n.adminDashStatSellers,
                    value: '${_roleCounts['seller'] ?? 0}',
                    icon: Iconsax.shop,
                  ),
                  RoleStatCard(
                    label: l10n.adminDashStatDelivery,
                    value: '${_roleCounts['delivery'] ?? 0}',
                    icon: Iconsax.truck,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _StoreEditorCard(onOpen: _openStoreEditor),
              const SizedBox(height: AppSpacing.lg),
              // The categories table drives the chips on Home and the
              // Categories tab, and the editor for it had no way in at all.
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: context.tokens.border),
                ),
                child: ListTile(
                  leading: const Icon(Iconsax.category),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  title: Text(l10n.adminDashCategories,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    l10n.adminDashCategoriesSub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminCategoriesScreen(),
                      ),
                    ).then((_) => _load());
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.adminDashRecentOrders,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_recentOrders.isEmpty)
                RoleEmptyNote(
                  icon: Iconsax.receipt,
                  message: l10n.adminDashNoOrders,
                )
              else
                ..._recentOrders.map(
                  (o) => Container(
                    margin: const EdgeInsets.only(
                      bottom: AppSpacing.listGap,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: context.tokens.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      title: Text(
                        l10n.adminDashOrderNumber(
                          (o['id'] as String).substring(0, 8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        RoleStatusChip.titled(o['status'] as String? ?? ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        formatRupees((o['total_amount'] as num?) ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
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

/// The way into the store editor: the customer app itself, with the admin's
/// pencils on everything that can be changed.
class _StoreEditorCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _StoreEditorCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadius.card,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppConstants.blackColor, Color(0xFFB84A00)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminDashEditorTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.adminDashEditorBody,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.edit, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
