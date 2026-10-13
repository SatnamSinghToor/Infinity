import 'dart:math' as math;
import 'package:duggu/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/voice_sound.dart';
import '../utils/constants.dart';
import 'app_network_image.dart';
import 'pressable.dart';

/// What the voice sheet hands back: the items on the shopping list that was
/// spoken, or a request to search with a photo instead.
class VoiceSearchResult {
  final List<String> terms;

  /// Where the photo should come from; null when this result is a spoken
  /// list rather than a photo search. The source is chosen in this sheet, so
  /// the caller never has to open a second one to ask.
  final ImageSource? photoSource;

  const VoiceSearchResult.terms(this.terms) : photoSource = null;
  const VoiceSearchResult.photo(this.photoSource) : terms = const [];

  bool get photo => photoSource != null;
}

/// The "search by voice or photo" sheet: tips on top, Upload and Speak at the
/// bottom. Speaking builds a shopping list — every item said is added with
/// its product photo — and keeps listening until done. Null means it was
/// dismissed.
Future<VoiceSearchResult?> showVoiceSearchSheet(BuildContext context) async {
  const duration = Duration(milliseconds: 420);
  final l10n = AppLocalizations.of(context);
  final result = await showGeneralDialog<VoiceSearchResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.voiceClose,
    barrierColor: Colors.black54,
    transitionDuration: duration,
    pageBuilder: (_, __, ___) => const Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _VoiceSearchSheet(),
      ),
    ),
    // One motion for everything in it: the panel glides up, and on the way
    // out glides down while fading, so nothing is left hanging mid-air.
    transitionBuilder: (context, animation, secondary, child) {
      final glide = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(glide),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
            reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ),
          child: child,
        ),
      );
    },
  );
  // The route reports its result as soon as it starts closing; wait for the
  // close to finish so the next screen doesn't slide in over a half-gone panel.
  await Future<void>.delayed(duration);
  return result;
}

class _ListItem {
  final String text;
  final Product? match;

  const _ListItem(this.text, this.match);
}

class _VoiceSearchSheet extends StatefulWidget {
  const _VoiceSearchSheet();

