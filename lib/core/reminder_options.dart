import '../l10n/generated/app_localizations.dart';

/// Reminder lead-time presets, in minutes before the event start.
/// `null` means "no reminder" — kept distinct from `0` ("at the time of
/// the event") rather than overloading zero for both.
const List<int?> kReminderOffsets = [null, 0, 10, 30, 60, 1440];

String reminderOffsetDisplayName(AppLocalizations l10n, int? minutesBefore) {
  return switch (minutesBefore) {
    null => l10n.reminderOff,
    0 => l10n.reminderAtEventTime,
    10 => l10n.reminderMinutesBefore(10),
    30 => l10n.reminderMinutesBefore(30),
    60 => l10n.reminderHoursBefore(1),
    1440 => l10n.reminderDaysBefore(1),
    _ => l10n.reminderMinutesBefore(minutesBefore),
  };
}
