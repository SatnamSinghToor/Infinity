import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../utils/constants.dart';
import '../utils/tokens.dart';
import 'pressable.dart';

/// The pieces every list in the app is built from: mostly the three roles'
/// screens (seller, delivery, admin), and now the customer's too — cart,
/// wishlist, orders, notifications, wallet and the rest.
///
/// A screen has four states and used to draw all four differently, or not at
/// all: loading, loaded, nothing here, and the load failed. The last one is
/// the one that matters most. A request that fails on a weak connection is
/// not an empty list, and someone who is told "no orders yet" when the truth
/// is "we could not ask" will not think to try again.
///
/// The same rule applies to writes: a tap that fails and says nothing looks
/// exactly like a tap that worked. [roleSay] is the app's single way of
/// saying a write did not land.

/// The app's one-line notice for the outcome of an action: a short message
/// at the bottom of the screen, replacing whatever notice was there before.
/// Screens used to hand-roll their own snackbars — or, worse, swallow the
/// failure — so every "that did not work" now reads the same way.
void roleSay(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
}

/// One number on a role's Home: a white tile, the icon in the app's orange,
/// the value in bold and the label under it in grey.
class RoleStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  /// The four-across rows on a phone: smaller type and padding, so the row
  /// fits without the labels ever running out of the tile.
  final bool dense;

  const RoleStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 10 : 14),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: dense ? 20 : 24),
          SizedBox(height: dense ? 5 : 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 15 : 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppConstants.textSecondaryColor,
              fontSize: dense ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while a role screen is fetching: the same centred spinner in the
/// same place on every screen, with a line saying what is being fetched.
class RoleLoading extends StatelessWidget {
  final String message;

  const RoleLoading({super.key, this.message = 'Loading…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A role screen's body, in whichever of its four states it is in: fetching,
/// failed, or ready — and, if ready, empty or full, which [child] decides.
///
/// Every list screen wraps its content in this, so a slow load, a failed
/// load and an empty list all look the same in the seller's app, the
/// delivery partner's, the admin's and the customer's — and, more
/// importantly, they never look like each other.
class RoleBody extends StatelessWidget {
  final bool loading;
  final String loadingMessage;

  final bool failed;
  final String errorTitle;
  final VoidCallback onRetry;

  /// The screen once everything is fine: normally a RefreshIndicator around
  /// the list.
  final Widget child;

  const RoleBody({
    super.key,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.child,
    this.loadingMessage = 'Loading…',
    this.errorTitle = "Couldn't load this",
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return RoleLoading(message: loadingMessage);
    if (failed) return RoleError(title: errorTitle, onRetry: onRetry);
    return child;
  }
}

/// Shown when a load failed. It says so plainly and offers the one thing
/// that helps: trying again.
class RoleError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  /// What went wrong, in the screen's own words ("Couldn't load orders").
  final String title;

  const RoleError({
    super.key,
    required this.onRetry,
    this.title = "Couldn't load this",
    this.message =
        'Check your internet connection, then try again — nothing was lost.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Iconsax.wifi_square,
              size: 52,
              color: AppConstants.textSecondaryColor,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppConstants.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: AppControl.md,
              child: Pressable(
                  child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'Try again',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when a list is genuinely empty — which is good news on a seller's
/// first day, and should read that way rather than as a failure.
class RoleEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// Something useful to do about it, if there is anything.
  final Widget? action;

  const RoleEmpty({
    super.key,
    required this.title,
    required this.message,
    this.icon = Iconsax.box,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFFD8D3CB)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppConstants.textSecondaryColor,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The inline version of [RoleEmpty]: what a preview section on a role's Home
/// (the seller's product list, the admin's recent orders) shows when there is
/// nothing in it yet. A whole screen gets [RoleEmpty]; this sits inside one.
class RoleEmptyNote extends StatelessWidget {
  final String message;
  final IconData icon;

  const RoleEmptyNote({
    super.key,
    required this.message,
    this.icon = Iconsax.box,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFFCFC8BE)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The failed state of one section inside a screen that is otherwise fine —
/// the reviews under a product, the options a product comes in. A page-wide
/// [RoleError] would throw away everything that did load, so the section says
/// what it could not fetch and offers to try just that part again.
///
/// [onRetry] may be null, and it should be when trying again cannot change the
/// answer: a button beside a mistake in somebody else's settings teaches the
/// person reading it to tap the same wall.
class RoleInlineError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const RoleInlineError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: [
          const Icon(
            Iconsax.wifi_square,
            size: 20,
            color: AppConstants.textSecondaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ),
          if (onRetry != null)
            Pressable(
                child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text(
                'Try again',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
        ],
      ),
    );
  }
}
