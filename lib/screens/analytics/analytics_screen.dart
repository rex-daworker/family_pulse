import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/event_categories.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';

/// Family activity at a glance — busiest days, who's adding the most
/// events, what kind of events dominate, and how loaded the week ahead
/// looks. Everything here is computed client-side from events that are
/// already being streamed elsewhere in the app (familyEventsProvider) —
/// no new backend, no new Firestore reads, just a different lens on data
/// the app already has.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(familyEventsProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final memberCount = membersAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No events yet — analytics will fill in as your family '
                  'starts adding things to the calendar.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _AnalyticsBody(events: events, memberCount: memberCount);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Could not load analytics — $error')),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.events, required this.memberCount});

  final List<EventModel> events;
  final int memberCount;

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeekEnd = today.add(const Duration(days: 7));

    final upcomingWeekCount = events
        .where((e) => !e.date.isBefore(today) && e.date.isBefore(nextWeekEnd))
        .length;

    // Busiest weekday — DateTime.weekday is 1 (Mon) .. 7 (Sun).
    final weekdayCounts = List<int>.filled(7, 0);
    for (final event in events) {
      weekdayCounts[event.date.weekday - 1]++;
    }
    final maxWeekdayCount = weekdayCounts.reduce((a, b) => a > b ? a : b);

    // Who's added the most events — grouped by the denormalized userName
    // already stored on each event (no member lookup needed).
    final Map<String, int> byContributor = {};
    for (final event in events) {
      final name = event.userName.isNotEmpty ? event.userName : 'Unknown';
      byContributor[name] = (byContributor[name] ?? 0) + 1;
    }
    final contributors = byContributor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxContributorCount = contributors.isEmpty
        ? 1
        : contributors.first.value;

    // By category.
    final Map<String, int> byCategory = {};
    for (final event in events) {
      final key = kEventCategories.contains(event.category)
          ? event.category
          : 'other';
      byCategory[key] = (byCategory[key] ?? 0) + 1;
    }
    final maxCategoryCount = byCategory.values.isEmpty
        ? 1
        : byCategory.values.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.event_note,
                label: 'Total events',
                value: '${events.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.groups,
                label: 'Family members',
                value: '$memberCount',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.upcoming,
                label: 'Next 7 days',
                value: '$upcomingWeekCount',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const _SectionTitle('Busiest day of the week'),
        const SizedBox(height: 8),
        ...List.generate(7, (index) {
          return _BarRow(
            label: _weekdayLabels[index],
            count: weekdayCounts[index],
            fraction: maxWeekdayCount == 0
                ? 0
                : weekdayCounts[index] / maxWeekdayCount,
            color: Theme.of(context).colorScheme.primary,
          );
        }),

        const SizedBox(height: 24),
        const _SectionTitle("Who's added the most"),
        const SizedBox(height: 8),
        if (contributors.isEmpty)
          const Text('No events logged yet.')
        else
          ...contributors.map(
            (entry) => _BarRow(
              label: entry.key,
              count: entry.value,
              fraction: entry.value / maxContributorCount,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),

        const SizedBox(height: 24),
        const _SectionTitle('By category'),
        const SizedBox(height: 8),
        ...kEventCategories.map((category) {
          final meta = categoryMeta(category);
          final count = byCategory[category] ?? 0;
          return _BarRow(
            label: meta.label,
            count: count,
            fraction: maxCategoryCount == 0 ? 0 : count / maxCategoryCount,
            color: meta.color,
            icon: meta.icon,
          );
        }),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

// A labeled horizontal bar whose fill width is proportional to `fraction`
// (0..1) of the largest value in its group — the same simple pattern used
// for every chart on this page, so nothing here needed a new chart-library
// dependency this close to the deadline.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.count,
    required this.fraction,
    required this.color,
    this.icon,
  });

  final String label;
  final int count;
  final double fraction;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          SizedBox(
            width: 88,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Full-width track. Stack gives non-positioned children
                    // loose constraints, so this needs an explicit width —
                    // without it, a bare Container with no child collapses
                    // to zero width instead of filling the row.
                    Container(
                      height: 14,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    Container(
                      height: 14,
                      width: constraints.maxWidth * fraction.clamp(0, 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text('$count', textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
