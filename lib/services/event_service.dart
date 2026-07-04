import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── HELPER: get current user ID ───────────────────────────
  String get _uid => _auth.currentUser!.uid;

  // ─── CREATE EVENT ──────────────────────────────────────────
  Future<void> createEvent({
    required String familyId,
    required String title,
    required String category, // 'school', 'hobby', 'work', 'other'
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    required String userName,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('events')
        .add({
      'title': title,
      'category': category,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'description': description ?? '',
      'user_id': _uid,       // auto-stamped from logged-in user
      'user_name': userName, // denormalized for fast rendering
    });
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
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
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