import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase/supabase.dart' show FileOptions;

import '../models/festival.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../screens/admin/admin_banners_screen.dart';
import '../screens/admin/admin_festivals_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/seller/add_product_screen.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import 'edit_badge.dart';
import 'pressable.dart';

// The tools an admin gets for each kind of card in edit mode. Every list
// holds only what makes sense for that one card: first what changes how it
// looks, then what it says, then where it sits.

Future<String?> _askText(
  BuildContext context,
  String title, {
  String initial = '',
  String? note,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          if (note != null) ...[
            const SizedBox(height: 10),
            Text(note, style: const TextStyle(fontSize: 12.5)),
          ],
        ],
      ),
      actions: [
        Pressable(
            child: TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.editCancel,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        Pressable(
            child: TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child:
              Text(l10n.editSave, maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String body,
  String action,
) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        Pressable(
            child: TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.editCancel,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        Pressable(
            child: TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            action,
            style: const TextStyle(color: AppConstants.dangerColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
    ),
  );
  return ok == true;
}

/// Lets the admin pick a picture from the gallery and uploads it. Returns its
/// public address, or null if they backed out or it couldn't be uploaded.
Future<String?> _pickAndUploadPicture(
  BuildContext context,
  String folder,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 90,
  );
  if (picked == null) return null;
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.editUploading,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      duration: const Duration(seconds: 30),
    ),
  );
  try {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');
    final bytes = await picked.readAsBytes();
    final path = '$userId/$folder/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bucket = SupabaseService.client.storage.from('product-images');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    messenger.hideCurrentSnackBar();
    return bucket.getPublicUrl(path);
  } catch (_) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
            content: Text(l10n.editUploadFailed,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
    return null;
  }
}

/// Swaps [id]'s place with its neighbour in [rows] (already in order).
/// Returns false when it is already at that end.
Future<bool> _swapOrder(
  String table,
  List<Map<String, dynamic>> rows,
  String id,
  int delta,
) async {
  final i = rows.indexWhere((r) => r['id'] == id);
  final j = i + delta;
  if (i < 0 || j < 0 || j >= rows.length) return false;
  final oa = (rows[i]['sort_order'] as num?)?.toInt() ?? i;
  var ob = (rows[j]['sort_order'] as num?)?.toInt() ?? j;
  if (oa == ob) ob = delta > 0 ? oa + 1 : oa - 1;
  final client = SupabaseService.client;
  await client
      .from(table)
      .update({'sort_order': ob}).eq('id', rows[i]['id'] as String);
  await client
      .from(table)
      .update({'sort_order': oa}).eq('id', rows[j]['id'] as String);
  return true;
}

// ---------------------------------------------------------------------------
// Chips and sub-categories

