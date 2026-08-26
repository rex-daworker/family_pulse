import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_member_model.dart';
import '../models/family_model.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';

// 1. Expose the AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 2. Expose the FamilyService instance
final familyServiceProvider = Provider<FamilyService>((ref) {
  return FamilyService();
});

// 3. Stream Provider tracking whether a user is logged in or out
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).userChanges;
});

// 4. Future Provider that resolves the current user's Family ID
// The frontend will use this to automatically feed the Event Streams
final currentFamilyIdProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;

  final familyService = ref.watch(familyServiceProvider);
  return await familyService.findFamilyIdByUserId(authState.uid);
});

// 5. Future Provider that resolves the current user's family info — name,
// creation date, and the ID itself (which doubles as the referral code).
// Settings uses this; nothing here duplicates currentFamilyIdProvider's
// job, it just fetches the actual document once an ID is known.
final currentFamilyProvider = FutureProvider<FamilyModel?>((ref) async {
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  if (familyId == null) return null;

  final familyService = ref.watch(familyServiceProvider);
  return await familyService.getFamily(familyId);
});

// 6. Live list of the current user's family members — the Free Time finder
// uses this to know whose calendars to check when looking for shared
// open windows.
final familyMembersProvider = StreamProvider<List<FamilyMember>>((ref) async* {
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  if (familyId == null) {
    yield <FamilyMember>[];
    return;
  }

  final familyService = ref.watch(familyServiceProvider);
  yield* familyService.getFamilyMembers(familyId);
});
