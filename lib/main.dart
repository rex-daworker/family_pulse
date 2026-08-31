import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/event_categories.dart';
import 'core/recurrence_options.dart';
import 'core/reminder_options.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'models/event_model.dart';
import 'models/weather_model.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/weather_provider.dart';
import 'services/notification_service.dart';
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

  // Sets up the local-notifications plugin (timezone database, Android
  // notification channel) so it's ready before the calendar screen tries
  // to schedule any event reminders. Cheap and safe to do unconditionally
  // — it doesn't prompt the user for permission by itself; see
  // NotificationService.requestPermission for that.
  await NotificationService.instance.initialize();

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
      theme: AppTheme.light(ref.watch(themePaletteProvider)),
      darkTheme: AppTheme.dark(ref.watch(themePaletteProvider)),
      themeMode: ref.watch(themeModeProvider),
      // null here means "follow the device language" — MaterialApp resolves
      // that against supportedLocales on its own. Only non-null once the
      // user picks English/Finnish/Swedish explicitly in Settings.
      locale: ref.watch(localeProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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

  // Local reminders are only (re-)scheduled for events starting within this
  // many days — see NotificationService's own doc comment for why trying
  // to schedule an entire recurring series years in advance isn't viable
  // (iOS's 64-pending-notification cap). Runs once per time this page is
  // mounted (i.e. roughly once per app open), which also papers over
  // Android clearing scheduled alarms on reboot.
  static const int _reminderResyncHorizonDays = 45;
  bool _hasResyncedReminders = false;

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

  // ---------------------------------------------------------------------------
  // REMINDER SCHEDULING
  // ---------------------------------------------------------------------------

  // Fires once per mount, from the first successful data load — see
  // `_hasResyncedReminders`'s doc comment for why a resync on every app
  // open is the strategy here rather than trying to schedule everything a
  // recurring series will ever need at creation time.
  void _maybeResyncReminders(List<EventModel> events, AppLocalizations l10n) {
    if (_hasResyncedReminders) return;
    _hasResyncedReminders = true;
    unawaited(_scheduleRemindersForEvents(events, l10n));
  }

  // Shared by the startup resync above and by _showEventEditor right after
  // creating a new (possibly recurring) event — both just need "schedule
  // whichever of these events have a reminder set and fall inside the
  // resync horizon", so the filtering logic lives in one place.
  Future<void> _scheduleRemindersForEvents(
    List<EventModel> events,
    AppLocalizations l10n,
  ) async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.requestPermission();

    final now = DateTime.now();
    final horizon = now.add(const Duration(days: _reminderResyncHorizonDays));

    for (final event in events) {
      final minutesBefore = event.reminderMinutesBefore;
      if (minutesBefore == null) continue;

      final start = event.startTime ?? event.date;
      if (start.isBefore(now) || start.isAfter(horizon)) continue;

      await notificationService.scheduleEventReminder(
        eventId: event.id,
        title: l10n.reminderNotificationTitle(event.title),
        body: l10n.reminderNotificationBody(DateFormat.jm().format(start)),
        eventTime: start,
        minutesBefore: minutesBefore,
      );
    }
  }

  // Sign-out now lives on PulseScreen's app bar (the landing page) — see
  // _signOut() in screens/home/pulse_screen.dart.

  // ---------------------------------------------------------------------------
  // MONTH LABEL
  // ---------------------------------------------------------------------------

  // Locale-aware month + year (e.g. "August 2026", "elokuu 2026",
  // "augusti 2026") — DateFormat picks the right month names for whatever
  // language is active instead of us hand-translating a name array.
  String _monthLabel(BuildContext context, DateTime month) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMM(locale).format(month);
  }

  // Locale-aware single-letter weekday header (S M T W T F S in English,
  // but the right letters for whatever language is active). Anchored to
  // 1970-01-04, a known Sunday, so this generates one of each weekday in
  // Sun..Sat order without hardcoding any language's names.
  List<String> _weekdayLabels(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return List<String>.generate(7, (index) {
      final day = DateTime(1970, 1, 4 + index);
      return DateFormat('EEEEE', locale).format(day);
    });
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
        : (user?.email ?? AppLocalizations.of(context).familyMemberFallback);
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
    final l10n = AppLocalizations.of(context);
    final familyId = ref.read(currentFamilyIdProvider).value;
    if (familyId == null) {
      _showErrorSnackBar(l10n.couldNotFindFamilyRetryError);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteEventTitle),
          content: Text(l10n.deleteEventContent(event.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
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
      // Harmless no-op if this event never had a reminder scheduled —
      // cancel() on an unknown ID is silently ignored by the plugin.
      await ref.read(notificationServiceProvider).cancelEventReminder(event.id);
      _showSuccessSnackBar(l10n.eventDeleted(event.title));
    } catch (e) {
      _showErrorSnackBar(l10n.couldNotDeleteEventError(e.toString()));
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
        onSave:
            (
              title,
              description,
              time,
              category,
              recurrence,
              recurrenceEndDate,
              reminderMinutesBefore,
            ) async {
              // Captured before any `await` below — see main.dart's other
              // dialogs for why touching `context` after an await isn't safe.
              final l10n = AppLocalizations.of(context);
              final familyId = ref.read(currentFamilyIdProvider).value;
              if (familyId == null) {
                throw Exception(l10n.couldNotFindFamilyRetryError);
              }

              final eventDate = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                time.hour,
                time.minute,
              );
              final endTime = eventDate.add(const Duration(hours: 1));
              final notificationService = ref.read(notificationServiceProvider);

              if (event == null) {
                final created = await ref
                    .read(eventServiceProvider)
                    .createEvent(
                      familyId: familyId,
                      title: title,
                      category: category,
                      startTime: eventDate,
                      endTime: endTime,
                      description: description,
                      userName: _currentUserName,
                      recurrence: recurrence,
                      recurrenceEndDate: recurrenceEndDate,
                      reminderMinutesBefore: reminderMinutesBefore,
                    );
                if (reminderMinutesBefore != null) {
                  await _scheduleRemindersForEvents(created, l10n);
                }
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
                        'reminder_minutes_before': reminderMinutesBefore,
                      },
                    );
                if (reminderMinutesBefore != null) {
                  await _scheduleRemindersForEvents([
                    EventModel(
                      id: event.id,
                      title: title,
                      description: description,
                      date: eventDate,
                      category: category,
                      startTime: eventDate,
                      endTime: endTime,
                      userId: event.userId,
                      userName: event.userName,
                      recurrence: event.recurrence,
                      recurrenceEndDate: event.recurrenceEndDate,
                      seriesId: event.seriesId,
                      reminderMinutesBefore: reminderMinutesBefore,
                    ),
                  ], l10n);
                } else {
                  await notificationService.cancelEventReminder(event.id);
                }
              }

              return eventDate;
            },
      ),
    );

    if (savedDate != null && mounted) {
      setState(() {
        _selectedDate = eventKeyFor(savedDate);
      });
      final l10n = AppLocalizations.of(context);
      _showSuccessSnackBar(event == null ? l10n.eventAdded : l10n.eventUpdated);
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
        _maybeResyncReminders(events, AppLocalizations.of(context));
        return _buildCalendarScaffold(context);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).familyCalendarTitle),
        ),
        body: Center(
          child: Text(
            AppLocalizations.of(
              context,
            ).couldNotLoadEventsError(error.toString()),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN SCAFFOLD (rendered once family events have loaded)
  // ---------------------------------------------------------------------------

  Widget _buildCalendarScaffold(BuildContext context) {
    final dayEvents = _eventsForSelectedDay();
    final l10n = AppLocalizations.of(context);

    // Weather is layered on top of the calendar rather than gating it: no
    // location set, or a network hiccup, both just mean this map is empty —
    // see weatherForecastProvider's doc comment for why errors are
    // swallowed rather than surfaced here.
    final forecasts =
        ref.watch(weatherForecastProvider).valueOrNull ?? const [];
    final forecastByDay = <DateTime, DailyForecast>{
      for (final forecast in forecasts) eventKeyFor(forecast.date): forecast,
    };
    final selectedDayForecast = forecastByDay[eventKeyFor(_selectedDate)];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.familyCalendarTitle),

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
            tooltip: _showEmptyDays
                ? l10n.hideEmptyDaysTooltip
                : l10n.showEmptyDaysTooltip,
          ),

          // Family screen.
          IconButton(
            onPressed: () {
              context.push('/family');
            },
            icon: const Icon(Icons.family_restroom),
            tooltip: l10n.myFamilyTooltip,
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
                    _monthLabel(context, _currentMonth),
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
              children: _weekdayLabels(context)
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
                // Square cells (the default 1.0 ratio) are a hair too short
                // for their content — day number + spacer + event dot/"Open"
                // label overflows the bottom by a fraction of a pixel on
                // most screens. Slightly taller-than-wide cells fix it with
                // margin to spare, including for larger system font sizes.
                childAspectRatio: 0.82,
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

                final dayForecast = forecastByDay[eventKeyFor(day)];

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
                          Row(
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
                              // A glance-able hint, not a full forecast — see
                              // the "Events for X" panel below for the full
                              // day summary (temps + rain chance).
                              if (dayForecast != null)
                                Icon(
                                  weatherIconFor(dayForecast.weatherCode).icon,
                                  size: 12,
                                  color: weatherIconFor(
                                    dayForecast.weatherCode,
                                  ).color,
                                ),
                            ],
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
                                  context,
                                  (_events[eventKeyFor(day)]?.first.category) ??
                                      'other',
                                ).color,
                                shape: BoxShape.circle,
                              ),
                            )
                          else if (showEmpty)
                            Text(
                              l10n.openDayLabel,
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
                        l10n.eventsForDate(
                          DateFormat.Md(
                            Localizations.localeOf(context).toString(),
                          ).format(_selectedDate),
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed: () {
                          _showEventEditor();
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: l10n.addEventTooltip,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (selectedDayForecast != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            weatherIconFor(
                              selectedDayForecast.weatherCode,
                            ).icon,
                            size: 20,
                            color: weatherIconFor(
                              selectedDayForecast.weatherCode,
                            ).color,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.weatherDaySummary(
                                weatherDescription(
                                  l10n,
                                  selectedDayForecast.weatherCode,
                                ),
                                selectedDayForecast.tempMaxC.round(),
                                selectedDayForecast.tempMinC.round(),
                                selectedDayForecast.precipitationProbability,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (dayEvents.isEmpty)
                    Text(l10n.noEventsYet)
                  else
                    ...dayEvents.map((event) {
                      final meta = categoryMeta(context, event.category);
                      final eventForecast =
                          forecastByDay[eventKeyFor(event.date)];
                      // Only flag it for the categories where "it might
                      // rain" actually changes the plan — school/work
                      // happen regardless of weather.
                      final isOutdoorLeaning =
                          event.category == 'hobby' ||
                          event.category == 'other';

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
                              if (eventForecast != null &&
                                  eventForecast.isOutdoorRisk &&
                                  isOutdoorLeaning)
                                Tooltip(
                                  message: l10n.rainRiskTooltip(
                                    eventForecast.precipitationProbability,
                                  ),
                                  child: const Icon(
                                    Icons.umbrella,
                                    size: 18,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              if (event.seriesId != null)
                                Icon(
                                  Icons.repeat,
                                  size: 18,
                                  color: Theme.of(context).hintColor,
                                ),
                              if (event.reminderMinutesBefore != null)
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 18,
                                  color: Theme.of(context).hintColor,
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: l10n.editEventTooltip,
                                onPressed: () {
                                  _showEventEditor(event: event);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: l10n.deleteEventTooltip,
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
        label: Text(l10n.newEventButton),
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
  //
  // `recurrence`/`recurrenceEndDate` are only ever non-default when
  // creating a brand new event — see the recurrence picker below for why
  // it's hidden (rather than just disabled) once an event already exists.
  final Future<DateTime> Function(
    String title,
    String description,
    TimeOfDay time,
    String category,
    String recurrence,
    DateTime? recurrenceEndDate,
    int? reminderMinutesBefore,
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
  late String _selectedRecurrence;
  DateTime? _recurrenceEndDate;
  int? _selectedReminder;

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
    // Recurrence is only ever set at creation time (see the picker's own
    // comment below), so an existing event's dialog always starts on
    // 'none' regardless of whether that event is itself part of a series.
    _selectedRecurrence = 'none';
    _recurrenceEndDate = null;
    _selectedReminder = widget.event?.reminderMinutesBefore;
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

  Future<void> _pickRecurrenceEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      // Matches EventService's own materialization cap — an end date
      // further out than this wouldn't generate any additional
      // occurrences anyway.
      lastDate: now.add(const Duration(days: 366)),
    );

    if (picked != null && mounted) {
      setState(() => _recurrenceEndDate = picked);
    }
  }

  Future<void> _handleSave() async {
    // Read everything context-derived before the `await` below — after it,
    // this dialog may already be unmounted, and touching `context` (even
    // just to look up AppLocalizations) at that point is unsafe.
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();

    // Inline validation — shown on the field itself, dialog stays open so
    // nothing typed is lost.
    if (title.isEmpty) {
      setState(() {
        _titleError = l10n.titleRequiredError;
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
        _selectedRecurrence,
        _recurrenceEndDate,
        _selectedReminder,
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
      widget.onError(l10n.couldNotSaveEventError(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.event == null
            ? l10n.addEventDialogTitle
            : l10n.editEventDialogTitle,
      ),

      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: l10n.titleFieldLabel,
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
                decoration: InputDecoration(
                  labelText: l10n.notesLabel,
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
                  l10n.categoryLabel,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: kEventCategories.map((category) {
                  final meta = categoryMeta(context, category);
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
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                    ),
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
                label: Text(l10n.eventTimeLabel(_selectedTime.format(context))),
              ),

              // Recurrence can only be set when an event is first created —
              // an occurrence generated from a series is just a normal event
              // document afterwards (see EventService), so there's no single
              // well-defined meaning for "change the recurrence" on one
              // existing occurrence. A series that already exists shows a
              // plain status note lower down instead of this picker.
              if (widget.event == null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.recurrenceLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: kRecurrenceOptions.map((option) {
                    final selected = _selectedRecurrence == option;
                    return ChoiceChip(
                      label: Text(recurrenceDisplayName(l10n, option)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedRecurrence = option;
                          if (option == 'none') _recurrenceEndDate = null;
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_selectedRecurrence != 'none') ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickRecurrenceEndDate,
                    icon: const Icon(Icons.event_busy),
                    label: Text(
                      _recurrenceEndDate == null
                          ? l10n.recurrenceNoEndDate
                          : l10n.recurrenceEndsOn(
                              DateFormat.yMMMd().format(_recurrenceEndDate!),
                            ),
                    ),
                  ),
                  if (_recurrenceEndDate != null)
                    TextButton(
                      onPressed: () =>
                          setState(() => _recurrenceEndDate = null),
                      child: Text(l10n.recurrenceClearEndDate),
                    ),
                ],
              ] else if (widget.event!.seriesId != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.repeat, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.partOfRecurringSeriesNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.reminderLabel,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: kReminderOffsets.map((offset) {
                  final selected = _selectedReminder == offset;
                  return ChoiceChip(
                    avatar: offset == null
                        ? null
                        : Icon(
                            Icons.notifications_active,
                            size: 18,
                            color: selected ? Colors.white : null,
                          ),
                    label: Text(reminderOffsetDisplayName(l10n, offset)),
                    selected: selected,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedReminder = offset);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),

        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
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

// Event data now lives in lib/models/event_model.dart (EventModel), backed
// live by Firestore via lib/services/event_service.dart + familyEventsProvider.