  @override
  State<_VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

class _VoiceSearchSheetState extends State<_VoiceSearchSheet>
    with TickerProviderStateMixin {
  static const _ink = Color(0xFF1B1B1B);

  static List<(String, String)> _tips(AppLocalizations l10n) => [
        ('🍅', l10n.voiceTipTomatoes),
        ('📷', l10n.voiceTipPhoto),
        ('🥛', l10n.voiceTipMilkEggs),
        ('🍪', l10n.voiceTipBiscuits),
      ];

  // "milk and eggs", "milk, eggs", "doodh aur ande" → separate items.
  static final _splitter = RegExp(
    r'\s*(?:,|\band\b|\baur\b|\bplus\b|और)\s*',
    caseSensitive: false,
  );

  final _speech = stt.SpeechToText();
  final List<double> _levels = List.filled(30, 0.06, growable: true);
  final List<_ListItem> _items = [];

  bool _ready = false;
  bool _listening = false;

  /// Upload was tapped: the actions row swaps to Camera / Gallery rather
  /// than closing the sheet and asking somewhere else.
  bool _pickingPhoto = false;
  bool _finished = false;
  bool _gotSpeech = false;
  int _silentCycles = 0;
  String _heard = '';
  String? _problem;

  /// Which stretch of listening is current. Android ends every stretch with
  /// two statuses (`notListening`, then `done`) and can deliver the final
  /// result more than once; without a way to tell "this stretch" from "the
  /// last one", each echo added the same item again and started a second
  /// listener on top of the first — "Biscuit" twice for one "biscuit".
  int _session = 0;

  /// Whether the current stretch has already been closed or has already
  /// given its final result. Both happen once per stretch, whatever the
  /// plugin reports.
  bool _cycleOpen = false;
  bool _finalSeen = false;

  /// Rows on their way out, faded and folded before they leave the list.
  final Set<_ListItem> _leaving = {};

  // The tips fly in one after another; a slower loop then keeps them (and the
  // Speak button's rings) gently moving.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    // Closing the sheet mid-listen must not leave the recogniser running or
    // the phone's sound muted.
    _speech.cancel();
    VoiceSound.end();
    _enter.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initSpeech().then((_) {
      if (mounted && !_listening && !_finished) _start();
    });
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _cycleEnded();
      },
      onError: (error) {
        if (!mounted) return;
        final quiet = error.errorMsg == 'error_no_match' ||
            error.errorMsg == 'error_speech_timeout';
        if (quiet) {
          _cycleEnded();
        } else {
          final l10n = AppLocalizations.of(context);
          VoiceSound.end();
          setState(() {
            _listening = false;
            _problem = l10n.voiceStopped;
          });
        }
      },
    );
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  // ---- speech -------------------------------------------------------------

  Future<void> _start() async {
    if (!_ready) {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') _cycleEnded();
        },
        onError: (error) {
          if (!mounted) return;
          final quiet = error.errorMsg == 'error_no_match' ||
              error.errorMsg == 'error_speech_timeout';
          if (quiet) {
            _cycleEnded();
          } else {
            final l10n = AppLocalizations.of(context);
            VoiceSound.end();
            setState(() {
              _listening = false;
              _problem = l10n.voiceStopped;
            });
          }
        },
      );
      if (!available) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() {
            _problem = l10n.voiceMicSettings;
          });
        }
        return;
      }
      if (mounted) {
        setState(() => _ready = true);
      }
    }
    if (!mounted) return;
    setState(() {
      _listening = true;
      _heard = '';
      _silentCycles = 0;
      _gotSpeech = false;
    });
    await VoiceSound.begin();
    if (!mounted || !_listening || _finished) return;
    await _listenOnce();
  }

  Future<void> _listenOnce() async {
    final session = ++_session;
    _cycleOpen = true;
    _finalSeen = false;
    await _speech.listen(
      onResult: (result) {
        // A result from an earlier stretch, or a repeat of the final one that
        // was already put on the list.
        if (!mounted || session != _session || _finalSeen) return;
        setState(() => _heard = result.recognizedWords);
        if (result.finalResult) {
          _finalSeen = true;
          _commitHeard();
        }
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        // Android reports roughly -2 (quiet) to 10 (loud).
        final normal = ((level + 2) / 12).clamp(0.06, 1.0).toDouble();
        setState(() {
          _levels.removeAt(0);
          _levels.add(normal);
        });
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.search,
      ),
    );
  }

  /// One stretch of listening ended (a pause in speech). Keep going for the
  /// next item; give up after two quiet stretches in a row.
  void _cycleEnded() {
    if (!mounted || !_listening || _finished) return;
    // The second status for the same stretch: it is already handled, and
    // handling it again would start a second listener.
    if (!_cycleOpen) return;
    _cycleOpen = false;
    final l10n = AppLocalizations.of(context);
    _commitHeard();
    _silentCycles = _gotSpeech ? 0 : _silentCycles + 1;
    _gotSpeech = false;
    if (_silentCycles >= 2) {
      VoiceSound.end();
      setState(() {
        _listening = false;
        if (_items.isEmpty) {
          _problem = l10n.voiceDidNotCatch;
        }
      });
      return;
    }
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && _listening && !_finished) _listenOnce();
    });
  }

  /// Turns what was just heard into list items.
  void _commitHeard() {
    final text = _heard.trim();
    if (text.isEmpty) return;
    _heard = '';
    _gotSpeech = true;
    final phrases =
        text.split(_splitter).map((p) => p.trim()).where((p) => p.isNotEmpty);
    setState(() {
      for (final phrase in phrases) {
        // A list names each thing once: saying it again (or the recogniser
        // hearing it twice) does not add a second row.
        final key = phrase.toLowerCase();
        final known = _items.any(
          (i) => !_leaving.contains(i) && i.text.toLowerCase() == key,
        );
        if (known) continue;
        _items.add(_ListItem(_capitalise(phrase), _matchFor(phrase)));
      }
    });
  }

  /// Takes [item] off the list with a short fold-and-fade instead of a jump.
  void _remove(_ListItem item) {
    if (_leaving.contains(item)) return;
    setState(() => _leaving.add(item));
    Future.delayed(_leaveDuration, () {
      if (!mounted) return;
      setState(() {
        _leaving.remove(item);
        _items.remove(item);
      });
    });
  }

  /// Every row leaves together, then the sheet settles back to the tips.
  void _clearAll() {
    if (_listening) _cancelListening();
    final going = _items.where((i) => !_leaving.contains(i)).toList();
    if (going.isEmpty) return;
    setState(() => _leaving.addAll(going));
    Future.delayed(_leaveDuration, () {
      if (!mounted) return;
      setState(() {
        _items.removeWhere(going.contains);
        _leaving.removeAll(going);
      });
    });
  }

  static const _leaveDuration = Duration(milliseconds: 260);

  Future<void> _cancelListening() async {
    await _speech.cancel();
    VoiceSound.end();
    if (mounted) {
      setState(() {
        _listening = false;
        _heard = '';
      });
    }
  }

  /// Done: hand the list back to be shown as products.
  Future<void> _showProducts() async {
    if (_finished) return;
    _commitHeard();
    if (_items.isEmpty) {
      await _cancelListening();
      return;
    }
    _finished = true;
    await _speech.stop();
    VoiceSound.end(success: true);
    if (mounted) {
      Navigator.pop(
        context,
        VoiceSearchResult.terms([
          for (final item in _items)
            if (!_leaving.contains(item)) item.text,
        ]),
      );
    }
  }

  // ---- matching -----------------------------------------------------------

  static String _capitalise(String text) => text
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  /// The product that best fits [phrase], preferring ones with a photo.
  Product? _matchFor(String phrase) {
    final q = phrase.toLowerCase().trim();
    if (q.isEmpty) return null;
    final tokens = q.split(RegExp(r'\s+'));
    final products = context.read<ProductProvider>().allProducts;
    Product? best;
    var bestScore = 0;
    for (final p in products) {
      if ((p.imageUrl ?? '').isEmpty) continue;
      final name = p.name.toLowerCase();
      final hay = '$name ${p.brand ?? ''} ${p.category}'.toLowerCase();
      var score = 0;
      if (name.contains(q)) {
        score = 3;
      } else if (tokens.every(hay.contains)) {
        score = 2;
      } else if (tokens.any((t) => t.length > 2 && name.contains(t))) {
        score = 1;
      }
      if (score > bestScore) {
        best = p;
        bestScore = score;
      }
    }
    return best;
  }

  // ---- layout -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screen = MediaQuery.of(context).size.height;
    final hasItems = _items.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circleButton(
          size: 56,
          color: _ink,
          icon: Iconsax.close_circle_copy,
          iconColor: Colors.white,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 14),
        // The panel changes height when the first item lands (tips → list)
        // and when the list is cleared (list → tips). AnimatedSize glides
        // between the two instead of snapping. It is not an AnimatedContainer
        // on purpose: that would tween the height between a number and null,
        // and halfway through the child is already the full-height Column
        // with an Expanded in it, so the Expanded has no height to take and
        // the sheet throws. AnimatedSize lays the new state out at its own
        // size and only animates the clip around it.
        AnimatedSize(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: Container(
            height: hasItems ? null : screen * 0.74,
            constraints: BoxConstraints(maxHeight: screen * 0.74),
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              color: Colors.white,
            ),
            child: Stack(
              children: [
                // The warm wash behind the tips fades out as the list arrives,
                // and shifts shade while listening, rather than switching.
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: hasItems ? 0 : 1,
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _listening
                              ? const [
                                  Color(0xFFFFD9A8),
                                  Color(0xFFFFF1DC),
                                  Colors.white,
                                ]
                              : const [
                                  Color(0xFFFFD8BC),
                                  Color(0xFFFFF6EF),
                                  Colors.white,
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                // While the mic is open, a soft glow flows along the bottom
                // and brightens with the voice, so listening looks alive.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 260,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _listening ? 1 : 0,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                      child: AnimatedBuilder(
                        animation: _loop,
                        builder: (context, _) => CustomPaint(
                          painter: _ListeningGlowPainter(
                            phase: _loop.value,
                            level: _levels.last,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The content itself fades in whenever the panel swaps between
                // the tips and the list, so the new state arrives, not appears.
                TweenAnimationBuilder<double>(
                  key: ValueKey(hasItems),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  builder: (context, t, child) =>
                      Opacity(opacity: t, child: child),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize:
                          hasItems ? MainAxisSize.min : MainAxisSize.max,
                      children: [
                        if (hasItems) ...[
                          Flexible(child: _buildList()),
                          _buildShowProducts(),
                        ] else ...[
                          const SizedBox(height: 56),
                          Text(
                            l10n.voiceTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          Expanded(
                            child: _listening && _heard.isNotEmpty
                                ? _buildHeard()
                                : _buildTips(),
                          ),
                        ],
                        if (_problem != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                            child: Text(
                              _problem!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFFB3261E),
                              ),
                            ),
                          ),
                        _listening ? _buildListeningBar() : _buildActions(),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // The shopping list, once something has been said.
  Widget _buildList() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.voiceShoppingList,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
              Pressable(
                  child: GestureDetector(
                onTap: _clearAll,
                child: Text(
                  l10n.voiceClearAll,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: AppConstants.primaryColor,
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < _items.length; i++) _buildRow(i),
                if (_listening && _heard.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      '$_heard…',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.black45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final item = _items[index];
    final image = item.match?.imageUrl;
    final leaving = _leaving.contains(item);
    // New rows slide in from the right; a removed row fades and folds its
    // height away, so the rows below glide up instead of jumping.
    return TweenAnimationBuilder<double>(
      key: ObjectKey(item),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset((1 - t) * 40, 0), child: child),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: leaving ? 0 : 1),
        duration: _leaveDuration,
        curve: Curves.easeInOutCubic,
        builder: (context, shown, child) => ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: shown,
            child: Opacity(opacity: shown, child: child),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              Divider(height: 1, color: Colors.black.withOpacity(0.08)),
            _rowBody(index, item, image),
          ],
        ),
      ),
    );
  }

  Widget _rowBody(int index, _ListItem item, String? image) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: (image != null && image.isNotEmpty)
                ? AppNetworkImage(
                    image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _placeholderThumb(),
                  )
                : _placeholderThumb(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                ),
                if (item.match == null)
                  Text(
                    l10n.voiceNoMatch,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.black45,
                    ),
                  ),
              ],
            ),
          ),
          if (item.match != null) const SizedBox(width: 8),
          Pressable(
              child: GestureDetector(
            onTap: () => _remove(item),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Iconsax.trash_copy,
                color: Colors.black38,
                size: 26,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _placeholderThumb() =>
      const Icon(Iconsax.shopping_bag, color: Colors.black26, size: 24);

  Widget _buildShowProducts() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
      child: Pressable(
          child: GestureDetector(
        onTap: _showProducts,
        child: Container(
          height: 48,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            l10n.voiceShowProducts,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildTips() {
    final l10n = AppLocalizations.of(context);
    final tips = _tips(l10n);
    // Staggered left and right, like chat bubbles.
    const offsets = [
      EdgeInsets.only(left: 28, right: 90),
      EdgeInsets.only(left: 70, right: 28),
      EdgeInsets.only(left: 48, right: 100),
      EdgeInsets.only(left: 90, right: 24),
    ];
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _loop]),
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tips.length; i++)
                () {
                  // Each bubble pops in a beat after the last, then floats.
                  final start = i * 0.17;
                  final t = Interval(
                    start,
                    start + 0.45,
                    curve: Curves.easeOutBack,
                  ).transform(_enter.value);
                  final float = math.sin(2 * math.pi * _loop.value + i * 1.4);
                  return Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 28 + float * 3.5),
                      child: Transform.scale(
                        scale: 0.9 + 0.1 * t.clamp(0.0, 1.0),
                        child: Padding(
                          padding:
                              offsets[i].add(const EdgeInsets.only(bottom: 14)),
                          child: Align(
                            alignment: i.isEven
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: _bubble(tips[i].$1, tips[i].$2),
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          );
        },
      ),
    );
  }

  Widget _bubble(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3B3B3B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          _heard,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 26,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final l10n = AppLocalizations.of(context);
    if (_pickingPhoto) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _labelled(
            l10n.voiceCamera,
            _circleButton(
              size: 78,
              color: Colors.white,
              icon: Iconsax.camera_copy,
              iconColor: _ink,
              border: true,
              onTap: () => Navigator.pop(
                context,
                const VoiceSearchResult.photo(ImageSource.camera),
              ),
            ),
          ),
          const SizedBox(width: 36),
          _labelled(
            l10n.voiceGallery,
            _circleButton(
              size: 78,
              color: Colors.white,
              icon: Iconsax.gallery,
              iconColor: _ink,
              border: true,
              onTap: () => Navigator.pop(
                context,
                const VoiceSearchResult.photo(ImageSource.gallery),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _labelled(
          l10n.voiceUpload,
          _circleButton(
            size: 78,
            color: Colors.white,
            icon: Iconsax.camera_copy,
            iconColor: _ink,
            border: true,
            onTap: () => setState(() => _pickingPhoto = true),
          ),
        ),
        const SizedBox(width: 36),
        _labelled(
          l10n.voiceSpeak,
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Two rings that swell and fade, out of step with each other.
                for (final phase in const [0.0, 0.5])
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _loop,
                      builder: (context, _) {
                        final v = (_loop.value + phase) % 1.0;
                        return Container(
                          width: 78 * (1 + 0.55 * v),
                          height: 78 * (1 + 0.55 * v),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.primaryColor
                                .withOpacity(0.16 * (1 - v)),
                          ),
                        );
                      },
                    ),
                  ),
                _circleButton(
                  size: 78,
                  color: _ink,
                  icon: Iconsax.microphone_2,
                  iconColor: Colors.white,
                  onTap: _start,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListeningBar() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.voiceListening,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4F63),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 300,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _circleButton(
                size: 62,
                color: const Color(0xFFF1F1F4),
                icon: Iconsax.close_circle_copy,
                iconColor: _ink,
                onTap: _cancelListening,
              ),
              Expanded(child: _buildWave()),
              _circleButton(
                size: 62,
                color: AppConstants.primaryColor,
                icon: Iconsax.tick_circle,
                iconColor: Colors.white,
                onTap: _showProducts,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWave() {
    return SizedBox(
      height: 46,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final level in _levels)
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 3,
              height: 5 + 38 * level,
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor
                    .withOpacity(0.35 + 0.65 * level),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _labelled(String label, Widget button) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4F63),
          ),
        ),
        const SizedBox(height: 10),
        button,
      ],
    );
  }

  Widget _circleButton({
    required double size,
    required Color color,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool border = false,
  }) {
    return Pressable(
        child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color,
          border: border
              ? Border.all(
                  color: Colors.black.withOpacity(0.08), width: 1.5)
              : null,
          boxShadow: border
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.4),
      ),
    ));
  }
}

/// The glow along the bottom of the sheet while it listens: a few soft,
/// coloured light pools drifting side to side, fading out towards the top,
/// and swelling with the voice ([level] is the latest mic level, 0–1).
class _ListeningGlowPainter extends CustomPainter {
  final double phase;
  final double level;

  const _ListeningGlowPainter({required this.phase, required this.level});

  static const _pools = [
    // colour, speed, horizontal offset, base radius (share of width)
    (Color(0xFFFF6A00), 1.0, 0.0, 0.62),
    (Color(0xFFFF4D8D), -1.0, 0.33, 0.52),
    (Color(0xFFFFB300), 2.0, 0.66, 0.46),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final swell = 0.85 + 0.35 * level.clamp(0.0, 1.0);
    for (final (color, speed, offset, radius) in _pools) {
      final t = 2 * math.pi * (phase * speed + offset);
      final center = Offset(
        size.width * (0.5 + 0.38 * math.sin(t)),
        size.height * (1.0 - 0.08 * math.cos(t)),
      );
      final r = size.width * radius * swell;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.42 + 0.25 * level.clamp(0.0, 1.0)),
            color.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_ListeningGlowPainter old) =>
      old.phase != phase || old.level != level;
}
