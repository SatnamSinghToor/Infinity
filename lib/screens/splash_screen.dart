import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'root_router.dart';

/// The first thing people see: the Duggu Store wordmark and tagline over the
/// top of the backdrop, and a bar that fills as the app gets ready. It moves
/// on as soon as the saved sign-in has been restored (but never before the
/// intro has played, and never later than [_longest]).
///
/// The backdrop is one flat illustration — the mascot riding out with a
/// delivery bag of groceries — drawn full-bleed and anchored to the bottom,
/// so the scooter and the road run to the phone's last pixel instead of
/// leaving an empty strip under them. It is line art on white, the same
/// white the screen and the Android launch screen are set to, so there is no
/// seam and no flash of another colour before the first frame.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// The intro always plays through at least this long...
  static const _shortest = Duration(milliseconds: 2100);

  /// ...and the splash never holds people longer than this.
  static const _longest = Duration(seconds: 5);

  /// The illustration's own background, and what the screen shows behind and
  /// above it: the flat art is drawn on white.
  static const _page = Color(0xFFFFFFFF);

  late final AnimationController _intro;
  Timer? _shortestTimer;
  Timer? _longestTimer;
  bool _introDone = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _shortestTimer = Timer(_shortest, () {
      if (mounted) setState(() => _introDone = true);
    });
    _longestTimer = Timer(_longest, _leave);
  }

  bool _started = false;

  void _start(bool reduceMotion) {
    if (_started) return;
    _started = true;
    if (reduceMotion) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, animation, __) => const RootRouter(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _shortestTimer?.cancel();
    _longestTimer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  /// A 0..1 progress for [t] that starts at [begin] and finishes at [end] of
  /// the intro.
  Animation<double> _part(double begin, double end, [Curve? curve]) {
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(begin, end, curve: curve ?? Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    _start(reduceMotion);

    final ready = context.watch<AuthProvider>().initialized;
    if (ready && _introDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leave());
    }

    final wordmark = _part(0.0, 0.45, Curves.easeOutBack);
    final tagline = _part(0.35, 0.75);
    final progress = _part(0.5, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _page,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _page,
        body: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // One illustration, as wide as the screen and pinned to the
              // bottom: the scooter and the road reach the last pixel. On a
              // tall phone it is only the white above it that gives, which is
              // where the wordmark goes anyway.
              Semantics(
                container: true,
                label: AppConstants.appName.toLowerCase(),
                child: Image.asset(
                  'assets/logo/splash_art.png',
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  excludeFromSemantics: true,
                ),
              ),
              // The wordmark, the promise it makes, and the bar that
              // fills while the app gets ready.
              Positioned(
                left: 24,
                right: 24,
                top: MediaQuery.sizeOf(context).height * 0.055,
                child: FadeTransition(
                  opacity: wordmark,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.35),
                      end: Offset.zero,
                    ).animate(wordmark),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/logo/duggu_logo.png',
                          width: MediaQuery.sizeOf(context).width * 0.46,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(height: 10),
                        FadeTransition(
                          opacity: tagline,
                          child: Text(
                            AppConstants.tagline,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: progress,
                          child: SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.55,
                            child: _progress(ready),
                          ),
                        ),
                      ],
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

  Widget _progress(bool ready) {
    // It sits on plain white under the tagline, so it needs no plate.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: ready ? 1.0 : 0.82),
            duration: Duration(milliseconds: ready ? 500 : 3200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor:
                  AppConstants.primaryColor.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation(
                AppConstants.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          ready ? 'Ready' : 'Getting your store ready…',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppConstants.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
