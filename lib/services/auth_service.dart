import 'package:firebase_auth/firebase_auth.dart';

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
      throw _handleAuthError(e);
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
      throw _handleAuthError(e);
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
      throw Exception('You need to be signed in to do that.');
    }
    await user.updateDisplayName(name);
    await user.reload();
  }

  // ─── ERROR HANDLER ─────────────────────────────────────────
  // Converts Firebase error codes into readable messages
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