Future<List<EditTool>> categoryTools(BuildContext context, String name) async {
  // Taken before the first await, so nothing below uses the context late.
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final provider = context.read<ProductProvider>();
  final client = SupabaseService.client;
  final rows = await client
      .from('categories')
      .select('id, name, parent_id, sort_order, is_active, image_url, icon_url')
      .eq('name', name)
      .limit(1);
  if (rows.isEmpty) return const [];
  final row = rows.first;
  final id = row['id'] as String;
  final parentId = row['parent_id'] as String?;
  final active = row['is_active'] as bool? ?? true;
  final imageUrl = (row['image_url'] as String?) ?? '';
  final pictureRemoved = imageUrl == ProductProvider.noPicture;
  final hasPicture = imageUrl.isNotEmpty && !pictureRemoved;
  final hasFullCard = ((row['icon_url'] as String?) ?? '').isNotEmpty;
  final isChip = parentId == null;

  void say(String text) => messenger.showSnackBar(SnackBar(
      content: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)));
  Future<void> attempt(Future<void> Function() job, String done) async {
    try {
      await job();
      await provider.reload();
      say(done);
    } catch (_) {
      say(l10n.editSaveFailed);
    }
  }

  Future<void> move(int delta) async {
    final siblings = isChip
        ? await client
            .from('categories')
            .select('id, sort_order')
            .isFilter('parent_id', null)
            .order('sort_order')
        : await client
            .from('categories')
            .select('id, sort_order')
            .eq('parent_id', parentId)
            .order('sort_order');
    var moved = false;
    await attempt(() async {
      moved = await _swapOrder(
        'categories',
        List<Map<String, dynamic>>.from(siblings),
        id,
        delta,
      );
    }, l10n.editMoved);
    if (!moved) {
      say(delta < 0 ? l10n.editAlreadyFirst : l10n.editAlreadyLast);
    }
  }

  // A sub-category card has its own picture, and the chip it sits in has the
  // banner across the top of its page; both can be changed from the card.
  String? chipName = isChip ? name : null;
  if (!isChip) {
    final parent = await client
        .from('categories')
        .select('name')
        .eq('id', parentId)
        .limit(1);
    if (parent.isNotEmpty) chipName = parent.first['name'] as String?;
  }
  final bannerTools = chipName == null
      ? const <EditTool>[]
      : (context.mounted
          ? await _pageBannerTools(context, chipName)
          : const <EditTool>[]);

  return [
    if (!isChip) ...[
      EditTool(
        icon: Iconsax.gallery,
        label: l10n.editReplaceCard,
        hint: l10n.editReplaceCardHint,
        run: () async {
          final url = await _pickAndUploadPicture(context, 'cards');
          if (url == null) return;
          await attempt(
            () => client
                .from('categories')
                .update({'icon_url': url}).eq('id', id),
            l10n.editCardReplaced,
          );
        },
      ),
      if (hasFullCard)
        EditTool(
          icon: Iconsax.refresh,
          label: l10n.editBackToNormalCard,
          hint: l10n.editBackToNormalCardHint,
          run: () => attempt(
            () => client
                .from('categories')
                .update({'icon_url': null}).eq('id', id),
            l10n.editBackToNormalCardDone,
          ),
        ),
      EditTool(
        icon: Iconsax.gallery_edit,
        label: l10n.editChangePicture,
        hint: l10n.editChangePictureHint,
        run: () async {
          final url = await _pickAndUploadPicture(context, 'cards');
          if (url == null) return;
          await attempt(
            () => client
                .from('categories')
                .update({'image_url': url}).eq('id', id),
            l10n.editPictureChanged,
          );
        },
      ),
      if (pictureRemoved)
        EditTool(
          icon: Iconsax.eye,
          label: l10n.editShowPictureAgain,
          hint: l10n.editShowPictureAgainHint,
          run: () => attempt(
            () => client
                .from('categories')
                .update({'image_url': null}).eq('id', id),
            l10n.editPictureIsBack,
          ),
        )
      else ...[
        if (hasPicture)
          EditTool(
            icon: Iconsax.refresh,
            label: l10n.editUseProductPhoto,
            hint: l10n.editUseProductPhotoHint,
            run: () => attempt(
              () => client
                  .from('categories')
                  .update({'image_url': null}).eq('id', id),
              l10n.editBackToProductPhoto,
            ),
          ),
        EditTool(
          icon: Iconsax.gallery_slash,
          label: l10n.editRemovePicture,
          hint: l10n.editRemovePictureHint,
          run: () => attempt(
            () => client
                .from('categories')
                .update({'image_url': ProductProvider.noPicture}).eq('id', id),
            l10n.editPictureRemoved,
          ),
        ),
      ],
    ],
    ...bannerTools,
    EditTool(
      icon: Iconsax.edit,
      label: l10n.editChangeName,
      run: () async {
        final value = await _askText(
          context,
          l10n.editNameTitle,
          initial: name,
          note: isChip ? l10n.editNameNote : null,
        );
        if (value == null || value.trim().isEmpty || value.trim() == name) {
          return;
        }
        await attempt(
          () => client
              .from('categories')
              .update({'name': value.trim()}).eq('id', id),
          l10n.editNameChanged,
        );
      },
    ),
    EditTool(
      icon: active ? Iconsax.eye_slash : Iconsax.eye,
      label: active ? l10n.editHideFromStore : l10n.editShowInStore,
      run: () => attempt(
        () => client
            .from('categories')
            .update({'is_active': !active}).eq('id', id),
        active ? l10n.editHidden : l10n.editShown,
      ),
    ),
    if (isChip)
      EditTool(
        icon: Iconsax.add,
        label: l10n.editAddSubCategory,
        hint: l10n.editAddSubCategoryHint,
        run: () async {
          final value = await _askText(context, l10n.editNewSubCategory);
          if (value == null || value.trim().isEmpty) return;
          await attempt(() async {
            final kids = await client
                .from('categories')
                .select('sort_order')
                .eq('parent_id', id);
            var top = 0;
            for (final k in kids) {
              final o = (k['sort_order'] as num?)?.toInt() ?? 0;
              if (o > top) top = o;
            }
            await client.from('categories').insert({
              'name': value.trim(),
              'parent_id': id,
              'sort_order': top + 1,
              'is_active': true,
            });
          }, l10n.editAdded);
        },
      ),
    EditTool(
      icon: Iconsax.arrow_left,
      label: isChip ? l10n.editMoveEarlier : l10n.editMoveUp,
      run: () => move(-1),
    ),
    EditTool(
      icon: Iconsax.arrow_right_3,
      label: isChip ? l10n.editMoveLater : l10n.editMoveDown,
      run: () => move(1),
    ),
    EditTool(
      icon: Iconsax.trash,
      label: l10n.editDelete,
      danger: true,
      run: () async {
        final kids = await client
            .from('categories')
            .select('id')
            .eq('parent_id', id)
            .limit(1);
        if (kids.isNotEmpty) {
          say(l10n.editRemoveSubsFirst);
          return;
        }
        final used = await client
            .from('products')
            .select('id')
            .eq('category_id', id)
            .limit(1);
        if (used.isNotEmpty) {
          say(l10n.editProductsAreIn(name));
          return;
        }
        if (!context.mounted) return;
        final ok = await _confirm(
          context,
          l10n.editDeleteNamed(name),
          l10n.editCannotUndo,
          l10n.editDelete,
        );
        if (!ok) return;
        await attempt(
          () => client.from('categories').delete().eq('id', id),
          l10n.editDeleted,
        );
      },
    ),
  ];
}

