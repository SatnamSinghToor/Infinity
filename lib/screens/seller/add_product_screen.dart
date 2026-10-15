import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase/supabase.dart' show FileOptions;

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/background_removal_service.dart';
import '../../services/product_description_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../../widgets/category_picker_sheet.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/role_common.dart';
import '../../utils/safe_state.dart';
import 'package:provider/provider.dart';
import '../../widgets/pressable.dart';

class AddProductScreen extends StatefulWidget {
  /// When editing an existing product, its full row (as loaded by the
  /// seller dashboard's product list select). Null when adding a new one.
  final Map<String, dynamic>? existingProduct;

  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  bool get _isEditing => widget.existingProduct != null;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _unitController = TextEditingController(text: '1 pc');
  final _stockController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  /// The other sizes this product is sold in (500 GM, 1 KG…), each with its
  /// own price, MRP and stock — what the buyer picks from in the Choose
  /// Variant sheet.
  final List<_VariantDraft> _variants = [];

  /// Saved sizes the seller removed here; deleted when the product saves.
  final List<String> _removedVariantIds = [];
  bool _variantsFailed = false;

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _brands = [];
  String? _selectedBrandName;

  // A product is sold under the seller's own business name (their store
  // name) unless they pick a company brand (Apple, Samsung…).
  String? _myStoreName;
  bool _useCompanyBrand = false;
  List<String> _highlights = [];

  /// The product's photos in order; the first is the main one.
  final List<_PhotoSlot> _photos = [];
  static const _maxPhotos = 5;

  // The switch chooses, for every new photo, whether the cut-out or the
  // original gets saved, so it can be flipped without picking again.
  bool _removeBackground = true;
  bool _isRemovingBackground = false;

  bool _isLoadingCategories = true;

  /// Whether the lists that fill this form (categories, brands) could not be
  /// fetched. Without them the form cannot be filled in, so it says so and
  /// offers to try again instead of showing an empty chooser.
  bool _optionsFailed = false;
  bool _isGeneratingDescription = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  /// Whether the last answer from the AI writer fell short of the 700-word
  /// floor. The floor is the whole point of the feature
  /// (`ProductDescriptionAi.minWords` / `.maxWords`), so a page that ran out of
  /// the writer's time budget is said aloud instead of passed off as finished —
  /// and the button becomes "Add more with AI", because another tap continues
  /// from what is already in the box. It clears itself once the count is there,
  /// whoever got it there.
  bool _descriptionShort = false;

  /// How many words are in the box, kept live against the rule.
  int _descriptionWords = 0;

  /// Why the last tap failed, in one line, kept on screen until it is dealt
  /// with. A snackbar fades in four seconds and a description takes a minute:
  /// the seller needs to be able to go back and read it, and to retry from
  /// there.
  String? _descriptionError;

