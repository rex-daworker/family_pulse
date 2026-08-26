import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

// 1. Expose a single instance of the EventService across the app
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

// 1b. NotificationService is a plain singleton (see its own file for why —
// the plugin it wraps is itself process-global), exposed as a provider
// purely so call sites can `ref.read` it like every other service instead
// of importing a bare singleton.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

// 2. Real-time Stream Provider for tracking all family calendar events
// The frontend will watch this to automatically paint the column layout layout
final familyEventsStreamProvider = StreamProvider.family<QuerySnapshot, String>(
  (ref, familyId) {
    final eventService = ref.watch(eventServiceProvider);
    return eventService.getFamilyEvents(familyId);
  },
);

// 3. Real-time Stream Provider for tracking an individual family member's lanes
final memberEventsStreamProvider =
    StreamProvider.family<QuerySnapshot, MemberEventsArgs>((ref, args) {
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

// 5. Convenience provider for FamilyCalendarPage:
//   - resolves the current user's familyId automatically via
//     currentFamilyIdProvider, so call sites don't have to pass one in
//   - maps the raw QuerySnapshot into typed EventModel instances, since the
//     calendar UI wants typed events rather than raw Firestore documents
// Emits an empty list while there's no family yet — matches the router's
// redirect, which already keeps unaffiliated users off any screen that
// would watch this.
//
// Goes through eventServiceProvider directly rather than
// familyEventsStreamProvider(familyId).stream — the .stream modifier on a
// family provider is deprecated as of riverpod ^2.6.
final familyEventsProvider = StreamProvider<List<EventModel>>((ref) async* {
  final familyId = await ref.watch(currentFamilyIdProvider.future);

  if (familyId == null) {
    yield <EventModel>[];
    return;
  }

  final eventService = ref.watch(eventServiceProvider);

  yield* eventService.getFamilyEvents(familyId).map((snapshot) {
    return snapshot.docs
        .map(
          (doc) =>
              EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  });
});