class CategoryEditPencil extends StatelessWidget {
  final String name;
  final Widget child;
  final Alignment alignment;

  const CategoryEditPencil({
    super.key,
    required this.name,
    required this.child,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) => EditPencil(
        title: name,
        alignment: alignment,
        tools: () => categoryTools(context, name),
        child: child,
      );
}

// ---------------------------------------------------------------------------
// Products

Future<List<EditTool>> productTools(
  BuildContext context,
  Product product,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final provider = context.read<ProductProvider>();
  // On a chip's page a product card can also change that page's banner.
  final page = provider.selectedCategory;
  final bannerTools = page == 'All'
      ? const <EditTool>[]
      : await _pageBannerTools(context, page);
  return [
    EditTool(
      icon: Iconsax.gallery_edit,
      label: l10n.editEditPhotosDetails,
      hint: l10n.editEditPhotosDetailsHint,
      run: () async {
        final rows = await SupabaseService.client
            .from('products')
            .select(
              'id, name, description, price, mrp, unit, stock, is_active, '
              'category_id, brand, image_url, image_urls, about_highlights',
            )
            .eq('id', product.id)
            .limit(1);
        if (rows.isEmpty || !context.mounted) return;
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AddProductScreen(
              existingProduct: Map<String, dynamic>.from(rows.first),
            ),
          ),
        );
        if (saved == true) await provider.reload();
      },
    ),
    ...bannerTools,
    EditTool(
      icon: Iconsax.eye,
      label: l10n.editOpenProductPage,
      run: () async {
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
    ),
    EditTool(
      icon: Iconsax.eye_slash,
      label: l10n.editHideFromStore,
      hint: l10n.editKeepVisibleHint,
      danger: true,
      run: () async {
        if (!context.mounted) return;
        final ok = await _confirm(
          context,
          l10n.editHideNamed(product.name),
          l10n.editHideNamedBody,
          l10n.editHide,
        );
        if (!ok) return;
        try {
          await SupabaseService.client
              .from('products')
              .update({'is_active': false}).eq('id', product.id);
          await provider.reload();
          messenger.showSnackBar(SnackBar(
              content: Text(l10n.editHidden,
                  maxLines: 1, overflow: TextOverflow.ellipsis)));
        } catch (_) {
          messenger.showSnackBar(
            SnackBar(
                content: Text(l10n.editHideFailed,
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
          );
        }
      },
    ),
  ];
}

class ProductEditPencil extends StatelessWidget {
  final Product product;
  final Widget child;

  const ProductEditPencil({
    super.key,
    required this.product,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => EditPencil(
        title: product.name,
        tools: () => productTools(context, product),
        child: child,
      );
}

// ---------------------------------------------------------------------------
// Banners

/// Asks where a banner should open: a chip, a sub-category, or nowhere.
/// Returns "" for nowhere, or the link ("Chip" or "Chip|Sub"); null if
/// dismissed.
Future<String?> _pickLinkTarget(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final provider = context.read<ProductProvider>();
  final options = <(String, String)>[(l10n.editNothingJustPicture, '')];
  for (final chip in provider.categories) {
    if (chip == 'All') continue;
    options.add((chip, chip));
    for (final sub in provider.subCategoriesOf(chip)) {
      options.add(('$chip › $sub', '$chip|$sub'));
    }
  }
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              l10n.editWhereOpen,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          for (final o in options)
            ListTile(
              dense: true,
              title: Text(o.$1),
              onTap: () => Navigator.pop(ctx, o.$2),
            ),
        ],
      ),
    ),
  );
}

