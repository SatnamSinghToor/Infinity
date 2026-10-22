import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/google_auth_service.dart';
import '../../utils/tokens.dart';
import '../../widgets/pressable.dart';
import '../root_router.dart';

/// An "or" line, then "Continue with Google" — the same shape and height as
/// the screen's own primary button (`AppControl.lg`, 16-radius corners),
/// just outlined instead of filled, so it reads as a second way in rather
/// than competing with the first.
///
/// Renders as nothing at all until Google sign-in is actually configured
/// (see [GoogleAuthService.isConfigured]) — a build with no Google Cloud
/// client set up yet must not show a button that can only ever fail.
class GoogleAuthButton extends StatefulWidget {
  const GoogleAuthButton({super.key});

  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> {
  bool _busy = false;

  Future<void> _tap() async {
    if (_busy) return;
    setState(() => _busy = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RootRouter()),
        (route) => false,
      );
      return;
    }
    // A plain cancel (the account picker closed with nothing chosen)
    // leaves auth.error null on purpose — nothing to say about that.
    final err = auth.error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err, maxLines: 2, overflow: TextOverflow.ellipsis)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to show until the build actually has a Google Cloud client —
    // `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` turns the button on.
    if (!GoogleAuthService.isConfigured) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final loading = _busy || context.watch<AuthProvider>().isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: Divider(color: t.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                l10n.authOrDivider,
                style: TextStyle(fontSize: 12.5, color: t.textSecondary),
              ),
            ),
            Expanded(child: Divider(color: t.border)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: AppControl.lg,
          child: Pressable(
              child: OutlinedButton(
            onPressed: loading ? null : _tap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: t.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoogleG(border: t.border),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          l10n.authContinueGoogle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
          )),
        ),
      ],
    );
  }
}

/// A plain "G" badge — there's no Google logo asset in this app, and this
/// stays legible next to the button's own text without pulling in an icon
/// font just for one glyph. Google's own blue is the one brand colour that
/// has to stay literal — it is what makes the badge read as "Google" at a
/// glance, the same reason the app's own primary orange isn't a token.
class _GoogleG extends StatelessWidget {
  final Color border;

  const _GoogleG({required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4285F4),
          height: 1,
        ),
      ),
    );
  }
}
