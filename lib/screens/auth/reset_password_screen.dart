import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/tokens.dart';
import '../../widgets/plain_app_bar.dart';
import '../../widgets/pressable.dart';
import '../root_router.dart';
import 'auth_style.dart';

/// Where the password-reset email link lands: DeepLinkService opens this
/// once it has turned the link into a real session, so all this screen has
/// to do is ask for — and set — the new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  bool _done = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: context.tokens.danger,
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final password = _passwordController.text;
    if (password.length < 6) {
      _showError(l10n.authPasswordTooShort);
      return;
    }
    if (password != _confirmController.text) {
      _showError(l10n.authPasswordsDontMatch);
      return;
    }

    setState(() => _isLoading = true);
    final error = await context.read<AuthProvider>().updatePassword(password);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _done = error == null;
    });
    if (error != null) _showError(error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: whiteStatusBar,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PlainAppBar(
          titleText: l10n.authResetTitle,
          onBack: () => Navigator.pop(context),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tokens.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.lock, color: tokens.primary, size: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    l10n.authResetTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l10n.authResetBody,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: tokens.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                if (!_done) ...[
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: authFieldDecoration(
                      hint: l10n.authResetNewPassword,
                      prefix: Icon(Iconsax.lock_1, color: tokens.textSecondary),
                      suffix: Pressable(
                          child: IconButton(
                        icon: Icon(
                          _obscure ? Iconsax.eye_slash : Iconsax.eye,
                          size: 20,
                          color: tokens.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      )),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmController,
                    obscureText: _obscure,
                    onSubmitted: (_) => _submit(),
                    decoration: authFieldDecoration(
                      hint: l10n.authResetConfirmPassword,
                      prefix: Icon(Iconsax.lock_1, color: tokens.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: AppControl.lg,
                    child: Pressable(
                        child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.authResetSubmit,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    )),
                  ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.tick_circle,
                              size: 64, color: tokens.success),
                          const SizedBox(height: 16),
                          Text(
                            l10n.authResetDone,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: AppControl.lg,
                            child: Pressable(
                                child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RootRouter(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Text(l10n.authResetContinue,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            )),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
