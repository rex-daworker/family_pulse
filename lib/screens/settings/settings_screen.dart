import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/error_messages.dart';
import '../../core/family_roles.dart';
import '../../core/sign_out.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/family_member_model.dart';
import '../../models/family_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/name_label_dialog.dart';
import '../../widgets/weather_location_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final themePalette = ref.watch(themePaletteProvider);
    final locale = ref.watch(localeProvider);
    final showEmptyDays = ref.watch(showEmptyDaysByDefaultProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final ownMember = findMemberById(membersAsync.value ?? const [], user?.uid);

    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : l10n.addYourName;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l10n.appearanceHeader),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto),
                  label: Text(l10n.systemOption),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode),
                  label: Text(l10n.lightOption),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode),
                  label: Text(l10n.darkOption),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(selection.first);
              },
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.colorThemeLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 18,
              runSpacing: 12,
              children: AppTheme.all
                  .map(
                    (palette) => _PaletteOption(
                      palette: palette,
                      selected: palette.key == themePalette.key,
                      onTap: () => ref
                          .read(themePaletteProvider.notifier)
                          .setPalette(palette),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.languageLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<Locale?>(
              segments: [
                ButtonSegment(
                  value: null,
                  label: Text(l10n.languageSystemOption),
                ),
                ButtonSegment(
                  value: const Locale('en'),
                  label: Text(l10n.languageEnglishOption),
                ),
                ButtonSegment(
                  value: const Locale('fi'),
                  label: Text(l10n.languageFinnishOption),
                ),
                ButtonSegment(
                  value: const Locale('sv'),
                  label: Text(l10n.languageSwedishOption),
                ),
              ],
              selected: {locale},
              onSelectionChanged: (selection) {
                ref.read(localeProvider.notifier).setLocale(selection.first);
              },
            ),
          ),

          const Divider(height: 32),

          _SectionHeader(l10n.yourNameHeader),
          ListTile(
            title: Text(displayName),
            subtitle: ownMember != null && ownMember.label.isNotEmpty
                ? Text(ownMember.label)
                : null,
            trailing: const Icon(Icons.edit),
            onTap: () =>
                _editProfile(context, ref, user?.displayName ?? '', ownMember),
          ),

          const Divider(height: 32),

          _SectionHeader(l10n.yourFamilyHeader),
          familyAsync.when(
            data: (family) {
              if (family == null) {
                return ListTile(title: Text(l10n.notInFamilyYet));
              }
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: Text(family.name),
                    subtitle: Text(
                      l10n.createdOn(_formatDate(context, family.createdAt)),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code),
                    title: SelectableText(family.id),
                    subtitle: Text(l10n.familyCodeShareHelper),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: l10n.copyCodeTooltip,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: family.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.codeCopied)),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => ListTile(
              title: Text(l10n.couldNotLoadFamilyInfoError(error.toString())),
            ),
          ),

          const Divider(height: 32),

          _SectionHeader(l10n.weatherHeader),
          _WeatherLocationTile(
            location: familyAsync.value?.weatherLocation,
            isParent: ownMember != null && isParentRole(ownMember.role),
          ),

          const Divider(height: 32),

          _SectionHeader(l10n.calendarHeader),
          SwitchListTile(
            title: Text(l10n.showEmptyDaysTitle),
            subtitle: Text(l10n.showEmptyDaysSubtitle),
            value: showEmptyDays,
            onChanged: (value) {
              ref.read(showEmptyDaysByDefaultProvider.notifier).setValue(value);
            },
          ),

          const Divider(height: 32),

          _SectionHeader(l10n.accountHeader),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: () => confirmAndSignOut(context, ref),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Updates BOTH the Firebase Auth displayName (used for the auth session
  // and as a fallback greeting elsewhere) and the Firestore family member
  // doc's name/label (used everywhere the Family roster, event history,
  // and "who added this" labels actually read from). These used to only
  // update Auth, silently leaving your Family-screen entry stale — this is
  // the interconnection fix for that.
  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    FamilyMember? ownMember,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<({String name, String label})>(
      context: context,
      builder: (dialogContext) => NameLabelDialog(
        title: l10n.yourNameHeader,
        initialName: currentName,
        initialLabel: ownMember?.label ?? '',
      ),
    );

    if (result == null || !context.mounted) return;

    try {
      await ref.read(authServiceProvider).updateDisplayName(result.name);

      final familyId = ref.read(currentFamilyIdProvider).value;
      final user = ref.read(authStateProvider).value;
      if (familyId != null && user != null) {
        await ref
            .read(familyServiceProvider)
            .updateMemberInfo(
              familyId: familyId,
              userId: user.uid,
              name: result.name,
              label: result.label,
            );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.nameUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.couldNotUpdateNameError(localizedErrorMessage(context, e)),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }
}

// A tappable swatch for one ThemePalette — a two-color circle (a gradient
// from its primary to its secondary, so both seed colors are visible at a
// glance) with the palette's name underneath. The selected one gets a solid
// ring plus a checkmark, rather than relying on color alone, so the
// selection still reads for anyone with reduced color vision — worth
// caring about here, since this picker is meant to work for kids too.
class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final ThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  static const _swatchSize = 52.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _swatchSize,
              height: _swatchSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.primary, palette.secondary],
                ),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: selected
                  ? const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 22,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: _swatchSize + 12,
              child: Text(
                palette.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shows the family's saved weather-forecast location, with edit/remove
// controls visible only to parents — mirrors Family Groups' pencil+trash
// icon pairing rather than folding "remove" into the search dialog, so the
// dialog itself only ever has one job (pick a place).
class _WeatherLocationTile extends ConsumerWidget {
  const _WeatherLocationTile({required this.location, required this.isParent});

  final FamilyWeatherLocation? location;
  final bool isParent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Nothing to show a non-parent yet, and they can't set one anyway —
    // don't clutter Settings with a control that would just deny them.
    if (location == null && !isParent) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(location?.name ?? l10n.weatherNotSetLabel),
      subtitle: Text(l10n.weatherLocationSubtitle),
      trailing: !isParent
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: location == null
                      ? l10n.weatherSetLocationButton
                      : l10n.weatherChangeLocationTooltip,
                  onPressed: () => _editLocation(context, ref),
                ),
                if (location != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.weatherClearLocationTooltip,
                    onPressed: () => _removeLocation(context, ref),
                  ),
              ],
            ),
    );
  }

  Future<void> _saveLocation(
    BuildContext context,
    WidgetRef ref,
    FamilyWeatherLocation? newLocation,
  ) async {
    final l10n = AppLocalizations.of(context);
    final familyId = ref.read(currentFamilyIdProvider).value;
    if (familyId == null) return;

    try {
      await ref
          .read(familyServiceProvider)
          .updateWeatherLocation(familyId: familyId, location: newLocation);
      ref.invalidate(currentFamilyProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newLocation == null
                  ? l10n.weatherLocationRemoved
                  : l10n.weatherLocationSaved,
            ),
            backgroundColor: newLocation == null ? null : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.couldNotUpdateLocationError(
                localizedErrorMessage(context, e),
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _editLocation(BuildContext context, WidgetRef ref) async {
    final weatherService = ref.read(weatherServiceProvider);
    final result = await showDialog<FamilyWeatherLocation>(
      context: context,
      builder: (_) => WeatherLocationDialog(weatherService: weatherService),
    );

    if (result == null || !context.mounted) return;
    await _saveLocation(context, ref, result);
  }

  Future<void> _removeLocation(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.weatherClearLocationTooltip),
        content: Text(l10n.weatherRemoveLocationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await _saveLocation(context, ref, null);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
