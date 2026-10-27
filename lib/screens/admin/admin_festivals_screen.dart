import 'package:flutter/material.dart';
import 'package:duggu/l10n/app_localizations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../models/festival.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/tokens.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/role_common.dart';
import '../../widgets/pressable.dart';

/// Admin: the festival calendar. The festival that is on today names Home's
/// Festival chip and dresses its page (colours, hero title, pooja artwork).
class AdminFestivalsScreen extends StatefulWidget {
  /// A festival to open the editor on straight away (from its pencil).
  final String? openId;

  const AdminFestivalsScreen({super.key, this.openId});

  @override
  State<AdminFestivalsScreen> createState() => _AdminFestivalsScreenState();
}

class _AdminFestivalsScreenState extends State<AdminFestivalsScreen> {
  bool _loading = true;

  /// Whether the last load failed: the screen says so and offers
  /// to try again, rather than looking empty.
  bool _loadFailed = false;
  bool _openedFirst = false;
  List<Map<String, dynamic>> _rows = [];

  /// Colour sets to start from: header top, hero fade, and the accent used
  /// for the title and cards.
  static const _presets = <(String, String, String, String)>[
    ('Saffron', '#FFD9A8', '#FFF1DE', '#C4531A'),
    ('Rose', '#FFC7D1', '#FFEFF2', '#A31D3F'),
    ('Gold', '#FFE08A', '#FFF7DA', '#B45309'),
    ('Green', '#CDEBD3', '#EFFAF1', '#1E6B3A'),
    ('Indigo', '#D9DCFF', '#F0F1FF', '#3B3FA8'),
    ('Coral', '#FFC9B8', '#FFEEE6', '#B23A12'),
  ];

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
      final rows = await SupabaseService.client
          .from('festivals')
          .select()
          .order('start_date');
      if (!mounted) return;
      setState(() => _rows = List<Map<String, dynamic>>.from(rows));
    } catch (_) {
      _loadFailed = true;
      _toast(AppLocalizations.of(context).adminFestivalsLoadFailed);
    }
    if (mounted) setState(() => _loading = false);
    // Opened from a festival's pencil: go straight to its editor, once.
    final openId = widget.openId;
    if (openId != null && !_openedFirst && mounted) {
      _openedFirst = true;
      final match = _rows.where((r) => r['id'] == openId);
      if (match.isNotEmpty) _edit(match.first);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)));
  }

  static String _fmt(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Color _hex(String s, [Color fallback = Colors.grey]) {
    final c = s.replaceAll('#', '').trim();
    final v = int.tryParse(c.length == 6 ? 'FF$c' : c, radix: 16);
    return v == null ? fallback : Color(v);
  }

  static bool _validHex(String s) =>
      RegExp(r'^#?[0-9A-Fa-f]{6}$').hasMatch(s.trim());

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final l10n = AppLocalizations.of(context);

    /// The presets are data; their names are words, so they cross the wire
    /// through here.
    String presetLabel(String name) => switch (name) {
          'Saffron' => l10n.adminFestivalsPresetSaffron,
          'Rose' => l10n.adminFestivalsPresetRose,
          'Gold' => l10n.adminFestivalsPresetGold,
          'Green' => l10n.adminFestivalsPresetGreen,
          'Indigo' => l10n.adminFestivalsPresetIndigo,
          'Coral' => l10n.adminFestivalsPresetCoral,
          _ => name,
        };

    final chip = TextEditingController(
      text: existing?['chip_label'] as String? ?? '',
    );
    final kicker = TextEditingController(
      text: existing?['kicker'] as String? ?? 'CELEBRATE',
    );
    final title = TextEditingController(
      text: existing?['title'] as String? ?? '',
    );
    final from = TextEditingController(
      text: existing?['color_from'] as String? ?? _presets.first.$2,
    );
    final to = TextEditingController(
      text: existing?['color_to'] as String? ?? _presets.first.$3,
    );
    final accent = TextEditingController(
      text: existing?['accent'] as String? ?? _presets.first.$4,
    );
    var start = existing == null
        ? DateTime.now()
        : DateTime.parse(existing['start_date'] as String);
    var end = existing == null
        ? DateTime.now().add(const Duration(days: 7))
        : DateTime.parse(existing['end_date'] as String);
    var pooja = existing?['show_pooja'] as bool? ?? false;
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
        builder: (ctx, setSheet) {
          Future<void> pick(bool isStart) async {
            final d = await showDatePicker(
              context: ctx,
              initialDate: isStart ? start : end,
              firstDate: DateTime(2024),
              lastDate: DateTime(2035),
            );
            if (d == null) return;
            setSheet(() {
              if (isStart) {
                start = d;
                if (end.isBefore(start)) end = start;
              } else {
                end = d;
              }
            });
          }

          Widget colourField(String label, TextEditingController c) => Expanded(
                child: TextField(
                  controller: c,
                  onChanged: (_) => setSheet(() {}),
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _hex(c.text),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26),
                        ),
                        child: const SizedBox(width: 14, height: 14),
                      ),
                    ),
                  ),
                ),
              );

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null
                        ? l10n.adminFestivalsNew
                        : l10n.adminFestivalsEditDialog,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: chip,
                    decoration: InputDecoration(
                      labelText: l10n.adminFestivalsChipLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: kicker,
                          decoration: InputDecoration(
                            labelText: l10n.adminFestivalsKickerLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: title,
                    decoration: InputDecoration(
                      labelText: l10n.adminFestivalsTitleLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Pressable(
                            child: OutlinedButton.icon(
                          onPressed: () => pick(true),
                          icon: const Icon(Iconsax.calendar_1, size: 18),
                          label: Text(l10n.adminFestivalsFrom(_fmt(start)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Pressable(
                            child: OutlinedButton.icon(
                          onPressed: () => pick(false),
                          icon: const Icon(Iconsax.calendar_1, size: 18),
                          label: Text(l10n.adminFestivalsTo(_fmt(end)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.adminFestivalsColours,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final p in _presets)
                        ActionChip(
                          avatar: CircleAvatar(backgroundColor: _hex(p.$4)),
                          label: Text(presetLabel(p.$1),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onPressed: () => setSheet(() {
                            from.text = p.$2;
                            to.text = p.$3;
                            accent.text = p.$4;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      colourField(l10n.adminFestivalsHeader, from),
                      const SizedBox(width: 8),
                      colourField(l10n.adminFestivalsFade, to),
                      const SizedBox(width: 8),
                      colourField(l10n.adminFestivalsAccent, accent),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminFestivalsShowPooja),
                    subtitle: Text(l10n.adminFestivalsShowPoojaSub),
                    value: pooja,
                    activeColor: AppConstants.primaryColor,
                    onChanged: (v) => setSheet(() => pooja = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminFestivalsActive),
                    value: active,
                    activeColor: AppConstants.primaryColor,
                    onChanged: (v) => setSheet(() => active = v),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        error!,
                        style: const TextStyle(color: AppConstants.dangerColor),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: AppControl.lg,
                    child: Pressable(
                        child: ElevatedButton(
                      onPressed: () {
                        if (chip.text.trim().isEmpty ||
                            title.text.trim().isEmpty) {
                          setSheet(
                              () => error = l10n.adminFestivalsErrChipTitle);
                          return;
                        }
                        if (![from, to, accent]
                            .every((c) => _validHex(c.text))) {
                          setSheet(
                            () => error = l10n.adminFestivalsErrColours,
                          );
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: Text(l10n.adminFestivalsSave,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (saved != true) return;
    String norm(String s) => '#${s.replaceAll('#', '').trim().toUpperCase()}';
    final data = {
      'chip_label': chip.text.trim(),
      'kicker': kicker.text.trim().isEmpty ? 'CELEBRATE' : kicker.text.trim(),
      'title': title.text.trim(),
      'start_date': _iso(start),
      'end_date': _iso(end),
      'color_from': norm(from.text),
      'color_to': norm(to.text),
      'accent': norm(accent.text),
      'show_pooja': pooja,
      'is_active': active,
    };
    try {
      if (existing == null) {
        await SupabaseService.client.from('festivals').insert(data);
      } else {
        await SupabaseService.client
            .from('festivals')
            .update(data)
            .eq('id', existing['id'] as String);
      }
      _toast(l10n.adminFestivalsSaved);
      await _load();
    } catch (_) {
      _toast(l10n.adminFestivalsSaveFailed);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminFestivalsDeleteTitle(
          row['chip_label'] as String? ?? '',
        )),
        content: Text(l10n.adminFestivalsDeleteBody),
        actions: [
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.adminFestivalsCancel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          Pressable(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.adminFestivalsDelete,
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
          .from('festivals')
          .delete()
          .eq('id', row['id'] as String);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _toast(AppLocalizations.of(context).adminFestivalsDeleteFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final festivals = [for (final r in _rows) Festival.fromMap(r)];
    final live = Festival.current([
      for (var i = 0; i < _rows.length; i++)
        if (_rows[i]['is_active'] != false) festivals[i],
    ]);
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: GradientAppBar(
        title: Text(l10n.adminFestivalsTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _edit(),
        icon: const Icon(Iconsax.add),
        label: Text(l10n.adminFestivalsFab,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: RoleBody(
        loading: _loading,
        loadingMessage: l10n.adminFestivalsLoading,
        failed: _loadFailed,
        errorTitle: l10n.adminFestivalsLoadFailed,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  live == null
                      ? l10n.adminFestivalsNoneLive
                      : l10n.adminFestivalsOnToday(
                          live.title,
                          live.chipLabel,
                        ),
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < _rows.length; i++)
                _tile(_rows[i], festivals[i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> row, Festival f) {
    final l10n = AppLocalizations.of(context);
    final on = Festival.current([f]) != null;
    final active = row['is_active'] as bool? ?? true;
    var dates = '${_fmt(f.start)} – ${_fmt(f.end)}';
    if (f.showPooja) dates += l10n.adminFestivalsPoojaSuffix;
    if (!active) dates += l10n.adminFestivalsOffSuffix;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        border: on && active
            ? Border.all(color: AppConstants.primaryColor, width: 1.4)
            : Border.all(color: context.tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [f.colorFrom, f.colorTo],
              ),
            ),
            child: Icon(Iconsax.magic_star, color: f.accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        f.chipLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: active ? null : Colors.grey,
                        ),
                      ),
                    ),
                    if (on && active) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.adminFestivalsLive,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  dates,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Pressable(
              child: IconButton(
            tooltip: l10n.adminFestivalsEdit,
            icon: const Icon(Iconsax.edit, size: 20),
            onPressed: () => _edit(row),
          )),
          Pressable(
              child: IconButton(
            tooltip: l10n.adminFestivalsDelete,
            icon: const Icon(
              Iconsax.trash,
              size: 20,
              color: AppConstants.dangerColor,
            ),
            onPressed: () => _delete(row),
          )),
        ],
      ),
    );
  }
}
