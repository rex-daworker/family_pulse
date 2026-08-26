import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/family_roles.dart';
import '../../models/family_member_model.dart';
import '../../models/family_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/name_label_dialog.dart';

/// The "My family" screen — reachable from Pulse's family icon. Shows the
/// family's own info (name / created date / referral code) up top, then a
/// live roster of every member underneath, parents first.
///
/// Parents can rename other members (and set/change their label — "Mom",
/// "Dad", etc.) right from here; everyone else gets a read-only roster.
/// firestore.rules enforces the same restriction server-side, so this is
/// UI convenience, not the actual security boundary.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(currentFamilyProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Family'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Family groups',
            onPressed: () => context.push('/groups'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentFamilyProvider);
          ref.invalidate(familyMembersProvider);
          await ref.read(familyMembersProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            familyAsync.when(
              data: (family) {
                if (family == null) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("You're not part of a family yet."),
                  );
                }
                return _FamilyHeader(family: family);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load family info — $error'),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'MEMBERS',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),

            membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No members found yet.'),
                  );
                }

                final currentMember = findMemberById(members, currentUserId);
                final canRename =
                    currentMember != null && isParentRole(currentMember.role);

                final sorted = [...members]
                  ..sort((a, b) {
                    final roleCompare = _rolePriority(
                      a.role,
                    ).compareTo(_rolePriority(b.role));
                    if (roleCompare != 0) return roleCompare;
                    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  });

                return Column(
                  children: sorted
                      .map(
                        (member) => _MemberTile(
                          member: member,
                          isYou: member.userId == currentUserId,
                          canRename:
                              canRename && member.userId != currentUserId,
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load members — $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Parents sort ahead of children within the member list.
  int _rolePriority(String role) => isParentRole(role) ? 0 : 1;
}

class _FamilyHeader extends StatelessWidget {
  const _FamilyHeader({required this.family});

  final FamilyModel family;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: const Icon(Icons.home),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Created ${_formatDate(family.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.qr_code, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    family.id,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy family code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: family.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Family code copied')),
                    );
                  },
                ),
              ],
            ),
            Text(
              'Share this code so others can join.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.member,
    required this.isYou,
    required this.canRename,
  });

  final FamilyMember member;
  final bool isYou;
  final bool canRename;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final parent = isParentRole(member.role);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: parent
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        child: Icon(
          roleIcon(member.role),
          color: parent
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSecondaryContainer,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.name.isNotEmpty ? member.name : member.email,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isYou) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'You',
                style: TextStyle(fontSize: 11, color: colorScheme.primary),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${memberSubtitle(member.role, member.label)} · ${member.email}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(roleDisplayName(member.role)),
            visualDensity: VisualDensity.compact,
          ),
          if (canRename)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename',
              onPressed: () => _showRenameDialog(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final familyId = ref.read(currentFamilyIdProvider).value;
    if (familyId == null) return;

    final result = await showDialog<({String name, String label})>(
      context: context,
      builder: (dialogContext) => NameLabelDialog(
        title: 'Rename ${member.name}',
        initialName: member.name,
        initialLabel: member.label,
      ),
    );
    if (result == null) return;

    try {
      await ref
          .read(familyServiceProvider)
          .updateMemberInfo(
            familyId: familyId,
            userId: member.userId,
            name: result.name,
            label: result.label,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${member.name.isNotEmpty ? member.name : "Member"} updated',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't update member — $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
