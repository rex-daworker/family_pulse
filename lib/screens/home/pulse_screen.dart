import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/sign_out.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/app_drawer.dart';

// The app's home dashboard: a quick "pulse" of the family's day —
// today's schedule, what's coming up next, and shortcuts to the other
// screens. Reads from the same live providers FamilyCalendarPage uses,
// so there's exactly one source of truth for events.
class PulseScreen extends ConsumerWidget {
  const PulseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authStateProvider).value;
    final eventsAsync = ref.watch(familyEventsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.familyPulseTitle),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsNav,
          ),
          IconButton(
            onPressed: () => confirmAndSignOut(context, ref),
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          return _PulseBody(
            greetingName: _greetingName(user?.displayName, user?.email),
            events: events,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Text(l10n.couldNotLoadPulseError(error.toString())),
          );
        },
      ),
    );
  }

  String _greetingName(String? displayName, String? email) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim().split(' ').first;
    }
    return email ?? 'there';
  }
}

class _PulseBody extends StatelessWidget {
  const _PulseBody({required this.greetingName, required this.events});

  final String greetingName;
  final List<EventModel> events;

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = _dayOnly(now);

    final todayEvents =
        events.where((event) => _dayOnly(event.date) == today).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final upcomingEvents =
        events.where((event) => event.date.isAfter(now)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final nextUp = upcomingEvents.take(3).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.greeting(greetingName),
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 4),

        Text(
          _dateLabel(context, now),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),

        const SizedBox(height: 20),

        // -----------------------------------------------------------------
        // QUICK STATS
        // -----------------------------------------------------------------
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.event,
                label: l10n.todayLabel,
                value: '${todayEvents.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.upcoming,
                label: l10n.upcomingStat,
                value: '${upcomingEvents.length}',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // -----------------------------------------------------------------
        // TODAY'S SCHEDULE
        // -----------------------------------------------------------------
        Text(
          l10n.todaysSchedule,
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: 8),

        if (todayEvents.isEmpty)
          _EmptyStateCard(text: l10n.nothingToday)
        else
          ...todayEvents.map((event) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event_available),
                title: Text(event.title),
                subtitle: Text(_clockLabel(context, event.date)),
              ),
            );
          }),

        const SizedBox(height: 24),

        // -----------------------------------------------------------------
        // COMING UP
        // -----------------------------------------------------------------
        Text(l10n.comingUp, style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: 8),

        if (nextUp.isEmpty)
          _EmptyStateCard(text: l10n.nothingScheduledYet)
        else
          ...nextUp.map((event) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(event.title),
                subtitle: Text(_dateTimeLabel(context, event.date)),
              ),
            );
          }),

        const SizedBox(height: 24),

        // -----------------------------------------------------------------
        // QUICK NAV
        // -----------------------------------------------------------------
        Text(l10n.jumpTo, style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: 8),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/calendar'),
              icon: const Icon(Icons.calendar_month),
              label: Text(l10n.calendarNav),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/family'),
              icon: const Icon(Icons.family_restroom),
              label: Text(l10n.familyNav),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/free-time'),
              icon: const Icon(Icons.free_breakfast),
              label: Text(l10n.freeTimeNav),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/groups'),
              icon: const Icon(Icons.groups_outlined),
              label: Text(l10n.groupsNav),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/analytics'),
              icon: const Icon(Icons.bar_chart),
              label: Text(l10n.analyticsNav),
            ),
          ],
        ),
      ],
    );
  }

  String _dateLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEEE, MMMM d', locale).format(date);
  }

  String _clockLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.jm(locale).format(date);
  }

  String _dateTimeLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return '${DateFormat.MMMd(locale).format(date)} · ${_clockLabel(context, date)}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
    );
  }
}
