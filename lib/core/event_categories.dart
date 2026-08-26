import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Real event categories, shared by the event editor (so you can actually
/// pick one), the calendar/pulse tiles (so they render with the right
/// icon/color), and the Analytics page (so "busiest category" means
/// something). Previously every event silently saved as 'other' — the
/// field existed on the model but nothing in the UI ever set or showed it.
///
/// These are the language-neutral keys stored in Firestore — never
/// translate the keys themselves, only what categoryMeta() shows for them.
const List<String> kEventCategories = ['school', 'hobby', 'work', 'other'];

class EventCategoryMeta {
  const EventCategoryMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

const Map<String, IconData> _categoryIcons = {
  'school': Icons.school,
  'hobby': Icons.palette,
  'work': Icons.work,
  'other': Icons.label_outline,
};

const Map<String, Color> _categoryColors = {
  'school': Colors.indigo,
  'hobby': Colors.purple,
  'work': Colors.orange,
  'other': Colors.blueGrey,
};

/// Falls back to 'other' for legacy events or an unrecognized value, so a
/// bad/missing category never crashes the UI. Needs a BuildContext (rather
/// than being a const lookup) so the label comes back in whatever language
/// the user has picked in Settings.
EventCategoryMeta categoryMeta(BuildContext context, String category) {
  final key = _categoryIcons.containsKey(category) ? category : 'other';
  final l10n = AppLocalizations.of(context);
  final label = switch (key) {
    'school' => l10n.categorySchool,
    'hobby' => l10n.categoryHobby,
    'work' => l10n.categoryWork,
    _ => l10n.categoryOther,
  };
  return EventCategoryMeta(
    label: label,
    icon: _categoryIcons[key]!,
    color: _categoryColors[key]!,
  );
}
