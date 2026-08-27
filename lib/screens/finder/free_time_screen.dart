import 'package:flutter/material.dart';

import '../../services/event_service.dart';

class FreeTimeScreen extends StatefulWidget {
  const FreeTimeScreen({
    super.key,
    required this.familyId,
    required this.memberIds,
    this.familyName,
  });

  final String familyId;
  final List<String> memberIds;
  final String? familyName;

  @override
  State<FreeTimeScreen> createState() => _FreeTimeScreenState();
}

class _FreeTimeScreenState extends State<FreeTimeScreen> {
  final EventService _eventService = EventService();

  DateTime selectedDate = DateTime.now();

  int minimumDurationMinutes = 60;

  bool isLoading = false;

  String? errorMessage;

  List<FreeSlot> freeSlots = [];

  @override
  void initState() {
    super.initState();
    _findFreeTime();
  }

  // ---------------------------------------------------------------------------
  // FIND FREE TIME
  // ---------------------------------------------------------------------------

  Future<void> _findFreeTime() async {
    if (widget.familyId.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'No family ID was provided.';
        freeSlots = [];
        isLoading = false;
      });

      return;
    }

    if (widget.memberIds.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'No family members were selected.';
        freeSlots = [];
        isLoading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final dayStart = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        0,
        0,
      );

      final dayEnd = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
      );

      final results = await _eventService.findFreeSlots(
        familyId: widget.familyId,
        dayStart: dayStart,
        dayEnd: dayEnd,
        memberIds: widget.memberIds,
        minDurationMinutes: minimumDurationMinutes,
      );

      final convertedSlots = <FreeSlot>[];

      for (final result in results) {
        final start = result['start'];
        final end = result['end'];
        final duration = result['duration_minutes'];

        if (start is! DateTime || end is! DateTime) {
          continue;
        }

        convertedSlots.add(
          FreeSlot(
            start: start,
            end: end,
            durationMinutes: duration is int
                ? duration
                : end.difference(start).inMinutes,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        freeSlots = convertedSlots;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        freeSlots = [];
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // CHANGE DATE
  // ---------------------------------------------------------------------------

  Future<void> _changeDate(int amount) async {
    if (isLoading) {
      return;
    }

    setState(() {
      selectedDate = selectedDate.add(Duration(days: amount));
    });

    await _findFreeTime();
  }

  // ---------------------------------------------------------------------------
  // DATE PICKER
  // ---------------------------------------------------------------------------

  Future<void> _selectDate() async {
    if (isLoading) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      selectedDate = picked;
    });

    await _findFreeTime();
  }

  // ---------------------------------------------------------------------------
  // FORMAT DATE
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ---------------------------------------------------------------------------
  // FORMAT TIME
  // ---------------------------------------------------------------------------

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;

    final period = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    final displayMinute = minute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }

  // ---------------------------------------------------------------------------
  // FORMAT DURATION
  // ---------------------------------------------------------------------------

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0 && remainingMinutes > 0) {
      return '${hours}h ${remainingMinutes}m';
    }

    if (hours > 0) {
      return '${hours}h';
    }

    return '${remainingMinutes}m';
  }

  // ---------------------------------------------------------------------------
  // DURATION BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildDurationButton({required int minutes, required String label}) {
    final selected = minimumDurationMinutes == minutes;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: isLoading
          ? null
          : (value) async {
              if (!value) {
                return;
              }

              setState(() {
                minimumDurationMinutes = minutes;
              });

              await _findFreeTime();
            },
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.familyName == null || widget.familyName!.trim().isEmpty
              ? 'Find Free Time'
              : 'Find Free Time',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // DATE SELECTOR
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous day',
                    onPressed: isLoading ? null : () => _changeDate(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),

                  Expanded(
                    child: InkWell(
                      onTap: isLoading ? null : _selectDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              'Free time',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),

                            const SizedBox(height: 2),

                            Text(
                              _formatDate(selectedDate),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Next day',
                    onPressed: isLoading ? null : () => _changeDate(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),

            // -----------------------------------------------------------------
            // MINIMUM DURATION
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Minimum:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 10),

                  _buildDurationButton(minutes: 30, label: '30 min'),

                  const SizedBox(width: 6),

                  _buildDurationButton(minutes: 60, label: '1 hour'),

                  const SizedBox(width: 6),

                  _buildDurationButton(minutes: 120, label: '2 hours'),
                ],
              ),
            ),

            const Divider(height: 1),

            // -----------------------------------------------------------------
            // CONTENT
            // -----------------------------------------------------------------
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 52,
                color: Theme.of(context).colorScheme.error,
              ),

              const SizedBox(height: 16),

              Text(
                'Could not find free time',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(errorMessage!, textAlign: TextAlign.center),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _findFreeTime,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (freeSlots.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
              ),

              const SizedBox(height: 16),

              Text(
                'No matching free time',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'There is no period of at least '
                '$minimumDurationMinutes minutes when '
                'all selected family members are free.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _findFreeTime,
                icon: const Icon(Icons.refresh),
                label: const Text('Search Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _findFreeTime,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------------------------------------------------------------------
          // SUMMARY
          // -------------------------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.green.withValues(alpha: 0.10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 30),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    '${freeSlots.length} free '
                    'period${freeSlots.length == 1 ? '' : 's'} '
                    'found',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------------------------
          // FREE SLOTS
          // -------------------------------------------------------------------
          ...freeSlots.map((slot) => _buildFreeSlotCard(context, slot)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FREE SLOT CARD
  // ---------------------------------------------------------------------------

  Widget _buildFreeSlotCard(BuildContext context, FreeSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
        color: Colors.green.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.access_time, color: Colors.green),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatTime(slot.start)} - '
                  '${_formatTime(slot.end)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatDuration(slot.durationMinutes),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FREE SLOT MODEL
// =============================================================================

class FreeSlot {
  const FreeSlot({
    required this.start,
    required this.end,
    required this.durationMinutes,
  });

  final DateTime start;
  final DateTime end;
  final int durationMinutes;
}
