import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/family_member_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';

// Answers the question a group chat never answers well: "when's everyone
// actually free?" Overlays every family member's events for one day (via
// EventService.findFreeSlots, which Igor already built) and shows the
// windows nobody has anything booked, with a one-tap way to grab one.
class FreeTimeScreen extends ConsumerStatefulWidget {
  const FreeTimeScreen({super.key});

  @override
  ConsumerState<FreeTimeScreen> createState() => _FreeTimeScreenState();
}

class _FreeTimeScreenState extends ConsumerState<FreeTimeScreen> {
  late DateTime _selectedDate;
  int _minDurationMinutes = 60;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _shiftDay(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final familyIdAsync = ref.watch(currentFamilyIdProvider);
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.freeTimeTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _shiftDay(-1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: l10n.previousDayTooltip,
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: Text(
                    _dateLabel(context, _selectedDate),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _shiftDay(1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: l10n.nextDayTooltip,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 30, label: Text(l10n.minDuration30)),
                ButtonSegment(value: 60, label: Text(l10n.minDuration60)),
                ButtonSegment(value: 120, label: Text(l10n.minDuration120)),
              ],
              selected: {_minDurationMinutes},
              onSelectionChanged: (selection) {
                setState(() => _minDurationMinutes = selection.first);
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: familyIdAsync.when(
              data: (familyId) {
                if (familyId == null) {
                  return Center(child: Text(l10n.notInFamilyYet));
                }
                return membersAsync.when(
                  data: (members) {
                    final memberIds = members.map((m) => m.userId).toList();
                    if (memberIds.isEmpty) {
                      // Shouldn't happen in practice (you're always a member
                      // of your own family), but guard rather than show a
                      // confusing empty state.
                      return Center(child: Text(l10n.couldNotFindMembers));
                    }
                    return Column(
                      children: [
                        _FamilyAvailabilityCard(
                          familyId: familyId,
                          members: members,
                          date: _selectedDate,
                        ),
                        Expanded(
                          child: _FreeSlotsList(
                            familyId: familyId,
                            memberIds: memberIds,
                            date: _selectedDate,
                            minDurationMinutes: _minDurationMinutes,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      l10n.couldNotLoadFamilyMembersError(error.toString()),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(l10n.couldNotLoadYourFamilyError(error.toString())),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateLabel(BuildContext context, DateTime date) {
  final today = DateTime.now();
  final isToday =
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;
  if (isToday) return AppLocalizations.of(context).todayLabel;

  final locale = Localizations.localeOf(context).toString();
  return DateFormat.MMMd(locale).format(date);
}

// Owns the async load of free slots and re-runs it whenever the day,
// minimum duration, or member list actually changes — separated from
// FreeTimeScreen so that state, and only that state, drives the
// FutureBuilder below it.
class _FreeSlotsList extends ConsumerStatefulWidget {
  const _FreeSlotsList({
    required this.familyId,
    required this.memberIds,
    required this.date,
    required this.minDurationMinutes,
  });

  final String familyId;
  final List<String> memberIds;
  final DateTime date;
  final int minDurationMinutes;

  @override
  ConsumerState<_FreeSlotsList> createState() => _FreeSlotsListState();
}

class _FreeSlotsListState extends ConsumerState<_FreeSlotsList> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _FreeSlotsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date ||
        oldWidget.minDurationMinutes != widget.minDurationMinutes ||
        oldWidget.familyId != widget.familyId ||
        !listEquals(oldWidget.memberIds, widget.memberIds)) {
      setState(() {
        _future = _load();
      });
    }
  }

  // Searches 7:00–21:00 rather than the full 24 hours — a "free slot" at
  // 3am isn't useful family time, and this keeps the list focused on
  // windows people would actually plan something in.
  Future<List<Map<String, dynamic>>> _load() {
    final dayStart = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      7,
    );
    final dayEnd = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      21,
    );
    return ref
        .read(eventServiceProvider)
        .findFreeSlots(
          familyId: widget.familyId,
          dayStart: dayStart,
          dayEnd: dayEnd,
          memberIds: widget.memberIds,
          minDurationMinutes: widget.minDurationMinutes,
        );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.couldNotLoadFreeTimeError('${snapshot.error}'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.freeTimeRetryButton),
                  ),
                ],
              ),
            ),
          );
        }

        final slots = snapshot.data ?? [];
        if (slots.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.noFreeWindow,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        // Index 0 is the summary banner, so slot i lives at index i + 1 —
        // cheaper than a separate Column+ListView (which would lose
        // ListView.builder's lazy build) just to show one header row.
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: slots.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.freeSlotsFoundCount(slots.length),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              );
            }

            final slot = slots[index - 1];
            final start = slot['start'] as DateTime;
            final end = slot['end'] as DateTime;
            final duration = slot['duration_minutes'] as int;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.event_available),
                title: Text(
                  '${_timeLabel(context, start)} – ${_timeLabel(context, end)}',
                ),
                subtitle: Text(l10n.freeForEveryone(duration)),
                trailing: FilledButton.tonal(
                  onPressed: () => _scheduleHere(start),
                  child: Text(l10n.scheduleButton),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _scheduleHere(DateTime start) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          _QuickEventDialog(familyId: widget.familyId, startTime: start),
    );

