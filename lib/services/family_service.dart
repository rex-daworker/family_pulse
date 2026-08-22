import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/family_model.dart';
import '../models/user_model.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // CREATE FAMILY
  // ---------------------------------------------------------------------------

  // Creates a new family and adds the creator as the first parent.
  Future<String> createFamily({
    required String familyName,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final familyDocRef = await _firestore.collection('families').add({
      'name': familyName,
      'created_at': FieldValue.serverTimestamp(),
    });

    await familyDocRef.collection('users').doc(userId).set({
      'user_id': userId,
      'name': userName,
      'role': 'parent',
      'email': userEmail,
    });

    return familyDocRef.id;
  }

  // ---------------------------------------------------------------------------
  // JOIN FAMILY
  // ---------------------------------------------------------------------------

  // Adds an existing authenticated user to an existing family.
  Future<void> joinFamily({
    required String familyId,
    required String userId,
    required String userName,
    required String userEmail,
    required String role,
  }) async {
    final familyDoc = await _firestore
        .collection('families')
        .doc(familyId)
        .get();

    if (!familyDoc.exists) {
      throw Exception('Family not found. Check the code and try again.');
    }

    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('users')
        .doc(userId)
        .set({
          'user_id': userId,
          'name': userName,
          'role': role,
          'email': userEmail,
        });
  }

  // ---------------------------------------------------------------------------
  // FIND FAMILY FOR USER
  // ---------------------------------------------------------------------------

  // Finds which family a user belongs to.
  Future<String?> findFamilyIdByUserId(String userId) async {
    final querySnapshot = await _firestore
        .collectionGroup('users')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.reference.parent.parent!.id;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // GET FAMILY
  // ---------------------------------------------------------------------------

  // Gets the family information using its family ID.
  Future<FamilyModel?> getFamily(String familyId) async {
    final document = await _firestore
        .collection('families')
        .doc(familyId)
        .get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null) {
      return null;
    }

    return FamilyModel.fromMap(data, document.id);
  }

  // ---------------------------------------------------------------------------
  // WATCH FAMILY MEMBERS
  // ---------------------------------------------------------------------------

  // Watches the users inside a family in real time.
  Stream<List<UserModel>> watchFamilyMembers(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('users')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((document) {
            return UserModel.fromMap(document.data(), document.id);
          }).toList();
        });
  }
}
