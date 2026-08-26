import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/family_group_model.dart';
import '../../models/family_member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';

/// Sub-groups within a family — e.g. "Kids" or "Chores squad" — a name plus
/// which members belong to it. No group-specific calendar yet; this is the
/// "create a group" MVP from the feature request, deliberately left simple
/// (rename/re-pick members) rather than gold-plated this close to Sept 9.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(familyGroupsProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final members = membersAsync.value ?? const <FamilyMember>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Family Groups')),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No groups yet. Make one for things like "Kids" or '
                  '"Chores squad" to organize who\'s involved in what.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: groups.length,
            itemBuilder: (context, index) =>
                _GroupCard(group: groups[index], members: members),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Could not load groups — $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGroupEditor(context, ref),
        icon: const Icon(Icons.group_add),
        label: const Text('New group'),
      ),
    );
  }
}

Future<void> _openGroupEditor(
  BuildContext context,
  WidgetRef ref, {
  FamilyGroupModel? group,
}) async {
  final familyId = ref.read(currentFamilyIdProvider).value;
  if (familyId == null) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        _GroupEditorDialog(familyId: familyId, group: group),
  );
}

Future<void> _deleteGroup(
  BuildContext context,
  WidgetRef ref,
  FamilyGroupModel group,
) async {
  final familyId = ref.read(currentFamilyIdProvider).value;
  if (familyId == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete group?'),
      content: Text('"${group.name}" will be removed for everyone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    await ref
        .read(familyServiceProvider)
        .deleteGroup(familyId: familyId, groupId: group.id);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't delete group — $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.group, required this.members});

  final FamilyGroupModel group;
  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberNames = group.memberIds.map((id) {
      final match = members.where((m) => m.userId == id);
      return match.isNotEmpty ? match.first.name : 'Unknown member';
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit group',
                  onPressed: () => _openGroupEditor(context, ref, group: group),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete group',
                  onPressed: () => _deleteGroup(context, ref, group),
                ),
              ],
            ),
            if (memberNames.isEmpty)
              const Text('No members yet.')
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: memberNames
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// Owns its own TextEditingController via initState/dispose — the same
// dialog-lifecycle pattern used everywhere else in the app (event editor,
// edit-name dialog) to avoid disposing controllers mid exit-animation.
class _GroupEditorDialog extends ConsumerStatefulWidget {
  const _GroupEditorDialog({required this.familyId, this.group});

  final String familyId;
  final FamilyGroupModel? group;

  @override
  ConsumerState<_GroupEditorDialog> createState() => _GroupEditorDialogState();
}

class _GroupEditorDialogState extends ConsumerState<_GroupEditorDialog> {
  late final TextEditingController _nameController;
  late Set<String> _selectedIds;
  String? _nameError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    if (widget.group != null) {
      _selectedIds = {...widget.group!.memberIds};
    } else {
      // Default to including yourself — a group with nobody in it,
      // including its creator, isn't a useful starting point.
      final currentUserId = ref.read(authStateProvider).value?.uid;
      _selectedIds = currentUserId != null ? {currentUserId} : {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Group name is required');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = ref.read(familyServiceProvider);
      if (widget.group == null) {
        await service.createGroup(
          familyId: widget.familyId,
          name: name,
          memberIds: _selectedIds.toList(),
        );
      } else {
        await service.updateGroup(
          familyId: widget.familyId,
          groupId: widget.group!.id,
          name: name,
          memberIds: _selectedIds.toList(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't save group — $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);

    return AlertDialog(
      title: Text(widget.group == null ? 'New group' : 'Edit group'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Group name',
                errorText: _nameError,
                isDense: true,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            const Text('Members'),
            const SizedBox(height: 4),
            Flexible(
              child: membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No family members found yet.'),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: members.map((member) {
                      final checked = _selectedIds.contains(member.userId);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(member.name),
                        value: checked,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedIds.add(member.userId);
                            } else {
                              _selectedIds.remove(member.userId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) =>
                    Text('Could not load members — $error'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
