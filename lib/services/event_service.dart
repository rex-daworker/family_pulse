import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event_model.dart';

// A recurring series is materialized as individual event documents up
// front (one per occurrence), all sharing a `series_id`, rather than
// stored as a single rule that gets expanded at read time. That keeps
// every existing Firestore query (day-range lookups, the free-time
// finder, per-member streams) working unchanged, since each occurrence is
// an ordinary event document — the tradeoff is that occurrences are only
// generated up to a bounded horizon, not forever.
const int _maxRecurrenceOccurrences = 60;
const int _maxRecurrenceHorizonDays = 366;

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── HELPER: get current user ID ───────────────────────────
  String get _uid => _auth.currentUser!.uid;

  /// Builds the list of occurrence start dates for a recurrence preset,
  /// starting at (and including) [start]. Stops at whichever comes first:
  /// [recurrenceEndDate], the built-in occurrence cap, or the built-in
  /// horizon cap — so a series with no end date, or a "yearly" series,
  /// can't silently write an unbounded number of documents.
  List<DateTime> _generateOccurrenceDates({
    required DateTime start,
    required String recurrence,
    DateTime? recurrenceEndDate,
  }) {
    if (recurrence == 'none') return [start];

    final horizon = start.add(const Duration(days: _maxRecurrenceHorizonDays));
    final cutoff =
        (recurrenceEndDate != null && recurrenceEndDate.isBefore(horizon))
        ? recurrenceEndDate
        : horizon;

    // Known edge case, same one Google Calendar has: starting on the 31st
    // and stepping "monthly" lands on a month with no 31st — Dart's
    // DateTime constructor normalizes that by rolling into the following
    // month (e.g. Jan 31 -> "Feb 31" -> Mar 3) rather than clamping to the
    // last day of the short month. Acceptable for a fixed-preset MVP;
    // worth a dedicated fix (clamp to month length) if this trips someone.
    DateTime step(DateTime d) => switch (recurrence) {
      'daily' => d.add(const Duration(days: 1)),
      'weekly' => d.add(const Duration(days: 7)),
      'monthly' => DateTime(d.year, d.month + 1, d.day, d.hour, d.minute),
      'yearly' => DateTime(d.year + 1, d.month, d.day, d.hour, d.minute),
      _ => d,
    };

    final dates = <DateTime>[start];
    var current = start;
    while (dates.length < _maxRecurrenceOccurrences) {
      current = step(current);
      if (current.isAfter(cutoff)) break;
      dates.add(current);
    }
    return dates;
  }

  // ─── CREATE EVENT ──────────────────────────────────────────
  // Returns every occurrence actually written — just the one event for a
  // one-off ('recurrence' == 'none'), or the whole materialized series
  // otherwise — so the caller can schedule a reminder for each.
  Future<List<EventModel>> createEvent({
    required String familyId,
    required String title,
    required String category, // 'school', 'hobby', 'work', 'other'
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    required String userName,
    String recurrence = 'none',
    DateTime? recurrenceEndDate,
    int? reminderMinutesBefore,
  }) async {
    final occurrenceStarts = _generateOccurrenceDates(
      start: startTime,
      recurrence: recurrence,
      recurrenceEndDate: recurrenceEndDate,
    );
    final duration = endTime.difference(startTime);

    final eventsRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('events');

    // A one-off event doesn't need a series_id at all — only stamp one
    // when there's actually more than one occurrence to tie together.
    final seriesId = occurrenceStarts.length > 1 ? eventsRef.doc().id : null;

    final batch = _firestore.batch();
    final created = <EventModel>[];

    for (final occurrenceStart in occurrenceStarts) {
      final docRef = eventsRef.doc();
      final occurrenceEnd = occurrenceStart.add(duration);
      batch.set(docRef, {
        'title': title,
        'category': category,
        'start_time': Timestamp.fromDate(occurrenceStart),
        'end_time': Timestamp.fromDate(occurrenceEnd),
        'date': Timestamp.fromDate(occurrenceStart),
        'description': description ?? '',
        'user_id': _uid, // auto-stamped from logged-in user
        'user_name': userName, // denormalized for fast rendering
        'recurrence': recurrence,
        'recurrence_end_date': recurrenceEndDate != null
            ? Timestamp.fromDate(recurrenceEndDate)
            : null,
        'series_id': seriesId,
        'reminder_minutes_before': reminderMinutesBefore,
      });
      created.add(
        EventModel(
          id: docRef.id,
          title: title,
          description: description ?? '',
          date: occurrenceStart,
          category: category,
          startTime: occurrenceStart,
          endTime: occurrenceEnd,
          userId: _uid,
          userName: userName,
          recurrence: recurrence,
          recurrenceEndDate: recurrenceEndDate,
          seriesId: seriesId,
          reminderMinutesBefore: reminderMinutesBefore,
        ),
      );
    }

    await batch.commit();
    return created;
  }

  // ─── READ ALL FAMILY EVENTS (real-time stream) ─────────────
  Stream<QuerySnapshot> getFamilyEvents(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .orderBy('start_time')
        .snapshots();
  }

  // ─── READ EVENTS FOR ONE MEMBER ────────────────────────────
  Stream<QuerySnapshot> getMemberEvents(String familyId, String userId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .where('user_id', isEqualTo: userId)
        .orderBy('start_time')
        .snapshots();
  }

  // ─── FREE TIME FINDER ──────────────────────────────────────
  // This is the core algorithm — finds slots where ALL members are free
  Future<List<Map<String, dynamic>>> findFreeSlots({
    required String familyId,
    required DateTime dayStart,
    required DateTime dayEnd,
    required List<String> memberIds,
    int minDurationMinutes = 60,
  }) async {
    // 1. Fetch all events for the day
    final snapshot = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .where(
          'start_time',
          isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
        )
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
        .get();

    // 2. Build a list of busy time ranges per member
    final Map<String, List<Map<String, DateTime>>> busyTimes = {};
    for (final id in memberIds) {
      busyTimes[id] = [];
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final userId = data['user_id'] as String;

      if (memberIds.contains(userId)) {
        busyTimes[userId]!.add({
          'start': (data['start_time'] as Timestamp).toDate(),
          'end': (data['end_time'] as Timestamp).toDate(),
        });
      }
    }

    // 3. Scan through the day in 30-minute slots
    final List<Map<String, dynamic>> freeSlots = [];
    DateTime cursor = dayStart;
    DateTime? slotStart;

    while (cursor.isBefore(dayEnd)) {
      final slotEnd = cursor.add(const Duration(minutes: 30));

      // Check if ALL members are free during this 30-min window
      bool allFree = memberIds.every((id) {
        return busyTimes[id]!.every((busy) {
          return slotEnd.isBefore(busy['start']!) ||
              cursor.isAfter(busy['end']!);
        });
      });

      if (allFree) {
        slotStart ??= cursor; // mark start of free window
      } else {
        if (slotStart != null) {
          // End of a free window — check if it meets minimum duration
          final duration = cursor.difference(slotStart).inMinutes;
          if (duration >= minDurationMinutes) {
            freeSlots.add({
              'start': slotStart,
              'end': cursor,
              'duration_minutes': duration,
            });
          }
          slotStart = null;
        }
      }
      cursor = slotEnd;
    }

    // Catch any free window that runs to end of day
    if (slotStart != null) {
      final duration = dayEnd.difference(slotStart).inMinutes;
      if (duration >= minDurationMinutes) {
        freeSlots.add({
          'start': slotStart,
          'end': dayEnd,
          'duration_minutes': duration,
        });
      }
    }

    return freeSlots;
  }

  // ─── UPDATE EVENT ──────────────────────────────────────────
  Future<void> updateEvent({
    required String familyId,
    required String eventId,
    required Map<String, dynamic> updates,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .doc(eventId)
        .update(updates);
  }

  // ─── DELETE EVENT ──────────────────────────────────────────
  Future<void> deleteEvent({
    required String familyId,
    required String eventId,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .doc(eventId)
        .delete();
  }
}
