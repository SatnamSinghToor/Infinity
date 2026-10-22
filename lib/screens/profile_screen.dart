import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../providers/wishlist_provider.dart';
import '../utils/constants.dart';
import '../utils/tokens.dart';
import '../widgets/night_sky.dart';
import '../widgets/role_common.dart';
import 'help_screens.dart';
import 'main_shell.dart';
import 'auth/login_screen.dart';
import 'address_management_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'payment_methods_screen.dart';
import 'root_router.dart';
import 'wallet_screen.dart';
import 'wishlist_screen.dart';
import '../widgets/pressable.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppConstants.backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back goes to the store, as this page is a tab.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                  children: [
                    Pressable(
                        child: IconButton(
                      onPressed: () => MainShell.tab.value = MainShell.home,
                      icon: const Icon(Icons.arrow_back_rounded, size: 24),
                    )),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.profileTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // The size every other screen's title has.
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _LoggedInView(authProvider: authProvider)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoggedInView extends StatelessWidget {
  final AuthProvider authProvider;

  const _LoggedInView({required this.authProvider});

  Future<void> _pickAvatar(BuildContext context, AuthProvider auth) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;
    final ok = await auth.updateAvatar(bytes);
    if (!context.mounted) return;
    if (!ok) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.profileAvatarFailed,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
    }
  }

  Future<void> _afterRoleSwitch(BuildContext context, bool ok) async {
    if (!context.mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RootRouter()),
        (route) => false,
      );
    } else {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.profileRoleSwitchFailed,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
    }
  }

  Future<void> _becomeSellerFlow(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final businessNameController = TextEditingController();
    final ownerNameController = TextEditingController(
      text: authProvider.userName,
    );

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileBecomeSeller,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: businessNameController,
                decoration:
                    InputDecoration(labelText: l10n.profileBusinessName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerNameController,
                decoration: InputDecoration(labelText: l10n.profileOwnerName),
              ),
            ],
          ),
        ),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: ElevatedButton(
            onPressed: () {
              if (businessNameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: Text(l10n.profileSubmit,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      ),
    );

    if (submitted != true) return;
    final ok = await authProvider.becomeSeller(
      businessName: businessNameController.text.trim(),
      ownerName: ownerNameController.text.trim(),
    );
    if (!context.mounted) return;
    await _afterRoleSwitch(context, ok);
  }

  Future<void> _becomeDeliveryFlow(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: authProvider.userName);
    String vehicleType = 'BIKE';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.profileBecomeDelivery,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.profileFullName),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: vehicleType,
                  decoration:
                      InputDecoration(labelText: l10n.profileVehicleType),
                  items: [
                    DropdownMenuItem(
                        value: 'BIKE', child: Text(l10n.profileVehicleBike)),
                    DropdownMenuItem(
                        value: 'SCOOTER',
                        child: Text(l10n.profileVehicleScooter)),
                    DropdownMenuItem(
                        value: 'BICYCLE',
                        child: Text(l10n.profileVehicleBicycle)),
                    DropdownMenuItem(
                        value: 'EV_SCOOTER',
                        child: Text(l10n.profileVehicleEvScooter)),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => vehicleType = value!),
                ),
              ],
            ),
          ),
          actions: [
            Pressable(
                child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.profileCancel,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
            Pressable(
                child: ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: Text(l10n.profileSubmit,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          ],
        ),
      ),
    );

    if (submitted != true) return;
    final ok = await authProvider.becomeDeliveryPartner(
      fullName: nameController.text.trim(),
      vehicleType: vehicleType,
    );
    if (!context.mounted) return;
    await _afterRoleSwitch(context, ok);
  }

  void _needLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loggedIn = authProvider.isLoggedIn;
    final customer = authProvider.role == UserRole.customer;

    // Rows that need an account send guests to log in first.
    VoidCallback gated(VoidCallback go) =>
        loggedIn ? go : () => _needLogin(context);

    void open(Widget screen) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        // Room for the floating bottom bar.
        110 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        _ProfileCard(
          auth: authProvider,
          onLogin: () => _needLogin(context),
          onPickAvatar: () => _pickAvatar(context, authProvider),
        ),
        // Logged in, but the profile row never landed: name/role/addresses
        // are still the defaults, and the role decides which home the user
        // gets. Say so, and offer the re-read — background retries also
        // keep trying on their own.
        if (loggedIn && authProvider.profileStale)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: RoleInlineError(
              message: l10n.profileStale,
              onRetry: authProvider.refreshProfile,
            ),
          ),
        _SectionTitle(l10n.profileSectionPersonal),
        _RowsCard(
          children: [
            if (loggedIn)
              _ProfileRow(
                icon: Iconsax.receipt,
                label: l10n.profileMyOrders,
                onTap: () => open(const OrdersScreen()),
              ),
            if (!loggedIn || customer) ...[
              if (loggedIn)
                _ProfileRow(
                  icon: Iconsax.location,
                  label: l10n.profileAddresses,
                  onTap: () => open(const AddressManagementScreen()),
                ),
              if (loggedIn)
                _ProfileRow(
                  icon: Iconsax.wallet_3,
                  label: l10n.profileMyWallet,
                  onTap: () => open(const WalletScreen()),
                ),
              if (loggedIn)
                _ProfileRow(
                  icon: Iconsax.card,
                  label: l10n.profilePaymentMethods,
                  onTap: () => open(const PaymentMethodsScreen()),
                ),
              _ProfileRow(
                icon: Iconsax.heart,
                label: l10n.profileWishlist,
                badgeCount: context.watch<WishlistProvider>().count,
                onTap: gated(() => open(const WishlistScreen())),
              ),
              if (loggedIn) const _ReferralRow(),
            ],
          ],
        ),
        _SectionTitle(l10n.profileSectionSettings),
        _RowsCard(
          children: [
            ValueListenableBuilder<bool?>(
              valueListenable: NightSky.forced,
              builder: (context, _, __) {
                final night = NightSky.active;
                return _ProfileRow(
                  icon: Iconsax.brush_2,
                  label: l10n.profileChangeTheme,
                  showChevron: false,
                  trailing: Switch(
                    value: night,
                    onChanged: (value) => NightSky.setForced(value),
                  ),
                  onTap: () => NightSky.setForced(!night),
                );
              },
            ),
            _ProfileRow(
              icon: Iconsax.notification,
              label: l10n.profileNotifications,
              onTap: gated(() => open(const NotificationsScreen())),
            ),
          ],
        ),
        _SectionTitle(l10n.profileSectionHelp),
        _RowsCard(
          children: [
            _ProfileRow(
              icon: Iconsax.headphone,
              label: l10n.profileContactUs,
              onTap: gated(() => open(const ContactUsScreen())),
            ),
            _ProfileRow(
              icon: Iconsax.message_question,
              label: l10n.profileFaq,
              onTap: () => open(const FaqScreen()),
            ),
            _ProfileRow(
              icon: Iconsax.box_add,
              label: l10n.profileProductRequests,
              onTap: gated(() => open(const ProductRequestsScreen())),
            ),
            _ProfileRow(
              icon: Iconsax.shield_tick,
              label: l10n.profilePolicies,
              onTap: () => open(const PoliciesScreen()),
            ),
            _ProfileRow(
              icon: Iconsax.document_text,
              label: l10n.profileTerms,
              onTap: () => open(const TermsScreen()),
            ),
          ],
        ),
        _SectionTitle(l10n.profileSectionAbout),
        _RowsCard(
          children: [
            _ProfileRow(
              icon: Iconsax.info_circle,
              label: l10n.profileAbout,
              onTap: () => open(const AboutScreen()),
            ),
            _ProfileRow(
              icon: Iconsax.star,
              label: l10n.profileRateUs,
              onTap: gated(() => showRateUsSheet(context)),
            ),
            _ProfileRow(
              icon: Iconsax.share,
              label: l10n.profileShareApp,
              onTap: () => shareApp(l10n),
            ),
          ],
        ),
        if (loggedIn && customer) ...[
          _SectionTitle(l10n.profileSectionWork),
          _RowsCard(
            children: [
              _ProfileRow(
                icon: Iconsax.shop,
                label: l10n.profileBecomeSeller,
                onTap: () => _becomeSellerFlow(context),
              ),
              _ProfileRow(
                icon: Iconsax.truck,
                label: l10n.profileBecomeDelivery,
                onTap: () => _becomeDeliveryFlow(context),
              ),
            ],
          ),
        ],
        if (loggedIn) ...[
          _SectionTitle(l10n.profileSectionDanger),
          _RowsCard(
            children: [
              _ProfileRow(
                icon: Iconsax.logout,
                label: l10n.profileLogout,
                color: AppConstants.dangerColor,
                showChevron: false,
                onTap: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              if (authProvider.role == UserRole.customer)
                _ProfileRow(
                  icon: Iconsax.trash,
                  label: l10n.profileDeleteAccount,
                  color: AppConstants.dangerColor,
                  showChevron: false,
                  onTap: () => _deleteAccount(context, authProvider),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The dark card at the top: the photo, a welcome, and Login for guests.
class _ProfileCard extends StatelessWidget {
  final AuthProvider auth;
  final VoidCallback onLogin;
  final VoidCallback onPickAvatar;

  const _ProfileCard({
    required this.auth,
    required this.onLogin,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loggedIn = auth.isLoggedIn;
    final url = auth.avatarUrl;
    final name = auth.userName.trim();

    final photo = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && loggedIn
          ? Image(
              image: CachedNetworkImageProvider(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Iconsax.user, size: 44, color: Colors.white),
            )
          : Center(
              child: loggedIn && name.isNotEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Iconsax.user, size: 46, color: Colors.white),
            ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFE4E4E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: loggedIn ? onPickAvatar : null,
            child: Stack(
              children: [
                photo,
                if (loggedIn)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.camera,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: loggedIn
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? l10n.profileWelcomeName : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.email.isNotEmpty
                            ? auth.email
                            : (auth.phone.isEmpty ? '' : auth.phone),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          auth.role.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileWelcomeGuest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Pressable(
                          child: ElevatedButton(
                        onPressed: onLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, AppControl.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        child: Text(
                          l10n.profileLogin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimaryColor,
        ),
      ),
    );
  }
}

/// A white, thinly outlined card holding rows with a divider between them.
class _RowsCard extends StatelessWidget {
  final List<Widget> children;

  const _RowsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFEBEBEB)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final int? badgeCount;
  final bool showChevron;
  final Widget? trailing;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badgeCount,
    this.showChevron = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ink = color ?? AppConstants.primaryColor;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Bare icon — no tinted tile behind it.
            Icon(icon, size: 18, color: ink),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppConstants.textPrimaryColor,
                ),
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs + 1,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$badgeCount',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (trailing != null) trailing!,
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9A9A9A),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Invite Friends": shows this person's referral code and copies it when
/// tapped. A friend who enters it when signing up gets a wallet bonus.
class _ReferralRow extends StatefulWidget {
  const _ReferralRow();

  @override
  State<_ReferralRow> createState() => _ReferralRowState();
}

class _ReferralRowState extends State<_ReferralRow> {
  String? _code;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = SupabaseService.client.auth.currentUser?.id;
      if (uid == null) return;
      final row = await SupabaseService.client
          .from('profiles')
          .select('referral_code')
          .eq('id', uid)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _code = row?['referral_code'] as String?;
          _failed = false;
        });
      }
    } catch (e) {
      // A code that could not be fetched is not a code that does not exist.
      // The row used to hide itself on a failure, so the customer never even
      // learned they had one to share.
      debugPrint('Referral code load failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = _code;
    if (code == null && _failed) {
      return _ProfileRow(
        icon: Iconsax.gift,
        label: l10n.profileReferralFailed,
        showChevron: false,
        trailing: const Icon(Iconsax.refresh, size: 20),
        onTap: () {
          setState(() => _failed = false);
          _load();
        },
      );
    }
    if (code == null || code.isEmpty) return const SizedBox.shrink();
    return _ProfileRow(
      icon: Iconsax.gift,
      label: l10n.profileReferralCode(code),
      showChevron: false,
      trailing: const Icon(Iconsax.copy, size: 20),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(ClipboardData(text: code));
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.profileReferralCopied,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

/// The customer deleting their own account (Play Store requires the option
/// in the app). The server keeps the orders — they are the store's records
/// too — but strips everything personal and closes the login for good; see
/// delete_my_account() in supabase/delete_my_account.sql.
Future<void> _deleteAccount(BuildContext context, AuthProvider auth) async {
  final l10n = AppLocalizations.of(context);
  final sure = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.profileDeleteTitle),
      content: Text(l10n.profileDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.profileDeleteKeep,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.dangerColor,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.profileDeleteConfirm,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await SupabaseService.client.rpc('delete_my_account');
  } catch (e) {
    final active = e.toString().contains('active_orders');
    messenger.showSnackBar(SnackBar(
      content: Text(
        active ? l10n.profileDeleteActiveOrders : l10n.profileDeleteFailed,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ));
    return;
  }
  await auth.signOut();
  messenger.showSnackBar(SnackBar(
      content: Text(l10n.profileDeleted,
          maxLines: 1, overflow: TextOverflow.ellipsis)));
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
