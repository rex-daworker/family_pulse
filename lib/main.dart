import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/event_categories.dart';
import 'firebase_options.dart';
import 'models/event_model.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/family/create_family_screen.dart';
import 'screens/family/family_choice_screen.dart';
import 'screens/family/family_screen.dart';
import 'screens/family/groups_screen.dart';
import 'screens/family/join_family_screen.dart';
import 'screens/home/free_time_screen.dart';
import 'screens/home/pulse_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/app_drawer.dart';

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

  // Loaded once here (rather than inside each setting) so the theme
  // choice and other persisted settings are available synchronously via
  // sharedPreferencesProvider everywhere else in the app.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FamilyPulseApp(),
    ),
  );
}

// Normalizes a DateTime to the calendar day only, so events can be grouped by day.
DateTime eventKeyFor(DateTime date) =>
    DateTime(date.year, date.month, date.day);

// Checks whether a specific day already has at least one event.
bool hasEventsForDate(Map<DateTime, List<EventModel>> events, DateTime date) {
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ref.watch(themeModeProvider),
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
// not logged in -> /welcome (which gates /login and /register);
// logged in but no family -> /family-choice; otherwise -> home.
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
      // The only screens a signed-out visitor can reach. Anything else
      // bounces to /welcome — the pitch screen that's the sole door in.
      final publicRoute =
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      final user = authService.currentUser;
      if (user == null) return publicRoute ? null : '/welcome';
      if (publicRoute) return '/';

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
      GoRoute(path: '/', builder: (context, state) => const PulseScreen()),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const FamilyCalendarPage(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/free-time',
        builder: (context, state) => const FreeTimeScreen(),
      ),
      GoRoute(
        path: '/family',
        builder: (context, state) => const FamilyScreen(),
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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

  // Starting value comes from Settings' "show empty days by default";
  // the AppBar icon below can still flip it for the rest of this session
  // without changing that default.
  late bool _showEmptyDays;

  // Populated at the top of build() from the live familyEventsProvider
  // stream — see _groupEventsByDay(). Starts empty so the first frame
  // (before the stream has emitted) has something safe to read.
  Map<DateTime, List<EventModel>> _events = {};

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

    _showEmptyDays = ref.read(showEmptyDaysByDefaultProvider);
  }

  // ---------------------------------------------------------------------------
  // GROUP LIVE EVENTS BY DAY
  // ---------------------------------------------------------------------------

  Map<DateTime, List<EventModel>> _groupEventsByDay(List<EventModel> events) {
    final Map<DateTime, List<EventModel>> grouped = {};

    for (final event in events) {
      final key = eventKeyFor(event.date);
      grouped.putIfAbsent(key, () => []).add(event);
    }

    for (final list in grouped.values) {
      list.sort((a, b) => a.date.compareTo(b.date));
    }

    return grouped;
  }

  // Sign-out now lives on PulseScreen's app bar (the landing page) — see
  // _signOut() in screens/home/pulse_screen.dart.

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

  List<EventModel> _eventsForSelectedDay() {
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

  // Current user's display name, denormalized onto every event we write so
  // the UI can render "who added this" without a second lookup.
  String get _currentUserName {
    final user = ref.read(authStateProvider).value;
    return user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : (user?.email ?? 'Family member');
  }

  // Consistent colors so the snackbar itself signals success vs. failure,
  // not just the wording — matches the pattern used across the whole editor.
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _deleteEvent(EventModel event) async {
    final familyId = ref.read(currentFamilyIdProvider).value;
    if (familyId == null) {
      _showErrorSnackBar(
        "Couldn't find your family yet — try again in a moment.",
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete event?'),
          content: Text('"${event.title}" will be removed for everyone.'),
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
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(eventServiceProvider)
          .deleteEvent(familyId: familyId, eventId: event.id);
      _showSuccessSnackBar('"${event.title}" deleted');
    } catch (e) {
      _showErrorSnackBar("Couldn't delete event — $e");
    }
  }

  // The dialog owns its own TextEditingControllers (created in initState,
  // disposed in its own dispose()) instead of us creating/disposing them
  // here around an `await showDialog(...)`. That older pattern raced the
  // dialog's exit transition: showDialog's Future can resolve — letting us
  // call titleController.dispose() — before the AlertDialog widget has
  // actually finished animating out and been removed from the tree, so the
  // still-live TextField would touch a disposed controller. Letting the
  // framework own the controller's lifecycle avoids that race entirely.
  Future<void> _showEventEditor({EventModel? event}) async {
    final initialTime = TimeOfDay.fromDateTime(
      event?.date ??
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            18,
          ),
    );

    final savedDate = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => _EventEditorDialog(
        event: event,
        initialTime: initialTime,
        onError: _showErrorSnackBar,
        onSave: (title, description, time, category) async {
          final familyId = ref.read(currentFamilyIdProvider).value;
          if (familyId == null) {
            throw Exception(
              "Couldn't find your family yet — try again in a moment.",
            );
          }

          final eventDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            time.hour,
            time.minute,
          );
          final endTime = eventDate.add(const Duration(hours: 1));

          if (event == null) {
            await ref
                .read(eventServiceProvider)
                .createEvent(
                  familyId: familyId,
                  title: title,
                  category: category,
                  startTime: eventDate,
                  endTime: endTime,
                  description: description,
                  userName: _currentUserName,
                );
          } else {
            await ref
                .read(eventServiceProvider)
                .updateEvent(
                  familyId: familyId,
                  eventId: event.id,
                  updates: {
                    'title': title,
                    'description': description,
                    'category': category,
                    'date': Timestamp.fromDate(eventDate),
                    'start_time': Timestamp.fromDate(eventDate),
                    'end_time': Timestamp.fromDate(endTime),
                  },
                );
          }

          return eventDate;
        },
      ),
    );

    if (savedDate != null && mounted) {
      setState(() {
        _selectedDate = eventKeyFor(savedDate);
      });
      _showSuccessSnackBar(event == null ? 'Event added' : 'Event updated');
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(familyEventsProvider);

    return eventsAsync.when(
      data: (events) {
        _events = _groupEventsByDay(events);
        return _buildCalendarScaffold(context);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Family Calendar')),
        body: Center(child: Text('Could not load events: $error')),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN SCAFFOLD (rendered once family events have loaded)
  // ---------------------------------------------------------------------------

  Widget _buildCalendarScaffold(BuildContext context) {
    final dayEvents = _eventsForSelectedDay();

    return Scaffold(
      drawer: const AppDrawer(),
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
                                // Colored by the day's first event's category
                                // so the month grid hints at what kind of day
                                // it is before you even tap in.
                                color: categoryMeta(
                                  (_events[eventKeyFor(day)]?.first.category) ??
                                      'other',
                                ).color,
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
                      final meta = categoryMeta(event.category);
                      return Card(
                        child: ListTile(
                          title: Text(event.title),

                          subtitle: Text(
                            event.description.isEmpty
                                ? meta.label
                                : '${meta.label} · ${event.description}',
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit event',
                                onPressed: () {
                                  _showEventEditor(event: event);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete event',
                                onPressed: () {
                                  _deleteEvent(event);
                                },
                              ),
                            ],
                          ),

                          leading: CircleAvatar(
                            backgroundColor: meta.color.withValues(alpha: 0.15),
                            child: Icon(meta.icon, color: meta.color),
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

// -----------------------------------------------------------------------
// EVENT EDITOR DIALOG
// -----------------------------------------------------------------------
// A dedicated StatefulWidget so its TextEditingControllers are created in
// initState() and disposed in dispose() — controlled entirely by the
// framework's own widget lifecycle, never by us guessing when it's safe to
// dispose after an `await showDialog(...)` returns.
class _EventEditorDialog extends StatefulWidget {
  const _EventEditorDialog({
    required this.event,
    required this.initialTime,
    required this.onSave,
    required this.onError,
  });

  final EventModel? event;
  final TimeOfDay initialTime;

  // Returns the saved event's date/time on success, so the caller can jump
  // the calendar to it. Throwing surfaces an error without closing the
  // dialog, so the user doesn't lose what they typed.
  final Future<DateTime> Function(
    String title,
    String description,
    TimeOfDay time,
    String category,
  )
  onSave;

  final void Function(String message) onError;

  @override
  State<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<_EventEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TimeOfDay _selectedTime;
  late String _selectedCategory;

  String? _titleError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.event?.description ?? '',
    );
    _selectedTime = widget.initialTime;
    _selectedCategory = kEventCategories.contains(widget.event?.category)
        ? widget.event!.category
        : 'other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null && mounted) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();

    // Inline validation — shown on the field itself, dialog stays open so
    // nothing typed is lost.
    if (title.isEmpty) {
      setState(() {
        _titleError = 'Title is required';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final savedDate = await widget.onSave(
        title,
        _descriptionController.text.trim(),
        _selectedTime,
        _selectedCategory,
      );

      if (mounted) {
        Navigator.of(context).pop(savedDate);
      }
    } catch (e) {
      // Leave the dialog open on failure so the user can retry.
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      widget.onError("Couldn't save event — $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Add event' : 'Edit event'),

      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _titleError,
                isDense: true,
              ),
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() {
                    _titleError = null;
                  });
                }
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                isDense: true,
                alignLabelWithHint: true,
              ),
              minLines: 1,
              maxLines: 3,
              maxLength: 300,
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: kEventCategories.map((category) {
                final meta = categoryMeta(category);
                final selected = _selectedCategory == category;
                return ChoiceChip(
                  avatar: Icon(
                    meta.icon,
                    size: 18,
                    color: selected ? Colors.white : meta.color,
                  ),
                  label: Text(meta.label),
                  selected: selected,
                  selectedColor: meta.color,
                  labelStyle: TextStyle(color: selected ? Colors.white : null),
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time),
              label: Text('Time: ${_selectedTime.format(context)}'),
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
          onPressed: _isSaving ? null : _handleSave,
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

// Event data now lives in lib/models/event_model.dart (EventModel), backed
// live by Firestore via lib/services/event_service.dart + familyEventsProvider.
