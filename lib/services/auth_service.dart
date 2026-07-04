import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current logged-in user
  User? get currentUser => _auth.currentUser;

  // Stream — listens for login/logout changes in real time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── SIGN UP ───────────────────────────────────────────────
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'parent' or 'child'
    required String familyId,
  }) async {
    try {
      // 1. Create the Firebase Auth account
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Save the user profile to Firestore
      // Document ID = Firebase Auth UID (this is how security rules identify them)
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': name,
        'email': email,
        'role': role,
      });

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