import 'package:firebase_auth/firebase_auth.dart';

/// Thrown for auth failures the UI should show a message for. `code` is a
/// stable, language-neutral identifier — never shown to the user directly.
/// Screens translate it via `localizedErrorMessage()` (core/error_messages.dart)
/// so the same failure reads correctly in whatever language is active,
/// instead of this service layer (which has no BuildContext / locale of
/// its own) baking in English text.
class AuthError implements Exception {
  const AuthError(this.code);
  final String code;

  @override
  String toString() => 'AuthError($code)';
}

class AuthService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current logged-in user
  User? get currentUser => _auth.currentUser;

  // Stream — listens for login/logout changes in real time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Stream — listens for user state, token, or profile changes (used by AuthProvider)
  Stream<User?> get userChanges => _auth.userChanges();

  // ─── SIGN UP ───────────────────────────────────────────────
  // Only creates the auth account. Family membership is handled
  // separately by FamilyService once the user creates or joins one.
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store the display name so family screens can prefill it
      await credential.user?.updateDisplayName(name);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthError(_authErrorCode(e));
    }
  }

  // ─── SIGN IN ───────────────────────────────────────────────
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthError(_authErrorCode(e));
    }
  }

  // ─── SIGN OUT ──────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── UPDATE DISPLAY NAME ───────────────────────────────────
  // Used by the Settings screen so a user can fix a typo or just change
  // what the app calls them. reload() is required afterward — otherwise
  // the in-memory User object (and anything watching userChanges) keeps
  // showing the old name until the next full sign-in.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthError('not-signed-in');
    }
    await user.updateDisplayName(name);
    await user.reload();
  }

  // ─── ERROR HANDLER ─────────────────────────────────────────
  // Normalizes a Firebase error code into one of the codes
  // localizedErrorMessage() knows how to translate; anything unrecognized
  // collapses to 'unknown' rather than leaking a raw Firebase code to the UI.
  String _authErrorCode(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
      case 'email-already-in-use':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
        return e.code;
      default:
        return 'unknown';
    }
  }
}
