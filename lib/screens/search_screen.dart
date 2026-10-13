import 'dart:async';
import 'package:duggu/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/analytics.dart';
import '../services/search_history.dart';
import '../services/visual_search_service.dart';
import '../utils/constants.dart';
import '../utils/search_match.dart';
import '../widgets/voice_search_sheet.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import '../widgets/pressable.dart';

class SearchScreen extends StatefulWidget {
  /// Search these straight away: the items said on the voice sheet.
  final List<String> initialTerms;

  /// Ask for a picture as soon as the screen opens, from the source already
  /// chosen on the voice sheet (the camera on Home).
  final ImageSource? photoSource;

  const SearchScreen({
    super.key,
    this.initialTerms = const [],
    this.photoSource,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  // Kept here, not on the ProductProvider: a search must not leave Home's
  // product grid filtered after this screen is closed.
  String _query = '';

  bool _readingPhoto = false;

  /// Waiting to record the current search: typing "milk" is one search, not
  /// four.
  Timer? _logSearch;

  // Items from a spoken shopping list; while set, the results are the
  // products for any of them. Typing clears it.
  List<String> _terms = [];

  // The shopper's own past searches, newest first, shown on the idle
  // screen. Loaded once; kept in sync locally as searches are made rather
  // than re-read from disk each time.
  List<String> _history = const [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTerms.isNotEmpty) {
      _terms = List.of(widget.initialTerms);
      _query = _terms.join(', ');
      _controller.text = _query;
    }
    final source = widget.photoSource;
    if (source != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _photoSearch(source));
    }
    SearchHistory.load().then((terms) {
      if (mounted) setState(() => _history = terms);
    });
  }

