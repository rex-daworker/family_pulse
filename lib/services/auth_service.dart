import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes — used by authStateProvider
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up — called by AuthStateNotifier.signUp()
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final String uid = credential.user!.uid;

      // Save user data to Firestore
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': role,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow; // Let the provider handle the error
    }
  }

  // Sign in — called by AuthStateNotifier.signIn()
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow; // Let the provider handle the error
    }
  }

  // Sign out — called by AuthStateNotifier.signOut()
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow; // Let the provider handle the error
    }
  }

  // Get user data from Firestore — used by userDataProvider
  Future<UserModel?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    } catch (e) {
      return null; // Return null if user data doesn't exist
    }
  }
}
