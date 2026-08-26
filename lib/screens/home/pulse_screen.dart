import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';

// The app's home dashboard: a quick "pulse" of the family's day —
// today's schedule, what's coming up next, and shortcuts to the other
// screens. Reads from the same live providers FamilyCalendarPage uses,
// so there's exactly one source of truth for events.
class PulseScreen extends ConsumerWidget {
  const PulseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final eventsAsync = ref.watch(familyEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Pulse'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
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
          return Center(child: Text('Could not load your pulse: $error'));
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

// Moved here from FamilyCalendarPage — sign-out belongs on the landing
// page now that Pulse (not the calendar) is the app's home.
Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await _confirmSignOut(context);
  if (!confirmed || !context.mounted) return;

  try {
    await ref.read(authServiceProvider).signOut();

    // Firebase auth state changes also make GoRouter redirect on its own;
    // this is a belt-and-suspenders nudge in case that hasn't fired yet.
    if (context.mounted) {
      context.go('/welcome');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not sign out: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

// A tap on the logout icon used to sign out immediately with no way back —
// one misclick and you're staring at the welcome screen. This makes it a
// deliberate, two-step action instead.
Future<bool> _confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text(
        "You'll need to log back in to see your family's calendar.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _PulseBody extends StatelessWidget {
  const _PulseBody({required this.greetingName, required this.events});

  final String greetingName;
  final List<EventModel> events;

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
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
          'Hey, $greetingName',
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 4),

        Text(
          _dateLabel(now),
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
                label: 'Today',
                value: '${todayEvents.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.upcoming,
                label: 'Upcoming',
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
          "Today's schedule",
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: 8),

        if (todayEvents.isEmpty)
          const _EmptyStateCard(text: 'Nothing on the calendar today.')
        else
          ...todayEvents.map((event) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event_available),
                title: Text(event.title),
                subtitle: Text(_timeLabel(event.date)),
              ),
            );
          }),

        const SizedBox(height: 24),

        // -----------------------------------------------------------------
        // COMING UP
        // -----------------------------------------------------------------
        Text('Coming up', style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: 8),

        if (nextUp.isEmpty)
          const _EmptyStateCard(text: 'Nothing scheduled yet.')
        else
          ...nextUp.map((event) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(event.title),
                subtitle: Text(_dateTimeLabel(event.date)),
              ),
            );
          }),

        const SizedBox(height: 24),

        // -----------------------------------------------------------------
        // QUICK NAV
        // -----------------------------------------------------------------
        Text('Jump to', style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: 8),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.push('/calendar'),
              icon: const Icon(Icons.calendar_month),
              label: const Text('Calendar'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/family'),
              icon: const Icon(Icons.family_restroom),
              label: const Text('Family'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/free-time'),
              icon: const Icon(Icons.free_breakfast),
              label: const Text('Free time'),
            ),
          ],
        ),
      ],
    );
  }

  String _dateLabel(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _timeLabel(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute $period';
  }

  String _dateTimeLabel(DateTime date) {
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

    return '${months[date.month - 1]} ${date.day} · ${_timeLabel(date)}';
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