    // Re-run the search so the slot that was just filled disappears (or
    // shrinks) instead of still being offered.
    if (created == true) _refresh();
  }

  String _timeLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.jm(locale).format(date);
  }
}

// Shows each family member's own busy/free status for the selected day —
// the per-member detail findFreeSlots() computes internally and then
// throws away once it's collapsed into "when is everyone free". This is
// the piece that was missing on top of the combined result: not just
// whether there's a free window, but who specifically is free or busy
// when there isn't one.
class _FamilyAvailabilityCard extends ConsumerStatefulWidget {
  const _FamilyAvailabilityCard({
    required this.familyId,
    required this.members,
    required this.date,
  });

  final String familyId;
  final List<FamilyMember> members;
  final DateTime date;

  @override
  ConsumerState<_FamilyAvailabilityCard> createState() =>
      _FamilyAvailabilityCardState();
}

class _FamilyAvailabilityCardState
    extends ConsumerState<_FamilyAvailabilityCard> {
  late Future<Map<String, List<Map<String, DateTime>>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _FamilyAvailabilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.members.map((m) => m.userId).toList();
    final newIds = widget.members.map((m) => m.userId).toList();
    if (oldWidget.date != widget.date ||
        oldWidget.familyId != widget.familyId ||
        !listEquals(oldIds, newIds)) {
      setState(() {
        _future = _load();
      });
    }
  }

  // Same 7:00–21:00 "family time" window as _FreeSlotsList._load() below —
  // keep these in sync if that window ever changes, so a member's status
  // shown here still lines up with what the free-slot search actually
  // searched.
  Future<Map<String, List<Map<String, DateTime>>>> _load() {
    final dayStart = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      7,
    );
    final dayEnd = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      21,
    );
    return ref
        .read(eventServiceProvider)
        .getMemberAvailability(
          familyId: widget.familyId,
          dayStart: dayStart,
          dayEnd: dayEnd,
          memberIds: widget.members.map((m) => m.userId).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.familyAvailabilityTitle(_dateLabel(context, widget.date)),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, List<Map<String, DateTime>>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    l10n.couldNotLoadFreeTimeError('${snapshot.error}'),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }

                final busyTimes = snapshot.data ?? {};
                return Column(
                  children: widget.members
                      .map(
                        (member) => _MemberAvailabilityRow(
                          member: member,
                          busyBlocks: busyTimes[member.userId] ?? const [],
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvailabilityRow extends StatelessWidget {
  const _MemberAvailabilityRow({
    required this.member,
    required this.busyBlocks,
  });

  final FamilyMember member;
  final List<Map<String, DateTime>> busyBlocks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final isFree = busyBlocks.isEmpty;
    final statusColor = isFree ? Colors.green.shade700 : Colors.orange.shade800;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 10, color: statusColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name.isNotEmpty ? member.name : member.email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (isFree)
                  Text(
                    l10n.freeAllDayStatus,
                    style: TextStyle(color: statusColor, fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: busyBlocks
                        .map(
                          (block) => Chip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.orange.shade50,
                            label: Text(
                              '${DateFormat.jm(locale).format(block['start']!)} – '
                              '${DateFormat.jm(locale).format(block['end']!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// A deliberately small event-creation dialog scoped to this screen — the
// full editor lives in FamilyCalendarPage's private state and isn't
// reachable from here, so this is Title + Notes only, pre-filled with the
// tapped slot's start time and a 1-hour default duration. Owns its own
// controllers (created/disposed via initState/dispose) for the same reason
// the main event editor does: no race with the caller disposing them
// while the dialog is still closing.
class _QuickEventDialog extends ConsumerStatefulWidget {
  const _QuickEventDialog({required this.familyId, required this.startTime});

  final String familyId;
  final DateTime startTime;

  @override
  ConsumerState<_QuickEventDialog> createState() => _QuickEventDialogState();
}

class _QuickEventDialogState extends ConsumerState<_QuickEventDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _titleError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = l10n.titleRequiredError);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateProvider).value;
      final userName = (user?.displayName?.trim().isNotEmpty ?? false)
          ? user!.displayName!.trim()
          : (user?.email ?? l10n.familyMemberFallback);

      await ref
          .read(eventServiceProvider)
          .createEvent(
            familyId: widget.familyId,
            title: title,
            category: 'other',
            startTime: widget.startTime,
            endTime: widget.startTime.add(const Duration(hours: 1)),
            description: _descriptionController.text.trim(),
            userName: userName,
          );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotCreateEventError(e.toString())),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return AlertDialog(
      title: Text(
        l10n.scheduleAtTitle(DateFormat.jm(locale).format(widget.startTime)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: l10n.titleFieldLabel,
              errorText: _titleError,
              isDense: true,
            ),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.notesLabel,
              isDense: true,
              alignLabelWithHint: true,
            ),
            minLines: 1,
            maxLines: 3,
            maxLength: 300,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
