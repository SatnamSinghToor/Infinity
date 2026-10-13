import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/role_common.dart';
import '../../widgets/pressable.dart';

/// Admin: the category tree. Main categories are the tabs of the Categories
/// screen (and the ones Home's chips are built on); the sub-categories inside
/// them are what shows up as cards, tiles and shelves on a store page.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  bool _loading = true;

  /// Whether the last load failed: the screen says so and offers
  /// to try again, rather than looking empty.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _rows = [];
  Map<String, int> _productCounts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final cats = await SupabaseService.client
          .from('categories')
          .select('id, name, parent_id, sort_order, is_active')
          .order('sort_order')
          .order('name');
      final products =
          await SupabaseService.client.from('products').select('category_id');
      final counts = <String, int>{};
      for (final p in products) {
        final id = p['category_id'] as String?;
        if (id != null) counts[id] = (counts[id] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(cats);
        _productCounts = counts;
      });
    } catch (_) {
      // A failed load is not an empty tree: the flag drives the screen's
      // failure state, which the toast alone never did.
      _loadFailed = true;
      _toast(AppLocalizations.of(context).adminCategoriesLoadFailed);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)));
  }

  List<Map<String, dynamic>> get _mains =>
      _rows.where((r) => r['parent_id'] == null).toList();

  List<Map<String, dynamic>> _subsOf(String id) =>
      _rows.where((r) => r['parent_id'] == id).toList();

  /// Products in a main category, counting those in its sub-categories.
  int _productsIn(Map<String, dynamic> main) {
    var n = _productCounts[main['id']] ?? 0;
    for (final s in _subsOf(main['id'] as String)) {
      n += _productCounts[s['id']] ?? 0;
    }
    return n;
  }

  /// Add or edit a category. [parent] is set when adding a sub-category.
  Future<void> _edit({Map<String, dynamic>? existing, String? parentId}) async {
    final l10n = AppLocalizations.of(context);
    final isSub = (existing?['parent_id'] ?? parentId) != null;
    final name =
        TextEditingController(text: existing?['name'] as String? ?? '');
    final order = TextEditingController(
      text: '${existing?['sort_order'] ?? _nextOrder(parentId)}',
    );
    var active = existing?['is_active'] as bool? ?? true;
    String? error;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null
                    ? (isSub
                        ? l10n.adminCategoriesNewSub
                        : l10n.adminCategoriesNewMain)
                    : (isSub
                        ? l10n.adminCategoriesEditSub
                        : l10n.adminCategoriesEditMain),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.adminCategoriesNameLabel,
                  border: const OutlineInputBorder(),
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: order,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.adminCategoriesOrderLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.adminCategoriesShowInApp),
                value: active,
                activeThumbColor: AppConstants.primaryColor,
                onChanged: (v) => setSheet(() => active = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Pressable(
                    child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final n = name.text.trim();
                    if (n.isEmpty) {
                      setSheet(() => error = l10n.adminCategoriesErrName);
                      return;
                    }
                    // Products are matched to categories by name, so a name
                    // can only be used once.
                    final clash = _rows.any(
                      (r) =>
                          (r['name'] as String).toLowerCase() ==
                              n.toLowerCase() &&
                          r['id'] != existing?['id'],
                    );
                    if (clash) {
                      setSheet(() => error = l10n.adminCategoriesErrClash);
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: Text(l10n.adminCategoriesSave,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true) return;
    final data = {
      'name': name.text.trim(),
      'sort_order': int.tryParse(order.text.trim()) ?? 0,
      'is_active': active,
    };
    try {
      if (existing == null) {
        await SupabaseService.client
            .from('categories')
            .insert({...data, 'parent_id': parentId});
      } else {
        await SupabaseService.client
            .from('categories')
            .update(data)
            .eq('id', existing['id'] as String);
      }
      _toast(l10n.adminCategoriesSaved);
      await _load();
    } catch (e) {
      _toast(l10n.adminCategoriesSaveFailed);
    }
  }

  int _nextOrder(String? parentId) {
    final siblings = parentId == null ? _mains : _subsOf(parentId);
    var top = 0;
    for (final s in siblings) {
      final o = (s['sort_order'] as num?)?.toInt() ?? 0;
      if (o > top) top = o;
    }
    return top + 1;
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final l10n = AppLocalizations.of(context);
    final id = row['id'] as String;
    final isMain = row['parent_id'] == null;
    if (isMain && _subsOf(id).isNotEmpty) {
      _toast(l10n.adminCategoriesRemoveSubsFirst);
      return;
    }
    if ((_productCounts[id] ?? 0) > 0) {
      _toast(
        l10n.adminCategoriesHasProducts(
          _productCounts[id] ?? 0,
          row['name'] as String? ?? '',
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminCategoriesDeleteTitle(row['name'] as String)),
        content: Text(l10n.adminCategoriesDeleteBody),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.adminCategoriesCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.adminCategoriesDelete,
              style: const TextStyle(color: AppConstants.dangerColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupabaseService.client.from('categories').delete().eq('id', id);
      _toast(l10n.adminCategoriesDeleted);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context).adminCategoriesDeleteFailed);
    }
  }

  Future<void> _setActive(Map<String, dynamic> row, bool value) async {
    try {
      await SupabaseService.client
          .from('categories')
          .update({'is_active': value}).eq('id', row['id'] as String);
      await _load();
    } catch (_) {
      _loadFailed = true;
      if (!mounted) return;
      _toast(AppLocalizations.of(context).adminCategoriesUpdateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.adminCategoriesTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _edit(),
        icon: const Icon(Iconsax.add),
        label: Text(l10n.adminCategoriesFab,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: RoleBody(
        loading: _loading,
        loadingMessage: l10n.adminCategoriesLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminCategoriesLoadFailed,
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4DB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.adminCategoriesHint,
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              for (final main in _mains) _mainTile(main),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainTile(Map<String, dynamic> main) {
    final l10n = AppLocalizations.of(context);
    final subs = _subsOf(main['id'] as String);
    final active = main['is_active'] as bool? ?? true;
    var subtitle = l10n.adminCategoriesMainSubtitle(
      subs.length,
      _productsIn(main),
    );
    if (!active) subtitle += l10n.adminCategoriesHidden;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          title: Text(
            main['name'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? null : Colors.grey,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 8, 10),
          children: [
            for (final s in subs) _subRow(s),
            Row(
              children: [
                Pressable(
                    child: TextButton.icon(
                  onPressed: () => _edit(parentId: main['id'] as String),
                  icon: const Icon(Iconsax.add, size: 18),
                  label: Text(l10n.adminCategoriesAddSub,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
                const Spacer(),
                Switch(
                  value: active,
                  activeThumbColor: AppConstants.primaryColor,
                  onChanged: (v) => _setActive(main, v),
                ),
                Pressable(
                    child: IconButton(
                  tooltip: l10n.adminCategoriesEdit,
                  icon: const Icon(Iconsax.edit, size: 20),
                  onPressed: () => _edit(existing: main),
                )),
                Pressable(
                    child: IconButton(
                  tooltip: l10n.adminCategoriesDelete,
                  icon: const Icon(
                    Iconsax.trash,
                    size: 20,
                    color: AppConstants.dangerColor,
                  ),
                  onPressed: () => _delete(main),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _subRow(Map<String, dynamic> sub) {
    final l10n = AppLocalizations.of(context);
    final active = sub['is_active'] as bool? ?? true;
    final n = _productCounts[sub['id']] ?? 0;
    var subtitle = l10n.adminCategoriesProductsCount(n);
    if (!active) subtitle += l10n.adminCategoriesHidden;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        sub['name'] as String,
        style: TextStyle(color: active ? null : Colors.grey),
      ),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: active,
            activeThumbColor: AppConstants.primaryColor,
            onChanged: (v) => _setActive(sub, v),
          ),
          Pressable(
              child: IconButton(
            tooltip: l10n.adminCategoriesEdit,
            icon: const Icon(Iconsax.edit, size: 20),
            onPressed: () => _edit(existing: sub),
          )),
          Pressable(
              child: IconButton(
            tooltip: l10n.adminCategoriesDelete,
            icon: const Icon(
              Iconsax.trash,
              size: 20,
              color: AppConstants.dangerColor,
            ),
            onPressed: () => _delete(sub),
          )),
        ],
      ),
    );
  }
}
