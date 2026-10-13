import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';
import '../utils/tokens.dart';
import '../widgets/pressable.dart';

/// First-run walkthrough for new users. Shown once per install (see
/// [hasSeen]/[markSeen]).
///
/// Flow rules (keep these when touching any auth screen):
/// 1. "Get Started" ends on the LOGIN screen — never on Register.
/// 2. "Skip" enters the store as a guest, also without Register.
/// 3. Register opens only from Login, when the entered email/phone has no
///    account (server existence check) or the user taps "Sign Up" there.
/// 4. Existing credentials log straight in.
///
/// Three pages, one for each promise the shop makes: everything in one
/// place, at your door the same day, and paid for safely. The artwork is
/// flat line art on white, so the page is white too, and the pages are told
/// apart by their headline, their picture and the dots between them.
class OnboardingScreen extends StatefulWidget {
  /// Called after the walkthrough is finished. [createAccount] is true when
  /// the user chose to create an account rather than log in.
  final void Function(bool createAccount) onFinished;

  /// Called when the user taps "Skip" (top right): they go straight to the
  /// store as a guest.
  final VoidCallback onSkip;

  const OnboardingScreen({
    super.key,
    required this.onFinished,
    required this.onSkip,
  });

  static const _prefsKey = 'onboarding_seen_v1';

  /// Whether the walkthrough has already been completed on this device. If
  /// storage can't be read we say "seen" — never block the user behind it.
  static Future<bool> hasSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    } catch (_) {
      // Best-effort: if the flag cannot be written, the walkthrough simply
      // shows once more on a later launch — annoying once, never blocking.
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  final String asset;
  final String title;
  final String body;

  const _OnboardingPage(this.asset, this.title, this.body);
}

/// The headline is what the page promises; the body says how.
const _pages = [
  _OnboardingPage(
    'assets/onboarding/page_1.png',
    'Find What You Need',
    'Explore thousands of products across everyday essentials and household '
        'items, tailored just for you.',
  ),
  _OnboardingPage(
    'assets/onboarding/page_2.png',
    'Swift Doorstep Delivery',
    'Sit back and relax while your order comes to your door — picked, packed '
        'and tracked the whole way.',
  ),
  _OnboardingPage(
    'assets/onboarding/page_3.png',
    'Fast & Secure Checkout',
    'Pay the way you like — UPI, cards or cash on delivery — and get your '
        'order in minutes.',
  ),
];

/// Below this the headline steps down a size, so a small phone keeps the
/// picture and the button on screen.
const _smallScreen = 700.0;

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  // Both exits answer the tap at once. Writing the "seen" flag goes to disk,
  // and waiting on it first left a beat where the tap did nothing and then
  // the store jumped in — the freeze people felt on Skip. The flag is
  // best-effort anyway (see markSeen), so it is written alongside.
  void _finish() {
    OnboardingScreen.markSeen();
    // Get Started lands on Login; Register is only for emails/phones Login
    // finds to be new.
    widget.onFinished(false);
  }

  void _skip() {
    OnboardingScreen.markSeen();
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, index) => _pageBody(index),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: _actionButton(),
                  ),
                ],
              ),
              Positioned(top: 6, right: 16, child: _skipPill()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageBody(int index) {
    final page = _pages[index];
    final small = MediaQuery.sizeOf(context).height < _smallScreen;
    return Column(
      children: [
        // Room for the Skip pill in the corner.
        SizedBox(height: small ? 34 : 46),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            page.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: small ? 21 : 24,
              fontWeight: FontWeight.w700,
              height: 1.18,
              color: AppConstants.textPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Text(
            page.body,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: small ? 13 : 14,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: AppConstants.textSecondaryColor,
            ),
          ),
        ),
        SizedBox(height: small ? 14 : 20),
        _dots(),
        // The picture takes whatever is left, whole and never cropped.
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Image.asset(
                page.asset,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// One filled orange pill for the page you are on, small grey dots for the
  /// rest.
  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppConstants.primaryColor : const Color(0xFFE3E0DC),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _actionButton() {
    return Pressable(
        child: GestureDetector(
      onTap: _isLast ? _finish : _next,
      child: Container(
        width: double.infinity,
        // The app's primary action size, like every other main button.
        height: AppControl.lg,
        decoration: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLast ? "Let's Get Started!" : 'Next',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (!_isLast) ...[
              const SizedBox(width: 8),
              const Icon(
                Iconsax.arrow_right_3_copy,
                size: 19,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    ));
  }

  /// Goes straight to the store as a guest, from any page.
  Widget _skipPill() {
    return Pressable(
        child: GestureDetector(
      onTap: _skip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE6E2DD)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          'Skip',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimaryColor,
          ),
        ),
      ),
    ));
  }
}
