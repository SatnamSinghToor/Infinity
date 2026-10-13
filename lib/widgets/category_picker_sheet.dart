import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../utils/tokens.dart';
import 'pressable.dart';

/// One row of the `categories` table, as the picker needs it.
class PickerCategory {
  final String id;
  final String name;
  final String? parentId;

  const PickerCategory({required this.id, required this.name, this.parentId});

  static PickerCategory fromRow(Map<String, dynamic> row) => PickerCategory(
        id: row['id'] as String,
        name: (row['name'] as String? ?? '').trim(),
        parentId: row['parent_id'] as String?,
      );
}

/// The categories as the picker shows them: main categories, each with the
/// sub-categories a product can actually go into.
class CategoryTree {
  final List<PickerCategory> mains;
  final Map<String, List<PickerCategory>> subs;
  final Map<String, PickerCategory> byId;

  CategoryTree._(this.mains, this.subs, this.byId);

  factory CategoryTree.from(List<PickerCategory> all) {
    final byId = {for (final c in all) c.id: c};
    // A sub-category whose main category is switched off stands on its own.
    final mains = all
        .where((c) => c.parentId == null || !byId.containsKey(c.parentId))
        .toList();
    final subs = <String, List<PickerCategory>>{
      for (final m in mains)
        m.id: all.where((c) => c.parentId == m.id).toList(),
    };
    return CategoryTree._(mains, subs, byId);
  }

  /// Whether a product can be put in [c]: a sub-category, or a main category
  /// with no sub-categories of its own.
  bool isPickable(PickerCategory c) =>
      (c.parentId != null && byId.containsKey(c.parentId)) ||
      (subs[c.id]?.isEmpty ?? true);

  /// The main category [c] sits under, or null for a main category.
  PickerCategory? parentOf(PickerCategory c) =>
      c.parentId == null ? null : byId[c.parentId];

  /// Every pickable category whose name, or whose main category's name,
  /// contains every word of [query].
  List<PickerCategory> search(String query) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];
    final hits = <PickerCategory>[];
    for (final c in byId.values) {
      if (!isPickable(c)) continue;
      final hay = '${c.name} ${parentOf(c)?.name ?? ''}'.toLowerCase();
      if (words.every(hay.contains)) hits.add(c);
    }
    // Names that start with what was typed come first.
    final first = words.first;
    hits.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(first) ? 0 : 1;
      final bStarts = b.name.toLowerCase().startsWith(first) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.name.compareTo(b.name);
    });
    return hits;
  }
}

/// Opens the category picker and resolves to the chosen category's id, or
/// null if it was closed without a choice.
///
/// It replaces one long dropdown in which thirty sub-categories and the
/// headings above them sat in a single scroll, the headings looked like
/// choices that did nothing, and nothing could be searched. Here a search box
/// finds any category at once; without a search the main categories come
/// first, and one tap opens the few sub-categories under it.
Future<String?> showCategoryPicker(
  BuildContext context, {
  required CategoryTree tree,
  String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.tokens.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _CategoryPicker(tree: tree, selectedId: selectedId),
    ),
  );
}

class _CategoryPicker extends StatefulWidget {
  final CategoryTree tree;
  final String? selectedId;

  const _CategoryPicker({required this.tree, this.selectedId});

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  final _search = TextEditingController();
  String _query = '';

  /// The main category whose sub-categories are open; null shows the mains.
  PickerCategory? _open;

  @override
  void initState() {
    super.initState();
    // Opening the picker again lands on the chosen category's group, so a
    // seller changing Toys & Games to Art & School is one tap away.
    final selected = widget.tree.byId[widget.selectedId];
    if (selected != null) _open = widget.tree.parentOf(selected);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _pick(PickerCategory c) => Navigator.pop(context, c.id);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searching = _query.trim().isNotEmpty;
    final open = _open;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.tokens.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
          child: Row(
            children: [
              if (open != null && !searching)
                Pressable(
                    child: IconButton(
                  tooltip: l10n.categoryPickerBack,
                  onPressed: () => setState(() => _open = null),
                  icon: const Icon(Icons.arrow_back_rounded),
                ))
              else
                const SizedBox(width: 8),
              Expanded(
                child: Text(
                  open != null && !searching
                      ? open.name
                      : l10n.categoryPickerTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.categoryPickerSearchHint,
              prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
              suffixIcon: searching
                  ? Pressable(
                      child: IconButton(
                      tooltip: l10n.categoryPickerClear,
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ))
                  : null,
              filled: true,
              // The sheet is a card, so the box takes the page's surface and
              // a hairline, or it would vanish into the white.
              fillColor: context.tokens.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.tokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: context.tokens.primary, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: searching
                ? _results(l10n)
                : open == null
                    ? _mains(l10n)
                    : _subsOf(open),
          ),
        ),
      ],
    );
  }

  Widget _mains(AppLocalizations l10n) {
    final tree = widget.tree;
    final selected = tree.byId[widget.selectedId];
    final selectedMain =
        selected == null ? null : (tree.parentOf(selected) ?? selected);
    return ListView(
      key: const ValueKey('mains'),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final m in tree.mains)
          _Row(
            title: m.name,
            subtitle: (tree.subs[m.id]?.isEmpty ?? true)
                ? null
                : l10n.categoryPickerCount(tree.subs[m.id]!.length),
            selected: selectedMain?.id == m.id,
            trailing: (tree.subs[m.id]?.isEmpty ?? true)
                ? null
                : const Icon(Icons.chevron_right_rounded),
            onTap: () {
              if (tree.subs[m.id]?.isEmpty ?? true) {
                _pick(m);
              } else {
                setState(() => _open = m);
              }
            },
          ),
      ],
    );
  }

  Widget _subsOf(PickerCategory main) {
    final subs = widget.tree.subs[main.id] ?? const [];
    return ListView(
      key: ValueKey('subs-${main.id}'),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final s in subs)
          _Row(
            title: s.name,
            selected: s.id == widget.selectedId,
            onTap: () => _pick(s),
          ),
      ],
    );
  }

  Widget _results(AppLocalizations l10n) {
    final hits = widget.tree.search(_query);
    if (hits.isEmpty) {
      return Padding(
        key: const ValueKey('none'),
        padding: const EdgeInsets.all(28),
        child: Text(
          l10n.categoryPickerNoMatch(_query.trim()),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.tokens.textSecondary),
        ),
      );
    }
    return ListView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final c in hits)
          _Row(
            title: c.name,
            subtitle: widget.tree.parentOf(c)?.name,
            selected: c.id == widget.selectedId,
            onTap: () => _pick(c),
          ),
      ],
    );
  }
}

/// A category, with its initial in a soft circle so the list reads at a
/// glance, and a tick on the chosen one.
class _Row extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final Widget? trailing;
  final VoidCallback onTap;

  const _Row({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      selected: selected,
      selectedTileColor: t.primary.withValues(alpha: 0.07),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor:
            selected ? t.primary : t.primary.withValues(alpha: 0.1),
        child: Text(
          title.isEmpty ? '?' : title[0].toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? t.card : t.primary,
          ),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: t.textPrimary,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: t.primary)
          : trailing,
    );
  }
}
