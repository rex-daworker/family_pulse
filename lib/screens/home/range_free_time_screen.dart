import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/free_time_api.dart';

// The single-day free-time finder answers "is the family free on Saturday?".
// This answers the harder question families actually ask: "when, in the next
// two weeks, can we all get three hours together?" — which means scanning
// every day in a range against every member's calendar.
//
// That search runs in an Azure Function rather than on the device. See
// azure-functions/README.md for the reasoning and the security model.
//
// Strings here are English-only. The rest of the app is localised through
// AppLocalizations; this screen was added under deadline and its strings have
// not been through the ARB/codegen cycle yet. Tracked as a known gap.
class RangeFreeTimeScreen extends ConsumerStatefulWidget {
  const RangeFreeTimeScreen({super.key});

  @override
  ConsumerState<RangeFreeTimeScreen> createState() =>
      _RangeFreeTimeScreenState();
}

class _RangeFreeTimeScreenState extends ConsumerState<RangeFreeTimeScreen> {
  static const _horizons = <int, String>{7: '1 week', 14: '2 weeks', 30: '1 month'};
  static const _durations = <int, String>{
    60: '1 hour',
    120: '2 hours',
    180: '3 hours',
    240: '4 hours',
  };

  int _days = 14;
  int _minDurationMinutes = 180;

  bool _loading = false;
  String? _errorCode;
  FreeTimeRangeResult? _result;

  Future<void> _search(String familyId) async {
    setState(() {
      _loading = true;
      _errorCode = null;
    });

    try {
      final result = await ref
          .read(freeTimeApiProvider)
          .findFreeSlotsInRange(
            familyId: familyId,
            days: _days,
            minDurationMinutes: _minDurationMinutes,
          );
      if (mounted) setState(() => _result = result);
    } on FreeTimeApiError catch (error) {
      if (mounted) setState(() => _errorCode = error.code);
    } catch (_) {
      if (mounted) setState(() => _errorCode = 'unknown');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyIdAsync = ref.watch(currentFamilyIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find time together')),
      body: familyIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          icon: Icons.error_outline,
          title: 'Could not load your family',
          detail: '$error',
        ),
        data: (familyId) {
          if (familyId == null) {
            return const _Message(
              icon: Icons.group_off_outlined,
              title: 'No family yet',
              detail: 'Join or create a family to search for shared free time.',
            );
          }
          return _buildBody(context, familyId);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, String familyId) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Look ahead', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        _ChoiceRow(
          options: _horizons,
          selected: _days,
          onSelected: (value) => setState(() => _days = value),
        ),
        const SizedBox(height: 20),
        Text('We need at least', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        _ChoiceRow(
          options: _durations,
          selected: _minDurationMinutes,
          onSelected: (value) => setState(() => _minDurationMinutes = value),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _loading ? null : () => _search(familyId),
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(_loading ? 'Searching…' : 'Find free time'),
        ),
        const SizedBox(height: 24),
        if (_errorCode != null) _ErrorCard(code: _errorCode!),
        if (_result != null) ..._buildResults(context, _result!),
      ],
    );
  }

  List<Widget> _buildResults(BuildContext context, FreeTimeRangeResult result) {
    final theme = Theme.of(context);

    if (result.slots.isEmpty) {
      return [
        _Message(
          icon: Icons.event_busy_outlined,
          title: 'Nothing that long is free',
          detail:
              'No window of ${_durations[_minDurationMinutes]} or more in the '
              'next ${_horizons[_days]!.toLowerCase()}. Try a shorter block or '
              'a longer horizon.',
        ),
      ];
    }

    return [
      Text(
        '${result.slots.length} ${result.slots.length == 1 ? "window" : "windows"} found',
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      Text(
        'Across ${result.memberCount} members and ${result.eventsScanned} events, '
        'computed in Azure.',
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      for (final slot in result.slots) _SlotTile(slot: slot),
    ];
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final Map<int, String> options;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in options.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (_) => onSelected(entry.key),
          ),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot});

  final FreeSlot slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayFormat = DateFormat('EEEE d MMMM');
    final timeFormat = DateFormat('HH:mm');

    final hours = slot.durationMinutes ~/ 60;
    final minutes = slot.durationMinutes % 60;
    final length = minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            length,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(dayFormat.format(slot.start)),
        subtitle: Text(
          '${timeFormat.format(slot.start)} – ${timeFormat.format(slot.end)}',
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.code});

  final String code;

  static const _messages = <String, String>{
    'not_signed_in': 'You are signed out. Sign in and try again.',
    'unauthorized': 'Your session expired. Sign out and back in.',
    'not_a_family_member': 'You are not a member of this family.',
    'family_empty': 'This family has no members yet.',
    'unreachable':
        'Could not reach the free-time service. Check your connection and '
        'try again — the first request after a quiet period can be slow.',
    'bad_response': 'The service returned something unexpected.',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = _messages[code] ?? 'Something went wrong ($code).';

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
