import '../l10n/generated/app_localizations.dart';

/// Recurrence presets for the event editor. Mirrors event_categories.dart's
/// pattern: language-neutral keys stored in Firestore (never translate the
/// keys themselves), with a separate lookup for what to actually show.
///
/// Kept to fixed presets (no custom "every N weeks on Mon/Wed" rule
/// builder) — covers the common cases (school pickup, weekly practice,
/// birthdays) without the much larger UI + query surface a full rule
/// builder would need.
const List<String> kRecurrenceOptions = [
  'none',
  'daily',
  'weekly',
  'monthly',
  'yearly',
];

String recurrenceDisplayName(AppLocalizations l10n, String recurrence) {
  return switch (recurrence) {
    'daily' => l10n.recurrenceDaily,
    'weekly' => l10n.recurrenceWeekly,
    'monthly' => l10n.recurrenceMonthly,
    'yearly' => l10n.recurrenceYearly,
    _ => l10n.recurrenceNone,
  };
}
