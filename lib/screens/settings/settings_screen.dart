import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sign_out.dart';
import '../../models/family_member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/name_label_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final showEmptyDays = ref.watch(showEmptyDaysByDefaultProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final ownMember = findMemberById(membersAsync.value ?? const [], user?.uid);

    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'Add your name';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
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

          const Divider(height: 32),

          const _SectionHeader('Your name'),
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

          const _SectionHeader('Your family'),
          familyAsync.when(
            data: (family) {
              if (family == null) {
                return const ListTile(
                  title: Text("You're not part of a family yet."),
                );
              }
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: Text(family.name),
                    subtitle: Text('Created ${_formatDate(family.createdAt)}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code),
                    title: SelectableText(family.id),
                    subtitle: const Text(
                      'Family code — share so others can join',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: family.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied')),
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
            error: (error, stackTrace) =>
                ListTile(title: Text('Could not load family info — $error')),
          ),

          const Divider(height: 32),

          const _SectionHeader('Calendar'),
          SwitchListTile(
            title: const Text('Show empty days by default'),
            subtitle: const Text(
              'Applies next time you open the calendar — you can still '
              'toggle it there for a quick look.',
            ),
            value: showEmptyDays,
            onChanged: (value) {
              ref.read(showEmptyDaysByDefaultProvider.notifier).setValue(value);
            },
          ),

          const Divider(height: 32),

          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
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
    final result = await showDialog<({String name, String label})>(
      context: context,
      builder: (dialogContext) => NameLabelDialog(
        title: 'Your name',
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
          const SnackBar(
            content: Text('Name updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't update name — $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
