import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
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