  @override
  void dispose() {
    _logSearch?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content:
              Text(message, maxLines: 1, overflow: TextOverflow.ellipsis)));
  }

  /// Mic: the same voice / photo sheet as on Home.
  Future<void> _openVoiceSheet() async {
    FocusScope.of(context).unfocus();
    final result = await showVoiceSearchSheet(context);
    if (result == null || !mounted) return;
    if (result.photo) {
      await _photoSearch(result.photoSource!);
    } else {
      _setTerms(result.terms);
    }
  }

  /// Take or pick a picture; what's printed on it and what it looks like
  /// become the search. [source] was chosen on the voice sheet, so there is
  /// no second sheet to ask.
  Future<void> _photoSearch(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    final XFile? picked;
    try {
      picked = await ImagePicker()
          .pickImage(source: source, maxWidth: 1280, imageQuality: 85);
    } catch (_) {
      _say(l10n.searchCameraFailed);
      return;
    }
    if (picked == null || !mounted) return;

    setState(() => _readingPhoto = true);
    final result = await VisualSearchService.termsFor(picked.path);
    if (!mounted) return;
    setState(() => _readingPhoto = false);

    // "The phone could not read this photo" is not "there was nothing in it":
    // the first is usually a device that has never run this before with no
    // internet for the model, and sending that customer off to take a clearer
    // photo fails the same way.
    if (result.unavailable) {
      _say(l10n.searchScannerFailed);
      return;
    }

    final provider = context.read<ProductProvider>();
    String? found;
    for (final term in result.terms) {
      if (_matching(provider, term).isNotEmpty) {
        found = term;
        break;
      }
    }
    if (found == null) {
      _say(l10n.searchNoMatch);
    } else {
      _setQuery(found);
    }
  }

  void _setTerms(List<String> terms) {
    final text = terms.join(', ');
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      _terms = List.of(terms);
      _query = text;
    });
  }

  void _setQuery(String value) {
    _terms = [];
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _query = value.trim());
  }

  /// Records the search once the typing stops. What people search for — and
  /// what finds nothing — is the stocking list the shop cannot write by
  /// itself; a row per keystroke would bury it under "m", "mi", "mil".
  void _noteSearch(ProductProvider provider) {
    _logSearch?.cancel();
    final term = _query.trim();
    if (term.length < 2) return;
    _logSearch = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Analytics.log('search', {
        'term': term,
        'results': _results(provider).length,
      });
      SearchHistory.add(term).then((saved) {
        if (mounted) setState(() => _history = saved);
      });
    });
  }

  Future<void> _clearHistory() async {
    await SearchHistory.clear();
    if (mounted) setState(() => _history = const []);
  }

  /// Products matching [_query] by name, category, brand or store, best
  /// match first. A small typo ("meggi") still finds the right product;
  /// the words that made it match are what decide the order.
  List<Product> _results(ProductProvider provider) {
    if (_terms.isEmpty) return _matching(provider, _query);
    final seen = <String>{};
    return [
      for (final term in _terms)
        for (final p in _matching(provider, term))
          if (seen.add(p.id)) p,
    ];
  }

  List<Product> _matching(ProductProvider provider, String query) {
    final words = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];
    // (product, score, its position in the shop's own order) — the position
    // breaks ties, so `List.sort`, which is not itself stable, still keeps
    // equally-scored products in the shop's order instead of shuffling them.
    final scored = <(Product, int, int)>[];
    for (var i = 0; i < provider.allProducts.length; i++) {
      final p = provider.allProducts[i];
      var total = 0;
      for (final word in words) {
        var best = fieldScore(word, p.name);
        final categoryHit = provider.categories.skip(1).any(
            (c) => fieldScore(word, c) > 0 && provider.inCategoryGroup(p, c));
        if (categoryHit) best = best > 2 ? best : 2;
        best = [best, fieldScore(word, p.category)]
            .reduce((a, b) => a > b ? a : b);
        best = [best, fieldScore(word, p.brand) - 1]
            .reduce((a, b) => a > b ? a : b);
        best = [best, fieldScore(word, p.storeName) - 1]
            .reduce((a, b) => a > b ? a : b);
        if (best <= 0) {
          total = 0;
          break; // every typed word must match something
        }
        total += best;
      }
      if (total > 0) scored.add((p, total, i));
    }
    scored.sort(
        (a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$3.compareTo(b.$3));
    return scored.map((e) => e.$1).toList();
  }

  /// Ideas to tap: the store's real categories and brands.
  List<String> _suggestions(ProductProvider provider) {
    final seen = <String>{};
    final out = <String>[];
    void add(String? text) {
      final t = text?.trim() ?? '';
      if (t.isEmpty || !seen.add(t.toLowerCase())) return;
      out.add(t);
    }

    for (final c in provider.categories.skip(1)) {
      if (provider.allProducts.any((p) => provider.inCategoryGroup(p, c))) {
        add(c);
      }
    }
    for (final p in provider.allProducts) {
      add(p.displayBrand);
    }
    return out.take(10).toList();
  }

  /// Every word a "Did you mean…?" suggestion could point to: category
  /// names, brands, and product names, each split into its own words so a
  /// query for one word of a long product name still turns up a match.
  List<String> _vocabulary(ProductProvider provider) {
    final out = <String>{};
    out.addAll(provider.categories.skip(1));
    for (final p in provider.allProducts) {
      final brand = p.displayBrand?.trim() ?? '';
      if (brand.isNotEmpty) out.add(brand);
      out.addAll(p.name.split(RegExp(r'\s+')).where((w) => w.length > 2));
    }
    return out.toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final results = _results(provider);
    final suggestions = _suggestions(provider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: TextField(
          controller: _controller,
          autofocus: widget.initialTerms.isEmpty && widget.photoSource == null,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            setState(() {
              _terms = [];
              _query = value.trim();
            });
            _noteSearch(provider);
          },
          decoration: InputDecoration(
            hintText: _readingPhoto
                ? AppLocalizations.of(context).searchReading
                : AppLocalizations.of(context).searchHint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon:
                Icon(Iconsax.search_normal_1_copy, color: Colors.grey[700]),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_query.isNotEmpty)
                  Pressable(
                      child: IconButton(
                    icon: Icon(Iconsax.close_circle_copy,
                        color: Colors.grey[700]),
                    tooltip: AppLocalizations.of(context).searchClear,
                    onPressed: () => _setQuery(''),
                  )),
                _readingPhoto
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Pressable(
                        child: IconButton(
                        icon: const Icon(
                          Iconsax.microphone_2,
                          color: Color(0xFF757575),
                        ),
                        tooltip:
                            AppLocalizations.of(context).searchByVoiceOrPhoto,
                        onPressed: _openVoiceSheet,
                      )),
              ],
            ),
            border: InputBorder.none,
            filled: false,
          ),
          style: const TextStyle(color: AppConstants.textPrimaryColor),
        ),
      ),
      body: _query.isEmpty
          ? _buildIdle(suggestions)
          : results.isEmpty
              ? _buildNoResults(provider)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        AppLocalizations.of(context)
                            .searchResultsFound(results.length),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final product = results[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(productId: product.id),
                              ),
                            ),
                            child: ProductCard(product: product),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildIdle(List<String> suggestions) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.search_normal_1_copy,
                size: 70, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              l10n.searchIdleTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.searchRecent,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 10),
                  Pressable(
                      child: GestureDetector(
                    onTap: _clearHistory,
                    child: Text(
                      l10n.searchClearRecent,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final term in _history)
                    ActionChip(
                      avatar: const Icon(Iconsax.clock, size: 15),
                      label: Text(term,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      backgroundColor: Colors.white,
                      onPressed: () => _setQuery(term),
                    ),
                ],
              ),
            ],
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.searchTrySearching,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      label:
                          Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
                      backgroundColor: Colors.white,
                      onPressed: () => _setQuery(s),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(ProductProvider provider) {
    final l10n = AppLocalizations.of(context);
    final nearest = nearestTerms(_query, _vocabulary(provider));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.search_normal_copy, size: 70, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              l10n.searchNoResultsTitle(_query),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.searchNoResultsBody,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (nearest.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                l10n.searchDidYouMean,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final term in nearest)
                    ActionChip(
                      label: Text(term,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      backgroundColor:
                          AppConstants.primaryColor.withValues(alpha: 0.08),
                      labelStyle:
                          const TextStyle(color: AppConstants.primaryColor),
                      onPressed: () => _setQuery(term),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