Future<List<EditTool>> bannerTools(
  BuildContext context,
  Map<String, dynamic>? banner,
  Future<void> Function() onChanged,
) async {
  final client = SupabaseService.client;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger.showSnackBar(SnackBar(
      content: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)));
  Future<void> attempt(Future<void> Function() job, String done) async {
    try {
      await job();
      await onChanged();
      say(done);
    } catch (_) {
      say(l10n.editSaveFailed);
    }
  }

  final id = banner?['id'] as String?;
  // A banner with a heading is drawn by the app from product photos; the
  // others are a plain picture.
  final isOffer = banner?['title'] != null;

  Future<void> move(int delta) async {
    final all = await client
        .from('banners')
        .select('id, sort_order')
        .order('sort_order');
    var moved = false;
    await attempt(() async {
      moved = await _swapOrder(
        'banners',
        List<Map<String, dynamic>>.from(all),
        id!,
        delta,
      );
    }, l10n.editMoved);
    if (!moved) {
      say(delta < 0 ? l10n.editAlreadyFirst : l10n.editAlreadyLast);
    }
  }

  return [
    if (id != null && !isOffer)
      EditTool(
        icon: Iconsax.gallery,
        label: l10n.editChangePicture,
        hint: l10n.editPickPhotoHint,
        run: () async {
          final url = await _pickAndUploadPicture(context, 'banners');
          if (url == null) return;
          await attempt(
            () =>
                client.from('banners').update({'image_url': url}).eq('id', id),
            l10n.editPictureChanged,
          );
        },
      ),
    if (id != null && isOffer)
      EditTool(
        icon: Iconsax.edit,
        label: l10n.editChangeText,
        hint: l10n.editChangeTextHint,
        run: () async {
          final title = await _askText(
            context,
            l10n.editHeadingTitle,
            initial: banner!['title'] as String? ?? '',
          );
          if (title == null || !context.mounted) return;
          final subtitle = await _askText(
            context,
            l10n.editSubtitleTitle,
            initial: banner['subtitle'] as String? ?? '',
          );
          if (subtitle == null || !context.mounted) return;
          final cta = await _askText(
            context,
            l10n.editButtonTextTitle,
            // 'Shop now' is what an empty banner button is stored as
            // everywhere else, so the field starts on that same word.
            initial: banner['cta_label'] as String? ?? 'Shop now',
          );
          if (cta == null) return;
          await attempt(
            () => client.from('banners').update({
              'title': title.trim(),
              'subtitle': subtitle.trim(),
              'cta_label': cta.trim().isEmpty ? 'Shop now' : cta.trim(),
            }).eq('id', id),
            l10n.editTextChanged,
          );
        },
      ),
    if (id != null)
      EditTool(
        icon: Iconsax.link,
        label: l10n.editChangeWhereOpens,
        hint: (banner?['link_id'] as String?)?.replaceAll('|', ' › '),
        run: () async {
          final target = await _pickLinkTarget(context);
          if (target == null) return;
          await attempt(
            () => client.from('banners').update({
              'link_type': target.isEmpty ? null : 'category',
              'link_id': target.isEmpty ? null : target,
            }).eq('id', id),
            l10n.editSaved,
          );
        },
      ),
    EditTool(
      icon: Iconsax.gallery_add,
      label: l10n.editAddNewBanner,
      hint: l10n.editAddNewBannerHint,
      run: () async {
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminBannersScreen()),
        );
        await onChanged();
      },
    ),
    if (id != null) ...[
      EditTool(
        icon: Iconsax.eye_slash,
        label: l10n.editHideThisBanner,
        run: () => attempt(
          () =>
              client.from('banners').update({'is_active': false}).eq('id', id),
          l10n.editHidden,
        ),
      ),
      EditTool(
        icon: Iconsax.arrow_left,
        label: l10n.editMoveEarlier,
        run: () => move(-1),
      ),
      EditTool(
        icon: Iconsax.arrow_right_3,
        label: l10n.editMoveLater,
        run: () => move(1),
      ),
      EditTool(
        icon: Iconsax.trash,
        label: l10n.editDeleteThisBanner,
        danger: true,
        run: () async {
          if (!context.mounted) return;
          final ok = await _confirm(
            context,
            l10n.editDeleteThisBannerQ,
            l10n.editCannotUndo,
            l10n.editDelete,
          );
          if (!ok) return;
          await attempt(
            () => client.from('banners').delete().eq('id', id),
            l10n.editDeleted,
          );
        },
      ),
    ],
  ];
}

