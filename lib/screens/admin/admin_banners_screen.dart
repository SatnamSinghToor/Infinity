import 'dart:typed_data';
import 'package:duggu/l10n/app_localizations.dart';
import '../../widgets/app_network_image.dart';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase/supabase.dart' show FileOptions;

import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/role_common.dart';
import '../../widgets/pressable.dart';

/// Admin: the banners in Home's top carousel. Picture banners are uploaded
/// here; each can open a category when tapped.
class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  /// Home draws its banners at this shape, so pictures should match it.
  static const _ratio = 851 / 396;

  bool _loading = true;

  /// Whether the last load failed: the screen says so and offers
  /// to try again, rather than looking empty.
  bool _loadFailed = false;
  List<Map<String, dynamic>> _rows = [];
  List<({String label, String value})> _links = [];

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
      final banners = await SupabaseService.client
          .from('banners')
          .select()
          .order('sort_order');
      final cats = await SupabaseService.client
          .from('categories')
          .select('id, name, parent_id, sort_order')
          .eq('is_active', true)
          .order('sort_order');
      final mains = [
        for (final c in cats)
          if (c['parent_id'] == null) c
      ];
      final links = <({String label, String value})>[];
      for (final m in mains) {
        links.add((label: m['name'] as String, value: m['name'] as String));
        for (final s in cats) {
          if (s['parent_id'] == m['id']) {
            links.add((
              label: '${m['name']} › ${s['name']}',
              value: '${m['name']}|${s['name']}',
            ));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(banners);
        _links = links;
      });
    } catch (_) {
      _loadFailed = true;
      _toast(AppLocalizations.of(context).adminBannersLoadFailed);
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

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    String? link;
    final ok = await showModalBottomSheet<bool>(
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
                l10n.adminBannersNew,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: _ratio,
                  child: Image.memory(bytes, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.adminBannersShapeHint,
                style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: link,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.adminBannersLinkLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.adminBannersLinkNothing),
                  ),
                  for (final l in _links)
                    DropdownMenuItem<String?>(
                      value: l.value,
                      child: Text(l.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setSheet(() => link = v),
              ),
              const SizedBox(height: 14),
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
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.adminBannersUpload,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                )),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not signed in');
      final path =
          '$userId/banners/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SupabaseService.client.storage.from('product-images').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      final url = SupabaseService.client.storage
          .from('product-images')
          .getPublicUrl(path);
      var top = 0;
      for (final r in _rows) {
        final o = (r['sort_order'] as num?)?.toInt() ?? 0;
        if (o > top) top = o;
      }
      await SupabaseService.client.from('banners').insert({
        'image_url': url,
        'link_type': link == null ? null : 'category',
        'link_id': link,
        'sort_order': top + 1,
        'is_active': true,
      });
      _toast(l10n.adminBannersAdded);
      await _load();
    } catch (_) {
      _toast(l10n.adminBannersUploadFailed);
    }
  }

  Future<void> _setActive(Map<String, dynamic> row, bool v) async {
    try {
      await SupabaseService.client
          .from('banners')
          .update({'is_active': v}).eq('id', row['id'] as String);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context).adminBannersUpdateFailed);
    }
  }

  /// Swap the order of two neighbouring banners.
  Future<void> _move(int index, int delta) async {
    final j = index + delta;
    if (j < 0 || j >= _rows.length) return;
    final a = _rows[index], b = _rows[j];
    var oa = (a['sort_order'] as num?)?.toInt() ?? index;
    var ob = (b['sort_order'] as num?)?.toInt() ?? j;
    if (oa == ob) ob = delta > 0 ? oa + 1 : oa - 1;
    try {
      await SupabaseService.client
          .from('banners')
          .update({'sort_order': ob}).eq('id', a['id'] as String);
      await SupabaseService.client
          .from('banners')
          .update({'sort_order': oa}).eq('id', b['id'] as String);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context).adminBannersReorderFailed);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminBannersDeleteTitle),
        content: Text(l10n.adminBannersDeleteBody),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.adminBannersCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.adminBannersDelete,
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
      await SupabaseService.client
          .from('banners')
          .delete()
          .eq('id', row['id'] as String);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context).adminBannersDeleteFailed);
    }
  }

  String _linkLabel(Map<String, dynamic> row) {
    final l10n = AppLocalizations.of(context);
    final id = row['link_id'] as String?;
    if (row['link_type'] != 'category' || id == null) {
      return l10n.adminBannersOpensNothing;
    }
    return l10n.adminBannersOpens(id.replaceAll('|', ' › '));
  }

  Widget _picture(Map<String, dynamic> row) {
    final url = row['image_url'] as String? ?? '';
    if (row['title'] != null) {
      // A banner the app draws itself from text and colours.
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFEFF4FF),
        child: Text(
          '${row['title']}\n${row['subtitle'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }
    if (url.startsWith('asset:')) {
      return Image.asset(url.substring(6), fit: BoxFit.cover);
    }
    return AppNetworkImage(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFEEEEEE),
        child: Center(child: Icon(Iconsax.image, color: Colors.grey)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.adminBannersTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        onPressed: _add,
        icon: const Icon(Iconsax.add),
        label: Text(l10n.adminBannersFab,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: RoleBody(
        loading: _loading,
        loadingMessage: l10n.adminBannersLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminBannersLoadFailed,
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
                  l10n.adminBannersHint,
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              if (_rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.adminBannersEmpty)),
                ),
              for (var i = 0; i < _rows.length; i++) _tile(i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(int i) {
    final l10n = AppLocalizations.of(context);
    final row = _rows[i];
    final active = row['is_active'] as bool? ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Opacity(
            opacity: active ? 1 : 0.4,
            child: AspectRatio(aspectRatio: _ratio, child: _picture(row)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _linkLabel(row),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
                Pressable(
                    child: IconButton(
                  tooltip: l10n.adminBannersMoveUp,
                  icon: const Icon(Iconsax.arrow_up_2, size: 18),
                  onPressed: i == 0 ? null : () => _move(i, -1),
                )),
                Pressable(
                    child: IconButton(
                  tooltip: l10n.adminBannersMoveDown,
                  icon: const Icon(Iconsax.arrow_down_1, size: 18),
                  onPressed: i == _rows.length - 1 ? null : () => _move(i, 1),
                )),
                Switch(
                  value: active,
                  activeThumbColor: AppConstants.primaryColor,
                  onChanged: (v) => _setActive(row, v),
                ),
                Pressable(
                    child: IconButton(
                  tooltip: l10n.adminBannersDelete,
                  icon: const Icon(
                    Iconsax.trash,
                    size: 20,
                    color: AppConstants.dangerColor,
                  ),
                  onPressed: () => _delete(row),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
