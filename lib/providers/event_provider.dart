import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/event_service.dart';

// 1. Expose a single instance of the EventService across the app
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

// 2. Real-time Stream Provider for tracking all family calendar events
// The frontend will watch this to automatically paint the column layout layout
final familyEventsStreamProvider = StreamProvider.family<QuerySnapshot, String>((ref, familyId) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getFamilyEvents(familyId);
});

// 3. Real-time Stream Provider for tracking an individual family member's lanes
final memberEventsStreamProvider = StreamProvider.family<QuerySnapshot, MemberEventsArgs>((ref, args) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getMemberEvents(args.familyId, args.userId);
});

// 4. An arguments data container class required by Riverpod for multiple inputs
class MemberEventsArgs {
  final String familyId;
  final String userId;

  MemberEventsArgs({required this.familyId, required this.userId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberEventsArgs &&
          runtimeType == other.runtimeType &&
          familyId == other.familyId &&
          userId == other.userId;

  @override
  int get hashCode => familyId.hashCode ^ userId.hashCode;
}

