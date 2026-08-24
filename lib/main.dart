import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/family/create_family_screen.dart';
import 'screens/family/family_choice_screen.dart';
import 'screens/family/join_family_screen.dart';

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

// Root widget that sets up the app theme and launches the router.
class FamilyPulseApp extends ConsumerWidget {
  const FamilyPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FamilyPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

// Bridges a Firebase auth stream into something GoRouter can listen to,
// so the router re-evaluates redirects whenever login state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  void refresh() => notifyListeners();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Builds the app's router. Redirect logic enforces:
// not logged in -> /login; logged in but no family -> /family-choice;
// otherwise -> home.
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  // Also refresh when the family lookup resolves, so a redirect deferred
  // while currentFamilyIdProvider was still loading gets re-evaluated
  // once it has a value instead of leaving the user on the wrong screen.
  final refreshStream = GoRouterRefreshStream(authService.userChanges);
  ref.onDispose(refreshStream.dispose);
  ref.listen(currentFamilyIdProvider, (_, _) => refreshStream.refresh());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      final user = authService.currentUser;
      if (user == null) return loggingIn ? null : '/login';
      if (loggingIn) return '/';

      // Read the already-resolved family state — no awaiting here.
      final familyAsync = ref.read(currentFamilyIdProvider);
      final choosingFamily =
          state.matchedLocation == '/family-choice' ||
          state.matchedLocation == '/create-family' ||
          state.matchedLocation == '/join-family';

      // Still loading or errored — don't redirect, let the screen render.
      // Errored — send to family-choice rather than silently stranding on home.
      if (familyAsync.hasError) {
        debugPrint('family lookup failed: ${familyAsync.error}');
        return choosingFamily ? null : '/family-choice';
      }
      if (familyAsync.isLoading) return null;
      final familyId = familyAsync.value;
      if (familyId == null && !choosingFamily) return '/family-choice';
      if (familyId != null && choosingFamily) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const FamilyCalendarPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/family-choice',
        builder: (context, state) => const FamilyChoiceScreen(),
      ),
      GoRoute(
        path: '/create-family',
        builder: (context, state) => const CreateFamilyScreen(),
      ),
      GoRoute(
        path: '/join-family',
        builder: (context, state) => const JoinFamilyScreen(),
      ),
    ],
  );
});

class FamilyCalendarPage extends ConsumerStatefulWidget {
  const FamilyCalendarPage({super.key});

  @override
  ConsumerState<FamilyCalendarPage> createState() {
    return _FamilyCalendarPageState();
  }
}

class _FamilyCalendarPageState extends ConsumerState<FamilyCalendarPage> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

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

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _currentMonth = DateTime(now.year, now.month);

    _selectedDate = eventKeyFor(now);

    // Example events.
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

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> _signOut() async {
    try {
      // Use AuthService directly.
      // This avoids the ref/authStateNotifierProvider problem.
      await ref.read(authServiceProvider).signOut();

      // Firebase auth state changes will also make GoRouter redirect.
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not sign out: $e')));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // MONTH LABEL
  // ---------------------------------------------------------------------------

  String _monthLabel(DateTime month) {
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  // ---------------------------------------------------------------------------
  // DAYS FOR MONTH
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // SELECTED DAY EVENTS
  // ---------------------------------------------------------------------------

  List<Event> _eventsForSelectedDay() {
    final dayEvents = _events[eventKeyFor(_selectedDate)] ?? [];

    return dayEvents.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  // ---------------------------------------------------------------------------
  // SELECT DAY
  // ---------------------------------------------------------------------------

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDate = eventKeyFor(day);
    });
  }

  // ---------------------------------------------------------------------------
  // EVENT EDITOR
  // ---------------------------------------------------------------------------

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
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                          context: dialogContext,
                          initialTime: selectedTime,
                        );

                        if (time != null) {
                          setDialogState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        'Time: ${selectedTime.format(dialogContext)}',
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
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
                      // -------------------------------------------------------
                      // FIX FOR THE PREVIOUS NULLABLE EVENT ERROR
                      // -------------------------------------------------------

                      final DateTime? oldKey = event != null
                          ? eventKeyFor(event.date)
                          : null;

                      final newKey = eventKeyFor(eventDate);

                      // Remove event from its old day when
                      // editing and changing the date.
                      if (oldKey != null && oldKey != newKey) {
                        final oldList = (_events[oldKey] ?? [])
                            .where((existing) => existing != event)
                            .toList();

                        _events[oldKey] = oldList;
                      }

                      // Remove the old version of the event.
                      final list = (_events[newKey] ?? [])
                          .where((existing) => existing != event)
                          .toList();

                      // Add the new version.
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

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final dayEvents = _eventsForSelectedDay();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Calendar'),

        backgroundColor: Theme.of(context).colorScheme.primaryContainer,

        actions: [
          // Show/hide empty days.
          IconButton(
            onPressed: () {
              setState(() {
                _showEmptyDays = !_showEmptyDays;
              });
            },
            icon: Icon(
              _showEmptyDays ? Icons.visibility : Icons.visibility_off,
            ),
            tooltip: _showEmptyDays ? 'Hide empty days' : 'Show empty days',
          ),

          // Family screen.
          IconButton(
            onPressed: () {
              context.push('/family');
            },
            icon: const Icon(Icons.family_restroom),
            tooltip: 'My family',
          ),

          // Logout.
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // -----------------------------------------------------------------
            // MONTH NAVIGATION
            // -----------------------------------------------------------------
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

            // -----------------------------------------------------------------
            // WEEKDAY HEADER
            // -----------------------------------------------------------------
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

            // -----------------------------------------------------------------
            // CALENDAR GRID
            // -----------------------------------------------------------------
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
                final days = _daysForMonth(_currentMonth);

                final day = days[index];

                final isCurrentMonth =
                    day.month == _currentMonth.month &&
                    day.year == _currentMonth.year;

                final isSelected =
                    eventKeyFor(day) == eventKeyFor(_selectedDate);

                final hasEvent = hasEventsForDate(_events, day);

                final showEmpty = _showEmptyDays && isCurrentMonth && !hasEvent;

                return GestureDetector(
                  onTap: () {
                    _selectDay(day);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),

                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : hasEvent
                          ? Colors.orange.shade100
                          : showEmpty
                          ? Colors.green.shade50
                          : Colors.white,

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

            // -----------------------------------------------------------------
            // SELECTED DAY EVENTS
            // -----------------------------------------------------------------
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
                        'Events for '
                        '${_selectedDate.day}.'
                        '${_selectedDate.month}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed: () {
                          _showEventEditor();
                        },
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
                            onPressed: () {
                              _showEventEditor(event: event);
                            },
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

      // -----------------------------------------------------------------------
      // NEW EVENT BUTTON
      // -----------------------------------------------------------------------
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showEventEditor();
        },
        icon: const Icon(Icons.add),
        label: const Text('New event'),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EVENT MODEL
// -----------------------------------------------------------------------------

class Event {
  Event({required this.title, required this.description, required this.date});

  final String title;
  final String description;
  final DateTime date;
}
