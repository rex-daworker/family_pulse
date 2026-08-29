import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules and cancels the on-device reminders for calendar events.
///
/// Deliberately local-only, not server-pushed: reminders fire from the
/// device that created/edited the event, via flutter_local_notifications.
/// That means no backend cost and it works offline, but it also means two
/// real limits worth knowing about:
///
///  1. A reminder only fires on the device that scheduled it — it does not
///     follow the event to every family member's phone. Building that
///     properly needs a server-side push (Cloud Functions + FCM), which is
///     a bigger, separate piece of work.
///  2. iOS hard-caps an app at 64 pending local notifications, and a
///     device reboot on Android clears any that were scheduled. Both are
///     mitigated (not eliminated) by `resyncUpcomingReminders`, which
///     re-schedules reminders for the near-term window every time the app
///     starts, rather than trying to schedule everything for a whole
///     recurring series years in advance.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'event_reminders';
  static const String _channelName = 'Event reminders';
  static const String _channelDescription =
      'Reminders for upcoming family calendar events';

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Fall back to whatever the timezone database considers UTC rather
      // than crashing app start over a timezone lookup failing on some
      // device — reminders will just fire on UTC-relative times until the
      // next successful resync.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
          ),
        );

    _initialized = true;
  }

  /// Requests the notification permission — Android 13+'s runtime
  /// POST_NOTIFICATIONS prompt and iOS's alert/sound/badge prompt. Call
  /// this once the user is past auth/onboarding, not at cold start, so the
  /// system prompt has some context behind it.
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Firestore doc IDs are strings; local-notification IDs must be a
  /// 32-bit int. `hashCode` can be negative, so mask down to a positive
  /// 31-bit value — stable for a given event ID, which is what lets
  /// scheduleEventReminder overwrite (rather than duplicate) an existing
  /// reminder for the same event.
  int notificationIdFor(String eventId) => eventId.hashCode & 0x7fffffff;

  /// Schedules (or reschedules, if one already exists for this event) a
  /// single local notification `minutesBefore` minutes ahead of
  /// [eventTime]. No-ops quietly if that moment has already passed —
  /// callers don't need to check themselves.
  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required String body,
    required DateTime eventTime,
    required int minutesBefore,
  }) async {
    if (!_initialized) return;

    final fireTime = eventTime.subtract(Duration(minutes: minutesBefore));
    if (fireTime.isBefore(DateTime.now())) {
      await cancelEventReminder(eventId);
      return;
    }

    await _plugin.zonedSchedule(
      id: notificationIdFor(eventId),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelEventReminder(String eventId) async {
    if (!_initialized) return;
    await _plugin.cancel(id: notificationIdFor(eventId));
  }
}
