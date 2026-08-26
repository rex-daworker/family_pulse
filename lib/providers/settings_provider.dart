import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';

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
const _themePaletteKey = 'settings.themePalette';
const _showEmptyDaysKey = 'settings.showEmptyDaysByDefault';
const _localeKey = 'settings.locale';

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

// ─── APPEARANCE: color theme (which of AppTheme.all is active) ─────────
class ThemePaletteNotifier extends Notifier<ThemePalette> {
  @override
  ThemePalette build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(_themePaletteKey);
    return AppTheme.byKey(stored);
  }

  Future<void> setPalette(ThemePalette palette) async {
    state = palette;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_themePaletteKey, palette.key);
  }
}

final themePaletteProvider =
    NotifierProvider<ThemePaletteNotifier, ThemePalette>(
      ThemePaletteNotifier.new,
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

// ─── LANGUAGE: English / Finnish / Swedish, or follow the system ───────
// `null` means "follow the device's language" — MaterialApp.router's
// `locale:` param treats a null value that way, falling back through
// AppLocalizations.supportedLocales on its own. Only set to a concrete
// Locale when the user has explicitly picked one in Settings.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_localeKey);
    if (stored == null || stored.isEmpty) return null;
    return Locale(stored);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
