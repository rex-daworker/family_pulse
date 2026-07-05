import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android's native side (google-services.json) can auto-init the
  // default app before Dart runs, so Firebase.apps.isEmpty can't be
  // trusted here — catch the resulting duplicate-app error instead.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  runApp(const ProviderScope(child: FamilyPulseApp()));
}

// Normalizes a DateTime to the calendar day only, so events can be grouped by day.
DateTime eventKeyFor(DateTime date) =>
    DateTime(date.year, date.month, date.day);

// Checks whether a specific day already has at least one event.
bool hasEventsForDate(Map<DateTime, List<Event>> events, DateTime date) {
  return (events[eventKeyFor(date)] ?? []).isNotEmpty;
}

// Root widget that sets up the app theme and launches the calendar screen.
class FamilyPulseApp extends StatelessWidget {
  const FamilyPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const FamilyCalendarPage(),
    );
  }
}

class FamilyCalendarPage extends StatefulWidget {
  const FamilyCalendarPage({super.key});

  @override
  State<FamilyCalendarPage> createState() => _FamilyCalendarPageState();
}

class _FamilyCalendarPageState extends State<FamilyCalendarPage> {
  // Tracks the currently displayed month and selected day in the calendar.
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  // Stores events keyed by calendar day so they can be looked up quickly.
  bool _showEmptyDays = false;
  late final Map<DateTime, List<Event>> _events;

  final List<String> _monthNames = <String>[
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

  // Fills the screen with a few example events when the page first opens.
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = eventKeyFor(now);
    _events = {
      eventKeyFor(DateTime(now.year, now.month, 3)): [
        Event(
          title: 'Family dinner',
          description: 'Pizza night',
          date: DateTime(now.year, now.month, 3, 18),
        ),
      ],
      eventKeyFor(DateTime(now.year, now.month, 7)): [
        Event(
          title: 'School pickup',
          description: 'Meet at 3:30',
          date: DateTime(now.year, now.month, 7, 15, 30),
        ),
      ],
      eventKeyFor(DateTime(now.year, now.month, 12)): [
        Event(
          title: 'Weekend fun',
          description: 'Park and picnic',
          date: DateTime(now.year, now.month, 12, 10),
        ),
      ],
    };
  }

  // Formats the current month title shown in the header.
  String _monthLabel(DateTime month) {
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  // Builds the list of day cells displayed in the month grid, including leading and trailing days.
  List<DateTime> _daysForMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingDays = firstDayOfMonth.weekday % 7;
    final totalCells = (((leadingDays + daysInMonth + 6) ~/ 7) * 7).clamp(
      35,
      42,
    );

    return List<DateTime>.generate(totalCells, (index) {
      final dayOffset = index - leadingDays + 1;
      return DateTime(month.year, month.month, dayOffset);
    });
  }

  // Returns the events for the currently selected calendar day.
  List<Event> _eventsForSelectedDay() {
    final dayEvents = _events[eventKeyFor(_selectedDate)] ?? [];
    return dayEvents.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  // Updates the selected day when the user taps a calendar cell.
  void _selectDay(DateTime day) {
    setState(() {
      _selectedDate = eventKeyFor(day);
    });
  }

  // Opens a dialog for creating or editing an event on the selected day.
  Future<void> _showEventEditor({Event? event}) async {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      event?.date ??
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            18,
          ),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(event == null ? 'Add event' : 'Edit event'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setDialogState(() => selectedTime = time);
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text('Time: ${selectedTime.format(context)}'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      return;
                    }

                    final eventDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    setState(() {
                      final oldKey = event?.date != null
                          ? eventKeyFor(event!.date)
                          : null;
                      final newKey = eventKeyFor(eventDate);

                      if (oldKey != null && oldKey != newKey) {
                        final oldList = (_events[oldKey] ?? [])
                            .where((existing) => existing != event)
                            .toList();
                        _events[oldKey] = oldList;
                      }

                      final list = (_events[newKey] ?? [])
                          .where((existing) => existing != event)
                          .toList();
                      list.add(
                        Event(
                          title: title,
                          description: descriptionController.text.trim(),
                          date: eventDate,
                        ),
                      );
                      list.sort((a, b) => a.date.compareTo(b.date));
                      _events[newKey] = list;
                      _selectedDate = newKey;
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _eventsForSelectedDay();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Calendar'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _showEmptyDays = !_showEmptyDays;
              });
            },
            icon: Icon(
              _showEmptyDays ? Icons.visibility : Icons.visibility_off,
            ),
            label: Text(
              _showEmptyDays ? 'Showing empty days' : 'Show empty days',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _monthLabel(_currentMonth),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (label) => Center(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _daysForMonth(_currentMonth).length,
              itemBuilder: (context, index) {
                final day = _daysForMonth(_currentMonth)[index];
                final isCurrentMonth = day.month == _currentMonth.month;
                final isSelected =
                    eventKeyFor(day).difference(_selectedDate).inDays == 0;
                final hasEvent = hasEventsForDate(_events, day);
                final showEmpty = _showEmptyDays && isCurrentMonth && !hasEvent;

                return GestureDetector(
                  onTap: () => _selectDay(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : (hasEvent
                                ? Colors.orange.shade100
                                : (showEmpty
                                      ? Colors.green.shade50
                                      : Colors.white)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: isCurrentMonth
                                  ? Colors.black
                                  : Colors.grey,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (hasEvent)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          else if (showEmpty)
                            Text(
                              'Open',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Events for ${_selectedDate.day}.${_selectedDate.month}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showEventEditor(),
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Add event',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dayEvents.isEmpty)
                    const Text('No events yet — add one to plan family time.')
                  else
                    ...dayEvents.map((event) {
                      return Card(
                        child: ListTile(
                          title: Text(event.title),
                          subtitle: Text(
                            event.description.isEmpty
                                ? 'No notes'
                                : event.description,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEventEditor(event: event),
                          ),
                          leading: Icon(
                            Icons.event_available,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New event'),
      ),
    );
  }
}

// Data model for one family event on the calendar.
class Event {
  Event({required this.title, required this.description, required this.date});

  final String title;
  final String description;
  final DateTime date;
}
