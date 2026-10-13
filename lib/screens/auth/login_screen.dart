import 'package:flutter/gestures.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../help_screens.dart';
import '../root_router.dart';
import 'auth_skip_button.dart';
import 'auth_style.dart';
import 'google_auth_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../widgets/pressable.dart';

/// Blinkit-style entry: one field that takes an email or a mobile number.
/// An existing account signs in; a number with no account goes straight to
/// sign-up, and a failed email login offers the same path.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;
  bool _obscure = true;
  bool _busy = false;

  /// Shown when the credentials didn't match: offers the sign-up path.
  bool _notFound = false;

  bool get _isEmail => _idController.text.trim().contains('@');

  /// The entered number reduced to 10 digits.
  String get _phone {
    var d = _idController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length == 12 && d.startsWith('91')) d = d.substring(2);
    if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
    return d;
  }

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsScreen()),
          );
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PoliciesScreen()),
          );
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final id = _idController.text.trim();
    if (id.isEmpty || _passwordController.text.isEmpty) return;
    setState(() {
      _busy = true;
      _notFound = false;
    });
    final auth = context.read<AuthProvider>();
    bool ok;
    // Server-side existence check (supabase/account_exists.sql) routes a
    // fresh email or number straight to sign-up. Without the function the
    // login attempt decides and a failure offers the sign-up path.
    bool? exists;
    try {
      final res = await SupabaseService.client.rpc(
        _isEmail ? 'account_exists_email' : 'account_exists_phone',
        params: {'p': _isEmail ? id : _phone},
      );
      exists = res as bool?;
    } catch (_) {
      exists = null;
    }
    if (exists == false) {
      if (mounted) {
        setState(() => _busy = false);
        _goRegister();
      }
      return;
    }
    ok = _isEmail
        ? await auth.signIn(
            email: id,
            password: _passwordController.text,
          )
        : await auth.signInWithPhone(
            phone: _phone,
            password: _passwordController.text,
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RootRouter()),
        (route) => false,
      );
    } else {
      final err = auth.error ?? '';
      if (err.contains('Invalid')) setState(() => _notFound = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err, maxLines: 1, overflow: TextOverflow.ellipsis)));
    }
  }

  void _goRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          initialEmail: _isEmail ? _idController.text.trim() : null,
          initialPhone: _isEmail ? null : _phone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading = context.watch<AuthProvider>().isLoading || _busy;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: whiteStatusBar,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          // The page is one plain column in one scroll view, and every
          // measurement comes from the room this screen actually has — so
          // there is no size here that can come out negative or unbounded,
          // however small or fast the first frame is.
          child: LayoutBuilder(
            builder: (context, room) {
              return SingleChildScrollView(
                // A drag puts the keyboard away first, as phones do.
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                ),
                // At least a screen tall, so the form sits in the middle with
                // Skip above it and the small print below; on a short phone,
                // or with the keyboard up, the page simply scrolls.
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: room.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Skip sits in the flow at the top right: the row is
                        // measured like any other, so it can never be drawn
                        // over the form below it.
                        const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.sm),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AuthSkipButton(pill: true),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.lg),
                        Center(child: _logoTile()),
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: Text(
                            l10n.authHeading,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.blackColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Center(
                          child: Text(
                            l10n.authHeadingSub,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppConstants.textSecondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _idField(),
                        const SizedBox(height: AppSpacing.md),
                        _passwordField(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Pressable(
                              child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: Text(
                              l10n.authForgot,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                        ),
                        if (_notFound) _registerHint(),
                        const SizedBox(height: AppSpacing.xs),
                        _continueButton(isLoading),
                        const GoogleAuthButton(),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            0,
                            AppSpacing.lg,
                            0,
                            AppSpacing.md,
                          ),
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: AppConstants.textSecondaryColor,
                              ),
                              children: [
                                TextSpan(
                                  text: l10n.authAgree(AppConstants.appName),
                                ),
                                TextSpan(
                                  text: l10n.authTerms,
                                  recognizer: _termsTap,
                                  style: const TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: l10n.authAnd),
                                TextSpan(
                                  text: l10n.authPrivacy,
                                  recognizer: _privacyTap,
                                  style: const TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _logoTile() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Image.asset(
        'assets/logo/duggu_logo.png',
        height: 64,
        width: 117,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _idField() {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _idController,
      onChanged: (_) => setState(() => _notFound = false),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: authFieldDecoration(
        hint: _isEmail ? l10n.authEmailHint : l10n.authIdHint,
        prefix: _isEmail
            ? const Icon(
                Iconsax.sms,
                color: AppConstants.textSecondaryColor,
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 16),
                  IndiaFlag(),
                  SizedBox(width: 6),
                  Text(
                    '+91',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.blackColor,
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              ),
      ),
    );
  }

  Widget _passwordField() {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _passwordController,
      obscureText: _obscure,
      onChanged: (_) => setState(() => _notFound = false),
      decoration: authFieldDecoration(
        hint: l10n.authPasswordHint,
        prefix: const Icon(
          Iconsax.lock_1,
          color: AppConstants.textSecondaryColor,
        ),
        suffix: Pressable(
            child: IconButton(
          icon: Icon(
            _obscure ? Iconsax.eye_slash : Iconsax.eye,
            size: 20,
            color: AppConstants.textSecondaryColor,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        )),
      ),
    );
  }

  Widget _registerHint() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEmail ? l10n.authNoLoginEmail : l10n.authNoLoginPhone,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppConstants.blackColor,
              ),
            ),
          ),
          Pressable(
              child: TextButton(
            onPressed: _goRegister,
            child: Text(
              l10n.authSignUp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
  }

  Widget _continueButton(bool loading) {
    final l10n = AppLocalizations.of(context);
    // The app's primary action height (AppControl.lg); the corners stay the
    // ones this button always had.
    return SizedBox(
      height: AppControl.lg,
      child: Pressable(
          child: ElevatedButton(
        onPressed: loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                l10n.authContinue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      )),
    );
  }
}