  /// Whether that last line is worth tapping again. True for everything the
  /// provider can be waited out; false for the two reasons that are this
  /// project's own setup, where the same call returns the same wall.
  bool _descriptionRetry = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProduct;
    if (existing != null) {
      _nameController.text = existing['name'] as String? ?? '';
      _priceController.text = '${existing['price'] ?? ''}';
      _mrpController.text = existing['mrp'] != null ? '${existing['mrp']}' : '';
      _unitController.text = existing['unit'] as String? ?? '1 pc';
      _stockController.text = '${existing['stock'] ?? 0}';
      _descriptionController.text = existing['description'] as String? ?? '';
      _selectedCategoryId = existing['category_id'] as String?;
      _selectedBrandName = existing['brand'] as String?;
      _useCompanyBrand = (_selectedBrandName ?? '').trim().isNotEmpty;
      final urls = [
        for (final u in (existing['image_urls'] as List?) ?? const [])
          if (u is String && u.isNotEmpty) u,
      ];
      final main = existing['image_url'] as String?;
      if (urls.isEmpty && main != null && main.isNotEmpty) urls.add(main);
      _photos.addAll(urls.map((u) => _PhotoSlot(url: u)));
      // The stored list is `dynamic`, and a cast of the whole list only
      // throws when the chips paint it — in the middle of the screen.
      _highlights =
          ProductDescriptionAi.highlightsFrom(existing['about_highlights']);
    }
    _descriptionController.addListener(_onDescriptionChanged);
    _descriptionWords =
        ProductDescriptionAi.countWords(_descriptionController.text);
    _loadCategories();
    _loadBrands();
    _loadMyStoreName();
    if (existing != null) _loadVariants(existing['id'] as String);
  }

  Future<void> _loadVariants(String productId) async {
    try {
      final rows = await SupabaseService.client
          .from('product_variants')
          .select('id, name, price, mrp, stock_qty')
          .eq('product_id', productId)
          .order('price');
      safeSetState(() {
        _variantsFailed = false;
        _variants.addAll(rows.map(_VariantDraft.fromRow));
      });
    } catch (e) {
      // Saving without them loaded would look like the sizes were gone;
      // the section says so instead.
      debugPrint('Product sizes load failed: $e');
      safeSetState(() => _variantsFailed = true);
    }
  }

  void _addVariant() => safeSetState(() => _variants.add(_VariantDraft()));

  void _removeVariant(_VariantDraft v) {
    safeSetState(() {
      _variants.remove(v);
      if (v.id != null) _removedVariantIds.add(v.id!);
    });
    v.dispose();
  }

  /// Writes the sizes after the product itself is saved: removed ones are
  /// deleted, changed ones updated, new ones added. A row without a name
  /// or a price is left out rather than saved half-filled.
  Future<void> _saveVariants(String productId) async {
    final client = SupabaseService.client;
    if (_removedVariantIds.isNotEmpty) {
      await client
          .from('product_variants')
          .delete()
          .inFilter('id', _removedVariantIds);
    }
    for (final v in _variants) {
      final name = v.name.text.trim();
      final price = double.tryParse(v.price.text.trim()) ?? 0;
      if (name.isEmpty || price <= 0) continue;
      final mrp = double.tryParse(v.mrp.text.trim());
      final row = {
        'product_id': productId,
        'name': name,
        'price': price,
        'mrp': (mrp != null && mrp > price) ? mrp : null,
        'stock_qty': int.tryParse(v.stock.text.trim()) ?? 0,
        'is_active': true,
      };
      if (v.id != null) {
        await client.from('product_variants').update(row).eq('id', v.id!);
      } else {
        await client.from('product_variants').insert(row);
      }
    }
  }

  /// Keeps the word count under the description box live, and lets the
  /// "still short" notice go away as soon as the page reaches 700 words —
  /// whether the writer got it there or the seller did.
  void _onDescriptionChanged() {
    final words = ProductDescriptionAi.countWords(_descriptionController.text);
    if (words == _descriptionWords && !_descriptionShort) return;
    safeSetState(() {
      _descriptionWords = words;
      if (_descriptionShort && words >= ProductDescriptionAi.minWords) {
        _descriptionShort = false;
      }
    });
  }

  Future<void> _loadMyStoreName() async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await SupabaseService.client
          .from('stores')
          .select('name')
          .eq('owner_id', uid)
          .limit(1);
      final name = rows.isEmpty ? null : (rows.first['name'] as String?);
      if (mounted && name != null && name.trim().isNotEmpty) {
        safeSetState(() => _myStoreName = name.trim());
      }
    } catch (_) {
      // Only a suggestion for the brand field: the seller can still type
      // their own name, so this one is not worth interrupting them for.
      debugPrint('store name lookup failed');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    _priceController.dispose();
    _mrpController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _descriptionController
      ..removeListener(_onDescriptionChanged)
      ..dispose();
    super.dispose();
  }

  /// A category a product can sit in: a sub-category, or a main category
  /// that has no sub-categories of its own.
  bool _isPickable(Map<String, dynamic> c) {
    if (c['parent_id'] != null) return true;
    return !_categories.any((x) => x['parent_id'] == c['id']);
  }

  /// The categories as the picker shows them.
  CategoryTree get _categoryTree =>
      CategoryTree.from(_categories.map(PickerCategory.fromRow).toList());

  Future<void> _chooseCategory() async {
    final id = await showCategoryPicker(
      context,
      tree: _categoryTree,
      selectedId: _selectedCategoryId,
    );
    if (id != null) safeSetState(() => _selectedCategoryId = id);
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await SupabaseService.client
          .from('categories')
          .select('id, name, parent_id')
          .eq('is_active', true)
          .order('sort_order');
      safeSetState(() {
        _categories = List<Map<String, dynamic>>.from(rows);
        if (_categories.isNotEmpty && _selectedCategoryId == null) {
          // The first one that can be picked: a sub-category, or a main
          // category that has none.
          final pickable = _categories.where(_isPickable).toList();
          _selectedCategoryId = (pickable.isNotEmpty
              ? pickable.first
              : _categories.first)['id'] as String;
        }
      });
    } catch (_) {
      safeSetState(() => _optionsFailed = true);
    }
    safeSetState(() => _isLoadingCategories = false);
  }

  /// The category chooser: a spinner while the list is on its way, a way to
  /// try again if it never arrived, and the dropdown once it is here.
  Widget _categoryField() {
    final l10n = AppLocalizations.of(context);
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_optionsFailed && _categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Iconsax.warning_2,
              size: 18,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.addProductCategoriesFailed,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Pressable(
                child: TextButton(
              onPressed: () {
                safeSetState(() => _optionsFailed = false);
                _loadCategories();
              },
              child: Text(
                l10n.addProductTryAgain,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
          ],
        ),
      );
    }
    // A field that opens the picker, and says both where the product goes and
    // the group that sits in: "Toys & Games · Kids".
    final tree = _categoryTree;
    final chosen = tree.byId[_selectedCategoryId];
    final group = chosen == null ? null : tree.parentOf(chosen);
    return InkWell(
      onTap: _chooseCategory,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: chosen == null,
        decoration: InputDecoration(
          labelText: l10n.addProductCategoryLabel,
          hintText: l10n.addProductCategoryChoose,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: chosen == null
            ? null
            : Text.rich(
                TextSpan(
                  text: chosen.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppConstants.textPrimaryColor,
                  ),
                  children: [
                    if (group != null)
                      TextSpan(
                        text: '  ·  ${group.name}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  /// Brand names to suggest: the `brands` table plus brands already used on
  /// products, without duplicates (ignoring case), A–Z.
  List<String> _brandSuggestions() {
    final byKey = <String, String>{};
    for (final name in AppConstants.popularBrands) {
      byKey[name.toLowerCase()] = name;
    }
    for (final b in _brands) {
      final name = (b['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) byKey[name.toLowerCase()] = name;
    }
    for (final p in context.read<ProductProvider>().allProducts) {
      final name = p.brand?.trim();
      if (name != null && name.isNotEmpty) {
        byKey.putIfAbsent(name.toLowerCase(), () => name);
      }
    }
    return byKey.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<void> _loadBrands() async {
    try {
      final rows = await SupabaseService.client
          .from('brands')
          .select('id, name')
          .order('name');
      safeSetState(() => _brands = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      // Brands are only suggestions; the category load reports the failure
      // for both, since that list is the one the form cannot do without.
      debugPrint('brands lookup failed');
    }
  }

  Future<void> _pickImages() async {
    final room = _maxPhotos - _photos.length;
    if (room <= 0) return;
    final picked = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 100,
    );
    if (picked.isEmpty) return;
    final slots = <_PhotoSlot>[];
    for (final file in picked.take(room)) {
      slots
          .add(_PhotoSlot(original: await file.readAsBytes(), path: file.path));
    }
    if (!mounted) return;
    safeSetState(() => _photos.addAll(slots));
    if (picked.length > room) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)
                    .addProductPhotosSkipped(_maxPhotos),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      );
    }
    if (_removeBackground) await _runBackgroundRemoval();
  }

  void _removePhoto(_PhotoSlot slot) =>
      safeSetState(() => _photos.remove(slot));

  /// Makes [slot] the main photo (the one shown on cards and listings).
  void _makeMain(_PhotoSlot slot) => safeSetState(() {
        _photos.remove(slot);
        _photos.insert(0, slot);
      });

  /// Cuts the background out of every new photo that hasn't been done yet,
  /// one after another.
  Future<void> _runBackgroundRemoval() async {
    if (_isRemovingBackground) return;
    if (!BackgroundRemovalService.isSupported) return;

    safeSetState(() => _isRemovingBackground = true);
    var failed = false;
    while (mounted) {
      final slot = _photos
          .where((p) => p.path != null && p.cutout == null && !p.cutoutTried)
          .firstOrNull;
      if (slot == null) break;
      slot.cutoutTried = true;
      final cutout =
          await BackgroundRemovalService.removeBackground(slot.path!);
      if (!mounted) return;
      if (cutout == null) failed = true;
      // The photo may have been removed while it was being cut out.
      safeSetState(() => slot.cutout = cutout);
    }
    if (!mounted) return;
    safeSetState(() => _isRemovingBackground = false);
    if (failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).addProductBgSomeFailed,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

  /// Uploads the new photos to the `product-images` bucket under this
  /// seller's own folder (required by its storage policy) and returns the
  /// public URLs of all photos in order. Throws if an upload fails, so the
  /// product isn't saved with a photo missing.
  Future<List<String>> _uploadPhotos(String sellerId) async {
    final urls = <String>[];
    safeSetState(() => _isUploadingImage = true);
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < _photos.length; i++) {
        final slot = _photos[i];
        if (slot.url != null) {
          urls.add(slot.url!);
          continue;
        }
        // A cutout has a transparent background, which JPEG can't hold.
        final useCutout = _removeBackground && slot.cutout != null;
        final bytes = useCutout ? slot.cutout! : slot.original!;
        final path = '$sellerId/$stamp-$i.${useCutout ? 'png' : 'jpg'}';
        await SupabaseService.client.storage
            .from('product-images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: useCutout ? 'image/png' : 'image/jpeg',
              ),
            );
        urls.add(
          SupabaseService.client.storage
              .from('product-images')
              .getPublicUrl(path),
        );
      }
      return urls;
    } finally {
      if (mounted) safeSetState(() => _isUploadingImage = false);
    }
  }

  /// Whether the AI button has to wait: while the writer is working, a second
  /// tap would start a second page and a save would store half of one.
  bool get _aiBlocked => _isGeneratingDescription || _isSaving;

  /// The button's word: working, or extending a page that stopped under the
  /// floor, or writing one from the top.
  String _aiButtonLabel(AppLocalizations l10n) {
    if (_isGeneratingDescription) return l10n.addProductGenerating;
    if (_descriptionShort) return l10n.addProductExtend;
    return l10n.addProductGenerate;
  }

  /// The line under the box: what the writer is doing while it does it, and
  /// how many words there are against the 700 to 1500 the feature is built
  /// around once there is an answer.
  String _descriptionStatus(AppLocalizations l10n) {
    if (_isGeneratingDescription) return l10n.addProductWritingHelp;
    return l10n.addProductWordCount(
      _descriptionWords,
      ProductDescriptionAi.minWords,
      ProductDescriptionAi.maxWords,
    );
  }

  /// Grey for a page inside the rule, the app's own colour for one the writer
  /// left under it — so the seller sees the gap without a dialog about it.
  TextStyle _descriptionStatusStyle() {
    if (!_descriptionShort) {
      return TextStyle(fontSize: 12, color: Colors.grey[600]);
    }
    return const TextStyle(
      fontSize: 12,
      color: AppConstants.primaryColor,
      fontWeight: FontWeight.w600,
    );
  }

  /// Asks the AI writer for the description, and puts the answer in the box.
  ///
  /// The seller's own words are only ever replaced by a description that
  /// arrived: a failure leaves the box exactly as it was, which is the
  /// opposite of the first version of this button, where an answer without a
  /// `description` in it wrote an empty string over what had just been typed.
  /// What the writer is asked for is 700 to 1500 words, and a reply under the
  /// floor is reported as such — with a second tap that continues from the
  /// page instead of starting it again.
  Future<void> _generateDescription() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      roleSay(context, l10n.addProductErrName);
      return;
    }

    safeSetState(() {
      _isGeneratingDescription = true;
      _descriptionError = null;
      // Whether the next line will come with a retry button is decided by this
      // answer, not by the last one, so the flag is cleared with the error.
      _descriptionRetry = true;
    });
    try {
      final categoryName = _categories.firstWhere(
        (c) => c['id'] == _selectedCategoryId,
        orElse: () => const {},
      )['name'] as String?;

      final draft = await ProductDescriptionAi.write(
        name: name,
        category: categoryName ?? '',
        unit: _unitController.text.trim(),
        notes: _descriptionController.text.trim(),
        store: _myStoreName ?? '',
      );
      if (!mounted) return;
      // Assigning the text first lets the listener refresh the count; the
      // writer's own flags are settled after it, so a page that stopped short
      // still says so once.
      _descriptionController.text = draft.description;
      safeSetState(() {
        if (draft.highlights.isNotEmpty) _highlights = draft.highlights;
        _descriptionWords = ProductDescriptionAi.countWords(draft.description);
        _descriptionShort = !draft.inRange;
      });
      if (!draft.inRange) {
        roleSay(context, l10n.addProductGenerateShort(draft.words));
      } else if (!draft.fromModel) {
        // The page is publishable either way; what the seller is told depends
        // on why the model did not write it, because two of those reasons are
        // waited out and two of them are fixed in somebody's settings.
        roleSay(context, _fallbackLine(l10n, draft.fallbackReason));
      }
    } on ProductDescriptionFailure catch (failure) {
      debugPrint('generate description failed: $failure');
      if (mounted) {
        safeSetState(() {
          _descriptionError = _describeFailure(failure, l10n);
          _descriptionRetry = _canRetry(failure.problem);
        });
      }
    } catch (e) {
      debugPrint('generate description failed: $e');
      if (mounted) {
        safeSetState(() => _descriptionError = l10n.addProductGenerateFailed);
      }
    } finally {
      if (mounted) safeSetState(() => _isGeneratingDescription = false);
    }
  }

  /// One sentence per reason the writer can give, in the seller's language and
  /// about their world — the status code stays in the log. `message` is what
  /// the function itself said; its refusals are written for a person, so they
  /// are shown as they are.
  String _describeFailure(
    ProductDescriptionFailure failure,
    AppLocalizations l10n,
  ) {
    return switch (failure.problem) {
      ProductDescriptionProblem.needName => l10n.addProductErrName,
      ProductDescriptionProblem.offline => l10n.addProductGenerateOffline,
      ProductDescriptionProblem.timedOut => l10n.addProductGenerateSlow,
      ProductDescriptionProblem.notSignedIn => l10n.addProductGenerateSignIn,
      ProductDescriptionProblem.notDeployed => l10n.addProductGenerateMissing,
      ProductDescriptionProblem.misconfigured =>
        l10n.addProductGenerateMisconfigured,
      ProductDescriptionProblem.crashed => l10n.addProductGenerateCrashed,
      ProductDescriptionProblem.rateLimited =>
        l10n.addProductGenerateRateLimited,
      ProductDescriptionProblem.unavailable => l10n.addProductGenerateBusy,
      ProductDescriptionProblem.unreachable => l10n.addProductGenerateGarbled,
      ProductDescriptionProblem.empty => l10n.addProductGenerateEmpty,
      ProductDescriptionProblem.refused =>
        failure.message ?? l10n.addProductGenerateFailed,
    };
  }

  /// Why the box holds the seller's own words instead of the model's page.
  /// The server says which of these it was, in one word, and each gets its own
  /// sentence: a provider that is slow or down is worth another tap in a
  /// minute, a key that was refused is not worth one at all, and saying the
  /// second thing with the words of the first is how a settings mistake gets
  /// retried for a week.
  String _fallbackLine(AppLocalizations l10n, String reason) {
    return switch (reason) {
      'bad_key' => l10n.addProductGenerateAiRefused,
      'bad_address' || 'bad_request' => l10n.addProductGenerateAiAddress,
      'timeout' ||
      'upstream' ||
      'not_json' ||
      'provider_limit' =>
        l10n.addProductGenerateAiDown,
      _ => l10n.addProductGenerateFromNotes,
    };
  }

  /// Whether another tap can change the answer. Only the two reasons that are
  /// about this project's own setup are not: everything else is a provider
  /// being busy, which is exactly what a second tap is for.
  bool _canRetry(ProductDescriptionProblem problem) {
    const hopeless = [
      ProductDescriptionProblem.misconfigured,
      ProductDescriptionProblem.crashed,
    ];
    return !hopeless.contains(problem);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final description = _descriptionController.text.trim();

    if (name.isEmpty || price <= 0 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addProductErrRequired,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isRemovingBackground) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.addProductWaitBg,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
      return;
    }

    safeSetState(() => _isSaving = true);
    try {
      final sellerId = context.read<AuthProvider>().userId;
      final mrp = double.tryParse(_mrpController.text);
      final imageUrls = await _uploadPhotos(sellerId);
      final data = {
        'category_id': _selectedCategoryId,
        'name': name,
        'description': description.isEmpty ? name : description,
        'price': price,
        if (mrp != null && mrp > price) 'mrp': mrp,
        'unit': _unitController.text.trim().isEmpty
            ? '1 pc'
            : _unitController.text.trim(),
        'stock': int.tryParse(_stockController.text) ?? 0,
        'about_highlights': _highlights,
        // The first photo is the main one shown on cards and listings.
        if (imageUrls.isNotEmpty) 'image_url': imageUrls.first,
        if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
        // Empty = sold under the seller's own store name.
        'brand': (_myStoreName == null || _useCompanyBrand)
            ? _selectedBrandName
            : null,
      };

      String productId;
      if (_isEditing) {
        productId = widget.existingProduct!['id'] as String;
        await SupabaseService.client
            .from('products')
            .update(data)
            .eq('id', productId);
      } else {
        final created = await SupabaseService.client
            .from('products')
            .insert({
              ...data,
              'seller_id': sellerId,
              'is_active': true,
            })
            .select('id')
            .single();
        productId = created['id'] as String;
      }
      if (!_variantsFailed) await _saveVariants(productId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addProductSaveFailed,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) safeSetState(() => _isSaving = false);
    }
  }

  /// "Sizes": one small card per size with its name, price, MRP and stock,
  /// and a button to add another.
  Widget _buildVariants(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addProductVariantsTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            _variantsFailed
                ? l10n.addProductVariantsFailed
                : l10n.addProductVariantsHelp,
            style: TextStyle(
              fontSize: 12,
              color: _variantsFailed ? Colors.red : Colors.grey[600],
            ),
          ),
          for (final v in _variants) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: v.name,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: l10n.addProductVariantName,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: v.price,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.addProductPriceLabel,
                                  prefixText: '₹',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: v.mrp,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.addProductMrpLabel,
                                  prefixText: '₹',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: v.stock,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.addProductStockLabel,
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.addProductVariantRemove,
                    onPressed: () => _removeVariant(v),
                    icon: const Icon(Iconsax.trash, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Pressable(
            child: OutlinedButton.icon(
              onPressed: _variantsFailed ? null : _addVariant,
              icon: const Icon(Iconsax.add_copy, size: 18),
              label: Text(
                l10n.addProductVariantAdd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: const BorderSide(color: AppConstants.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The photo strip: every photo as a tile (the first is the main one), a
  /// tile to add more, and a big prompt while there are none.
  Widget _buildPhotos() {
    final l10n = AppLocalizations.of(context);
    final busy = _isUploadingImage || _isRemovingBackground;
    if (_photos.isEmpty) {
      return Pressable(
          child: GestureDetector(
        onTap: busy ? null : _pickImages,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.gallery_add, size: 32, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                l10n.addProductTapToAdd,
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                l10n.addProductUpTo(_maxPhotos),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < _photos.length; i++)
                _photoTile(_photos[i], main: i == 0),
              if (_photos.length < _maxPhotos)
                Pressable(
                    child: GestureDetector(
                  onTap: busy ? null : _pickImages,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.gallery_add,
                          size: 26,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.addProductAddMore,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.addProductPhotosHelp(_photos.length, _maxPhotos),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _photoTile(_PhotoSlot slot, {required bool main}) {
    final l10n = AppLocalizations.of(context);
    final pending = _isRemovingBackground &&
        _removeBackground &&
        slot.path != null &&
        slot.cutout == null &&
        !slot.cutoutTried;
    final ImageProvider image = slot.url != null
        ? CachedNetworkImageProvider(slot.url!)
        : MemoryImage(
            _removeBackground && slot.cutout != null
                ? slot.cutout!
                : slot.original!,
          );
    return GestureDetector(
      onTap: main ? null : () => _makeMain(slot),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: main ? AppConstants.primaryColor : Colors.grey.shade300,
            width: main ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(image: image, fit: BoxFit.contain),
              if (pending)
                Container(
                  color: Colors.black45,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (main)
                Positioned(
                  left: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    color: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      l10n.addProductMainBadge,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: (_isUploadingImage || _isSaving)
                      ? null
                      : () => _removePhoto(slot),
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(
            _isEditing ? l10n.addProductEditTitle : l10n.addProductTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotos(),
            if (BackgroundRemovalService.isSupported)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.addProductRemoveBg),
                  subtitle: Text(
                    _removeBackground
                        ? l10n.addProductRemoveBgOn
                        : l10n.addProductRemoveBgOff,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  value: _removeBackground,
                  activeColor: AppConstants.primaryColor,
                  onChanged: _isRemovingBackground
                      ? null
                      : (value) {
                          safeSetState(() => _removeBackground = value);
                          // Switched on after picking: cut out the photos
                          // that are already there.
                          if (value) _runBackgroundRemoval();
                        },
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.addProductNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            _categoryField(),
            const SizedBox(height: 14),
            // Brand: your own business name, or a big company's brand.
            Text(
              l10n.addProductBrandLabel,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            if (_myStoreName != null) ...[
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.addProductMyStore(_myStoreName!),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: !_useCompanyBrand,
                    selectedColor:
                        AppConstants.primaryColor.withOpacity(0.15),
                    onSelected: (_) =>
                        safeSetState(() => _useCompanyBrand = false),
                  ),
                  ChoiceChip(
                    label: Text(l10n.addProductCompanyBrand,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: _useCompanyBrand,
                    selectedColor:
                        AppConstants.primaryColor.withOpacity(0.15),
                    onSelected: (_) =>
                        safeSetState(() => _useCompanyBrand = true),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (_myStoreName != null && !_useCompanyBrand)
              Text(
                l10n.addProductMyStoreNote(_myStoreName!),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            else
              // Type any company brand (Apple, Samsung, Amul…); known ones are
              // suggested. Customers see these under "Shop by Brand" on Home.
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _selectedBrandName ?? ''),
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  final all = _brandSuggestions();
                  return query.isEmpty
                      ? all
                      : all.where((b) => b.toLowerCase().contains(query));
                },
                onSelected: (value) => _selectedBrandName = value,
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (text) => _selectedBrandName =
                        text.trim().isEmpty ? null : text.trim(),
                    decoration: InputDecoration(
                      labelText: _myStoreName == null
                          ? l10n.addProductCompanyBrandOptional
                          : l10n.addProductCompanyBrand,
                      hintText: l10n.addProductBrandHint,
                      helperText: _myStoreName == null
                          ? l10n.addProductBrandHelper
                          : null,
                      helperMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.addProductPriceLabel,
                      prefixText: '₹',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _mrpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.addProductMrpLabel,
                      prefixText: '₹',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: l10n.addProductUnitLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.addProductStockLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildVariants(l10n),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.addProductDescriptionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Pressable(
                    child: TextButton.icon(
                  // A description this long is not written in a second, so the
                  // writer keeps the button to itself while it works — and
                  // saving during a run would store half a page.
                  onPressed: _aiBlocked ? null : _generateDescription,
                  icon: _isGeneratingDescription
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.magicpen, size: 16),
                  label: Text(
                    _aiButtonLabel(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
            ),
            Text(
              l10n.addProductDescriptionRule(
                ProductDescriptionAi.minWords,
                ProductDescriptionAi.maxWords,
              ),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              // A page of this length has to be readable and fixable in the
              // box it was written into: four lines showed a fifth of it.
              maxLines: 10,
              readOnly: _isGeneratingDescription,
              decoration: InputDecoration(
                hintText: l10n.addProductDescriptionHint,
                border: const OutlineInputBorder(),
              ),
            ),
            // The count, live. The rule is worth nothing if nobody can see the
            // page filling up to it, and the seller's own typing counts towards
            // it exactly as the writer's does.
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _descriptionStatus(l10n),
                style: _descriptionStatusStyle(),
              ),
            ),
            if (_descriptionError != null) ...[
              const SizedBox(height: 8),
              RoleInlineError(
                message: _descriptionError!,
                onRetry: _descriptionRetry ? _generateDescription : null,
              ),
            ],
            if (_highlights.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.addProductHighlights,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _highlights
                    .map(
                      (h) => Chip(
                        label: Text(h,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: AppControl.lg,
              child: Pressable(
                  child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? l10n.addProductUpdate
                            : l10n.addProductSave,
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

/// One photo of the product: either already saved (a [url]) or newly picked
/// ([original], and its background-free [cutout] once that's ready).
class _PhotoSlot {
  final String? url;
  final Uint8List? original;
  final String? path;
  Uint8List? cutout;

  /// Whether a cut-out was already attempted, so a failure isn't retried
  /// forever.
  bool cutoutTried = false;

  _PhotoSlot({this.url, this.original, this.path});
}

/// One size being edited: its saved row id (null until saved) and a text
/// controller for each of its fields.
class _VariantDraft {
  final String? id;
  final name = TextEditingController();
  final price = TextEditingController();
  final mrp = TextEditingController();
  final stock = TextEditingController(text: '0');

  _VariantDraft({this.id});

  factory _VariantDraft.fromRow(Map<String, dynamic> row) {
    final v = _VariantDraft(id: row['id'] as String?);
    v.name.text = (row['name'] as String?) ?? '';
    v.price.text = '${row['price'] ?? ''}';
    v.mrp.text = row['mrp'] != null ? '${row['mrp']}' : '';
    v.stock.text = '${row['stock_qty'] ?? 0}';
    return v;
  }

  void dispose() {
    name.dispose();
    price.dispose();
    mrp.dispose();
    stock.dispose();
  }
}
