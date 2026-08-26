import 'package:flutter/material.dart';

/// One selectable color theme: a primary and a secondary seed color that
/// get built into a proper two-tone Material 3 scheme (see
/// [AppTheme._themeFor]) rather than a single flat hue with an accent
/// bolted on.
class ThemePalette {
  const ThemePalette(this.key, this.label, this.primary, this.secondary);

  /// Stable identifier persisted to SharedPreferences (see
  /// `ThemePaletteNotifier` in settings_provider.dart). Never shown to the
  /// user, and never renamed once shipped — renaming it would strand
  /// anyone who already saved that choice back on the default palette.
  final String key;

  /// What Settings shows next to the swatch.
  final String label;

  final Color primary;
  final Color secondary;
}

/// FamilyPulse's app theme. Every palette tried so far lives here as one of
/// [AppTheme.all] so the Settings screen can list them for the user to pick
/// from, and trying a new one out during development is a one-line change
/// — flip [defaultPalette] and hot-restart.
class AppTheme {
  AppTheme._();

  static const blueRose = ThemePalette(
    'blueRose',
    'Blue Rose',
    Color(0xFFC97B92),
    Color(0xFF6FA8DC),
  );
  static const sunnyMeadow = ThemePalette(
    'sunnyMeadow',
    'Sunny Meadow',
    Color(0xFF55B368),
    Color(0xFFFFC93C),
  );
  static const coralReef = ThemePalette(
    'coralReef',
    'Coral Reef',
    Color(0xFFFF7A59),
    Color(0xFF2EC4B6),
  );
  static const oceanPop = ThemePalette(
    'oceanPop',
    'Ocean Pop',
    Color(0xFF2F9FE0),
    Color(0xFFFFA630),
  );
  static const berryPatch = ThemePalette(
    'berryPatch',
    'Berry Patch',
    Color(0xFF8E5FD1),
    Color(0xFF9CCB3B),
  );

  // Sampled straight from the wallpaper photo Rex sent — a vivid magenta
  // fading into deep indigo-blue. Both colors were averaged from actual
  // pixels in the image (a few small patches per band, to cancel out the
  // screen's moiré texture), not eyeballed.
  static const aurora = ThemePalette(
    'aurora',
    'Aurora',
    Color(0xFFB30EA4),
    Color(0xFF3800D0),
  );

  /// Every palette Settings lets the user choose between, in display order.
  static const all = <ThemePalette>[
    blueRose,
    sunnyMeadow,
    coralReef,
    oceanPop,
    berryPatch,
    aurora,
  ];

  /// What a fresh install (or a saved key that no longer matches anything —
  /// shouldn't happen, but [byKey] falls back to this rather than crashing)
  /// starts on.
  static const defaultPalette = aurora;

  static ThemePalette byKey(String? key) {
    for (final palette in all) {
      if (palette.key == key) return palette;
    }
    return defaultPalette;
  }

  static ThemeData light(ThemePalette palette) =>
      _themeFor(palette, Brightness.light);
  static ThemeData dark(ThemePalette palette) =>
      _themeFor(palette, Brightness.dark);

  static ThemeData _themeFor(ThemePalette palette, Brightness brightness) {
    // `ColorScheme.fromSeed` only derives one hue family from a single seed
    // — there's no built-in way to seed a second color and keep both
    // properly tonal. So each color gets its own seeded scheme (which gives
    // it correct, contrast-safe light/dark tones), and the secondary
    // scheme's primary/container pair is grafted onto the main scheme's
    // secondary slot.
    final primaryScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    );
    final secondaryScheme = ColorScheme.fromSeed(
      seedColor: palette.secondary,
      brightness: brightness,
    );

    final scheme = primaryScheme.copyWith(
      secondary: secondaryScheme.primary,
      onSecondary: secondaryScheme.onPrimary,
      secondaryContainer: secondaryScheme.primaryContainer,
      onSecondaryContainer: secondaryScheme.onPrimaryContainer,
    );

    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }
}
