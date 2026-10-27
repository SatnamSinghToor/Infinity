import 'package:flutter/material.dart';

/// One entry of the festival calendar (the `festivals` table): what Home's
/// Festival chip is called and how its page is dressed while the festival is on.
class Festival {
  /// The `festivals` row id; null for one built in code.
  final String? id;
  final String chipLabel;
  final String kicker;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color colorFrom;
  final Color colorTo;
  final Color accent;

  /// Whether the pooja artwork (thali, bhog) belongs on this festival's page.
  final bool showPooja;

  const Festival({
    this.id,
    required this.chipLabel,
    required this.kicker,
    required this.title,
    required this.start,
    required this.end,
    required this.colorFrom,
    required this.colorTo,
    required this.accent,
    this.showPooja = false,
  });

  factory Festival.fromMap(Map<String, dynamic> row) {
    return Festival(
      id: row['id']?.toString(),
      chipLabel: row['chip_label'] as String,
      kicker: (row['kicker'] as String?) ?? 'CELEBRATE',
      title: row['title'] as String,
      start: DateTime.parse(row['start_date'] as String),
      end: DateTime.parse(row['end_date'] as String),
      colorFrom: _hex(row['color_from'] as String?, const Color(0xFFFFD9A8)),
      colorTo: _hex(row['color_to'] as String?, const Color(0xFFFFF1DE)),
      accent: _hex(row['accent'] as String?, const Color(0xFFC4531A)),
      showPooja: (row['show_pooja'] as bool?) ?? false,
    );
  }

  /// Whether [day] (by date only) falls within the festival, both ends included.
  bool isOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Whether [day] falls within [days] of the festival on either side — the
  /// window the Home chip shows in for, not just the festival's own dates,
  /// so it appears a week ahead (people plan for it) and stays a week after
  /// (stragglers still shopping it).
  bool isNear(DateTime day, {int days = 7}) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start.subtract(Duration(days: days))) &&
        !d.isAfter(end.add(Duration(days: days)));
  }

  /// The festival on today, if any; the earliest-starting wins an overlap.
  static Festival? current(List<Festival> all, [DateTime? now]) {
    final today = now ?? DateTime.now();
    final on = all.where((f) => f.isOn(today)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return on.isEmpty ? null : on.first;
  }

  static Color _hex(String? value, Color fallback) {
    if (value == null) return fallback;
    final cleaned = value.replaceAll('#', '').trim();
    final parsed =
        int.tryParse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
