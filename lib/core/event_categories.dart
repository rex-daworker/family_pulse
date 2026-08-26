import 'package:flutter/material.dart';

/// Real event categories, shared by the event editor (so you can actually
/// pick one), the calendar/pulse tiles (so they render with the right
/// icon/color), and the Analytics page (so "busiest category" means
/// something). Previously every event silently saved as 'other' — the
/// field existed on the model but nothing in the UI ever set or showed it.
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

const Map<String, EventCategoryMeta> _categoryMeta = {
  'school': EventCategoryMeta(
    label: 'School',
    icon: Icons.school,
    color: Colors.indigo,
  ),
  'hobby': EventCategoryMeta(
    label: 'Hobby',
    icon: Icons.palette,
    color: Colors.purple,
  ),
  'work': EventCategoryMeta(
    label: 'Work',
    icon: Icons.work,
    color: Colors.orange,
  ),
  'other': EventCategoryMeta(
    label: 'Other',
    icon: Icons.label_outline,
    color: Colors.blueGrey,
  ),
};

/// Falls back to 'other' for legacy events or an unrecognized value, so a
/// bad/missing category never crashes the UI.
EventCategoryMeta categoryMeta(String category) =>
    _categoryMeta[category] ?? _categoryMeta['other']!;
