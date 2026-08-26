import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Overridden once in main() right after `SharedPreferences.getInstance()`
// resolves (see the ProviderScope override around runApp), so every
// setting below can read/write synchronously without each one needing its
// own async bootstrap dance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() before runApp().',
  );
});

const _themeModeKey = 'settings.themeMode';
const _showEmptyDaysKey = 'settings.showEmptyDaysByDefault';

// ─── APPEARANCE: light / dark / system ──────────────────────────────────
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(_themeModeKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ─── CALENDAR: whether empty days are shown by default ─────────────────
// FamilyCalendarPage still has its own in-session toggle icon (so you can
// flip it for a quick look without changing your default); this is just
// what that toggle starts as when the screen opens.
class ShowEmptyDaysNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_showEmptyDaysKey) ??
        false;
  }

  Future<void> setValue(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_showEmptyDaysKey, value);
  }
}

final showEmptyDaysByDefaultProvider =
    NotifierProvider<ShowEmptyDaysNotifier, bool>(ShowEmptyDaysNotifier.new);
