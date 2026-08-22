import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current logged-in user
  User? get currentUser => _auth.currentUser;

  // Stream — listens for login/logout changes in real time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Stream — listens for user state, token, or profile changes
  Stream<User?> get userChanges => _auth.userChanges();

  // ─── SIGN UP ───────────────────────────────────────────────

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        // Store the display name in Firebase Authentication.
        await user.updateDisplayName(name);

        // Store the user's information in Firestore.
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': role,
        });
      }

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

  // ─── GET USER DATA ─────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return document.data();
  }

  // ─── SIGN OUT ──────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── ERROR HANDLER ─────────────────────────────────────────

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

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
