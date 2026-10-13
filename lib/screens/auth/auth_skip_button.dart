import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../root_router.dart';
import '../../widgets/pressable.dart';

/// "Skip" for the login / sign-up screens (top right): browse the store
/// without an account. Checkout asks for a login later.
class AuthSkipButton extends StatelessWidget {
  /// Set on screens that sit on top of the login screen (sign-up), where
  /// skipping must close everything back to the store rather than just this
  /// one screen.
  final bool closeAllScreens;

  /// Text colour; defaults to the theme orange. Use white on the orange app
  /// bar.
  final Color color;

  /// Drawn as a small outlined pill (the login screen) rather than a text
  /// button.
  final bool pill;

  const AuthSkipButton({
    super.key,
    this.closeAllScreens = false,
    this.color = AppConstants.primaryColor,
    this.pill = false,
  });

  void _skip(BuildContext context) {
    final auth = context.read<AuthProvider>();

    // Login was opened by a guest who is already in the store (e.g. from the
    // cart): "Skip" just closes it and drops them back where they were.
    if (auth.isGuest && !closeAllScreens) {
      Navigator.of(context).pop();
      return;
    }

    // Login is the root router's own screen (first launch, after the
    // walkthrough): becoming a guest is enough, the router fades to the store
    // by itself. Pushing a second router on top as well built Home twice in
    // the same moment, which is the stutter Skip used to have.
    final navigator = Navigator.of(context);
    if (!navigator.canPop() &&
        context.findAncestorWidgetOfExactType<RootRouter>() != null) {
      auth.continueAsGuest();
      return;
    }

    // Anywhere else, restart from the root router (it shows the store for a
    // guest). Works wherever the login screen sits in the stack, including
    // when it was pushed as the only screen after a logout.
    auth.continueAsGuest();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootRouter()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pill) {
      // The same small outlined pill as the walkthrough's Skip, and the
      // size of a chip inside the app rather than a second main button.
      return Pressable(
          child: Material(
        color: Colors.white,
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0xFFE4E4E4)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _skip(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppLocalizations.of(context).authSkip,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimaryColor,
              ),
            ),
          ),
        ),
      ));
    }
    return Pressable(
        child: TextButton(
      onPressed: () => _skip(context),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppLocalizations.of(context).authSkip,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(width: 4),
          const Icon(Iconsax.arrow_right_3, size: 16),
        ],
      ),
    ));
  }
}