class BannerEditPencil extends StatelessWidget {
  /// The banner's row, or null for the stand-in shown when there are none.
  final Map<String, dynamic>? banner;
  final Future<void> Function() onChanged;
  final Widget child;

  const BannerEditPencil({
    super.key,
    required this.banner,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EditPencil(
      title: l10n.editBannerTitle,
      tools: () => bannerTools(context, banner, onChanged),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Festivals

Future<List<EditTool>> festivalTools(
  BuildContext context,
  Festival festival,
  Future<void> Function() onChanged,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final id = festival.id;
  // The banner across the top of the Festival page.
  final bannerTools = await _pageBannerTools(context, 'Festival');
  return [
    ...bannerTools,
    if (id != null)
      EditTool(
        icon: Iconsax.edit,
        label: l10n.editEditNameDates,
        run: () async {
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminFestivalsScreen(openId: id),
            ),
          );
          await onChanged();
        },
      ),
    if (id != null)
      EditTool(
        icon: Iconsax.eye_slash,
        label: l10n.editSwitchFestivalOff,
        hint: l10n.editSwitchFestivalOffHint,
        run: () async {
          try {
            await SupabaseService.client
                .from('festivals')
                .update({'is_active': false}).eq('id', id);
            await onChanged();
            messenger.showSnackBar(SnackBar(
                content: Text(l10n.editOff,
                    maxLines: 1, overflow: TextOverflow.ellipsis)));
          } catch (_) {
            messenger.showSnackBar(
              SnackBar(
                  content: Text(l10n.editSaveFailedShort,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
            );
          }
        },
      ),
    EditTool(
      icon: Iconsax.calendar_1,
      label: l10n.editAllFestivals,
      hint: l10n.editAllFestivalsHint,
      run: () async {
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminFestivalsScreen()),
        );
        await onChanged();
      },
    ),
  ];
}

class FestivalEditPencil extends StatelessWidget {
  final Festival festival;
  final Future<void> Function() onChanged;
  final Widget child;

  const FestivalEditPencil({
    super.key,
    required this.festival,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => EditPencil(
        title: festival.title,
        tools: () => festivalTools(context, festival, onChanged),
        child: child,
      );
}

/// The tools for the banner across the top of a chip's page (the picture
/// is kept on the chip's own category row). Empty if there is no such chip.
Future<List<EditTool>> _pageBannerTools(
  BuildContext context,
  String chipName,
) async {
  final client = SupabaseService.client;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final provider = context.read<ProductProvider>();
  final rows = await client
      .from('categories')
      .select('id, image_url')
      .eq('name', chipName)
      .limit(1);
  if (rows.isEmpty) return const [];
  final id = rows.first['id'] as String;
  final hasBanner = ((rows.first['image_url'] as String?) ?? '').isNotEmpty;

  Future<void> save(String? url, String done) async {
    try {
      await client.from('categories').update({'image_url': url}).eq('id', id);
      await provider.reload();
      messenger.showSnackBar(SnackBar(
          content: Text(done, maxLines: 1, overflow: TextOverflow.ellipsis)));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
            content: Text(l10n.editSaveRetry,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      );
    }
  }

  return [
    EditTool(
      icon: Iconsax.gallery_edit,
      label: l10n.editChangeBanner,
      hint: l10n.editChangeBannerHint(chipName),
      run: () async {
        final url = await _pickAndUploadPicture(context, 'banners');
        if (url == null) return;
        await save(url, l10n.editBannerChanged);
      },
    ),
    if (hasBanner)
      EditTool(
        icon: Iconsax.refresh,
        label: l10n.editRemoveTheBanner,
        hint: l10n.editRemoveTheBannerHint,
        run: () => save(null, l10n.editBannerRemoved),
      ),
  ];
}
