import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/family_roles.dart';
import '../../models/family_member_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/name_label_dialog.dart';

/// Personal profile — who you are, distinct from Settings (which is about
/// how the app behaves for you). Shows your identity at a glance and lets
/// you edit it from one place that keeps Firebase Auth's displayName and
/// your Firestore family member doc in sync, instead of the two silently
/// drifting apart the way the old Settings-only edit did.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final membersAsync = ref.watch(familyMembersProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final ownMember = findMemberById(membersAsync.value ?? const [], user?.uid);

    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? 'Family member');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (user?.email != null)
                  Text(
                    user!.email!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      _editProfile(context, ref, displayName, ownMember),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profile'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          if (ownMember != null) ...[
            ListTile(
              leading: Icon(roleIcon(ownMember.role)),
              title: Text(roleDisplayName(ownMember.role)),
              subtitle: const Text('Your role in the family'),
            ),
            if (ownMember.label.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(ownMember.label),
                subtitle: const Text('Your label'),
              ),
          ],

          familyAsync.when(
            data: (family) => family == null
                ? const SizedBox.shrink()
                : ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(family.name),
                    subtitle: const Text('Your family'),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    FamilyMember? ownMember,
  ) async {
    final result = await showDialog<({String name, String label})>(
      context: context,
      builder: (dialogContext) => NameLabelDialog(
        title: 'Edit profile',
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
            content: Text('Profile updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't update profile — $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
