import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_messages.dart';
import '../../core/family_roles.dart';
import '../../core/gender_options.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/family_member_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/profile_edit_dialog.dart';

/// Personal profile — who you are, distinct from Settings (which is about
/// how the app behaves for you). Shows your identity at a glance and lets
/// you edit it from one place that keeps Firebase Auth's displayName and
/// your Firestore family member doc in sync, instead of the two silently
/// drifting apart the way the old Settings-only edit did.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).value;
    final membersAsync = ref.watch(familyMembersProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final ownMember = findMemberById(membersAsync.value ?? const [], user?.uid);

    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? l10n.familyMemberFallback);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final photoUrl = ownMember?.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
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
                  label: Text(l10n.editProfileButton),
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
              title: Text(roleDisplayName(context, ownMember.role)),
              subtitle: Text(l10n.yourRoleSubtitle),
            ),
            if (ownMember.label.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(ownMember.label),
                subtitle: Text(l10n.yourLabelSubtitle),
              ),
            if (ownMember.age != null)
              ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: Text('${ownMember.age}'),
                subtitle: Text(l10n.yourAgeSubtitle),
              ),
            if (ownMember.gender != null && ownMember.gender!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(genderDisplayName(context, ownMember.gender!)),
                subtitle: Text(l10n.yourGenderSubtitle),
              ),
          ],

          familyAsync.when(
            data: (family) => family == null
                ? const SizedBox.shrink()
                : ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(family.name),
                    subtitle: Text(l10n.yourFamilySubtitle),
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
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<ProfileEditResult>(
      context: context,
      builder: (dialogContext) => ProfileEditDialog(
        title: l10n.editProfileButton,
        initialName: currentName,
        initialLabel: ownMember?.label ?? '',
        initialPhotoUrl: ownMember?.photoUrl,
        initialAge: ownMember?.age,
        initialGender: ownMember?.gender,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref.read(authServiceProvider).updateDisplayName(result.name);

      final familyId = ref.read(currentFamilyIdProvider).value;
      final user = ref.read(authStateProvider).value;
      if (familyId != null && user != null) {
        String? photoUrl = ownMember?.photoUrl;

        final File? newPhotoFile = result.newPhotoFile;
        if (newPhotoFile != null) {
          photoUrl = await ref
              .read(storageServiceProvider)
              .uploadProfilePhoto(
                familyId: familyId,
                userId: user.uid,
                file: newPhotoFile,
              );
        } else if (result.removePhoto) {
          photoUrl = null;
        }

        await ref
            .read(familyServiceProvider)
            .updateOwnProfile(
              familyId: familyId,
              userId: user.uid,
              name: result.name,
              label: result.label,
              photoUrl: photoUrl,
              age: result.age,
              gender: result.gender,
            );

        // Keep Firebase Auth's own photoURL roughly in sync too. Nothing
        // reads it elsewhere in this app today, but other Firebase tooling
        // (and any future screen) expects it to reflect the same picture
        // rather than always being null. Doesn't touch `context`, so this
        // is safe to run after the awaits above regardless of whether the
        // dialog's caller is still mounted.
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.couldNotUpdateProfileError(
                localizedErrorMessage(context, e),
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
