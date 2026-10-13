import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../root_router.dart';
import 'auth_skip_button.dart';
import 'auth_style.dart';
import 'google_auth_button.dart';
import '../../widgets/pressable.dart';

class RegisterScreen extends StatefulWidget {
  /// Prefilled when the login screen routed a new user here.
  final String? initialEmail;
  final String? initialPhone;

  const RegisterScreen({
    super.key,
    this.initialEmail,
    this.initialPhone,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
    _phoneController.text = widget.initialPhone ?? '';
    // The button lights up as soon as the form is complete.
    for (final c in [
      _nameController,
      _phoneController,
      _emailController,
      _passwordController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _complete =>
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().length >= 10 &&
      _emailController.text.contains('@') &&
      _passwordController.text.length >= 6;

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text,
      phone: _phoneController.text,
      referralCode: _codeController.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RootRouter()),
        (route) => false,
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(auth.error!, maxLines: 1, overflow: TextOverflow.ellipsis)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading = context.watch<AuthProvider>().isLoading;
    final ready = _complete && !isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: whiteStatusBar,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pressable(
                        child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 24),
                    )),
                    const Spacer(),
                    const AuthSkipButton(closeAllScreens: true, pill: true),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.authCreateAccount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authCreateBody,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppConstants.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: authFieldDecoration(
                    hint: l10n.authUserName,
                    prefix: const Icon(Iconsax.user),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const PhoneCodeChip(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: authFieldDecoration(hint: l10n.authPhone),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: authFieldDecoration(
                    hint: l10n.authEmailAddress,
                    prefix: const Icon(Iconsax.sms),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: authFieldDecoration(
                    hint: l10n.authNewPassword,
                    prefix: const Icon(Iconsax.lock),
                    suffix: Pressable(
                        child: IconButton(
                      icon: Icon(_obscure ? Iconsax.eye_slash : Iconsax.eye),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: authFieldDecoration(
                    hint: l10n.authFriendsCode,
                    prefix: const Icon(Iconsax.gift),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: AppControl.lg,
                  child: Pressable(
                      child: ElevatedButton(
                    onPressed: ready ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: const Color(0xFFBDBDBD),
                      disabledForegroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.authSubmit,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  )),
                ),
                const GoogleAuthButton(),
                const SizedBox(height: 12),
                Text(
                  l10n.authRoleNote,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppConstants.textSecondaryColor,
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
