import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/free_time_api.dart';

// The single-day free-time finder answers "is the family free on this day".
// This answers the harder question families actually ask: "when, in the next
// two weeks, can we all get three hours together?" — which means scanning
// every day in a range against every member's calendar.
//
// That search runs in an Azure Function rather than on the device. See
// azure-functions/README.md for the reasoning and the security model.
class RangeFreeTimeScreen extends ConsumerStatefulWidget {
  const RangeFreeTimeScreen({super.key});

  @override
  ConsumerState<RangeFreeTimeScreen> createState() =>
      _RangeFreeTimeScreenState();
}

class _RangeFreeTimeScreenState extends ConsumerState<RangeFreeTimeScreen> {
  int _days = 14;
  int _minDurationMinutes = 180;

  bool _loading = false;
  String? _errorCode;
  FreeTimeRangeResult? _result;

  // Built per-frame rather than held as constants, because the labels are
  // localized and the locale can change while the screen is open.
  Map<int, String> _horizons(AppLocalizations l10n) => {
    7: l10n.rangeHorizonWeek,
    14: l10n.rangeHorizonTwoWeeks,
    30: l10n.rangeHorizonMonth,
  };

  Map<int, String> _durations(AppLocalizations l10n) => {
    60: l10n.rangeDurationOneHour,
    120: l10n.rangeDurationTwoHours,
    180: l10n.rangeDurationThreeHours,
    240: l10n.rangeDurationFourHours,
  };

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
    final l10n = AppLocalizations.of(context);
    final familyIdAsync = ref.watch(currentFamilyIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rangeFreeTimeTitle)),
      body: familyIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          icon: Icons.error_outline,
          title: l10n.rangeLoadFamilyError,
          detail: '$error',
        ),
        data: (familyId) {
          if (familyId == null) {
            return _Message(
              icon: Icons.group_off_outlined,
              title: l10n.rangeNoFamilyTitle,
              detail: l10n.rangeNoFamilyDetail,
            );
          }
          return _buildBody(context, l10n, familyId);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    String familyId,
  ) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(l10n.rangeLookAhead, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        _ChoiceRow(
          options: _horizons(l10n),
          selected: _days,
          onSelected: (value) => setState(() => _days = value),
        ),
        const SizedBox(height: 20),
        Text(l10n.rangeMinimumLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        _ChoiceRow(
          options: _durations(l10n),
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
          label: Text(_loading ? l10n.rangeSearching : l10n.rangeSearchButton),
        ),
        const SizedBox(height: 24),
        if (_errorCode != null) _ErrorCard(code: _errorCode!),
        if (_result != null) ..._buildResults(context, l10n, _result!),
      ],
    );
  }

  List<Widget> _buildResults(
    BuildContext context,
    AppLocalizations l10n,
    FreeTimeRangeResult result,
  ) {
    final theme = Theme.of(context);

    if (result.slots.isEmpty) {
      return [
        _Message(
          icon: Icons.event_busy_outlined,
          title: l10n.rangeNoWindowsTitle,
          detail: l10n.rangeNoWindowsDetail,
        ),
      ];
    }

    return [
      Text(
        l10n.rangeWindowsFound(result.slots.length),
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      Text(
        l10n.rangeComputedSummary(result.memberCount, result.eventsScanned),
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
    final locale = Localizations.localeOf(context).toString();
    final dayFormat = DateFormat('EEEE d MMMM', locale);
    final timeFormat = DateFormat.Hm(locale);

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

  /// Maps the service's language-neutral error codes onto localized text.
  /// The codes themselves never reach the user — they exist so the UI can
  /// decide what to say without parsing an English message.
  String _message(AppLocalizations l10n) {
    switch (code) {
      case 'not_signed_in':
        return l10n.rangeErrorNotSignedIn;
      case 'unauthorized':
        return l10n.rangeErrorUnauthorized;
      case 'not_a_family_member':
        return l10n.rangeErrorNotMember;
      case 'family_empty':
        return l10n.rangeErrorFamilyEmpty;
      case 'unreachable':
        return l10n.rangeErrorUnreachable;
      case 'bad_response':
        return l10n.rangeErrorBadResponse;
      default:
        return l10n.rangeErrorUnknown(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

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
                _message(l10n),
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
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
  });

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
          Text(
            detail,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
