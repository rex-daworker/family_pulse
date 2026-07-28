import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Create a brand new family and add the creator as the first parent member
  Future<String> createFamily({
    required String familyName,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    // Create the master family document
    final familyDocRef = await _firestore.collection('families').add({
      'name': familyName,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Add the creator to the nested users subcollection
    await familyDocRef.collection('users').doc(userId).set({
      'name': userName,
      'role': 'parent',
      'email': userEmail,
    });

    return familyDocRef.id; // Returns the generated family_id
  }

  // 2. Add an existing authenticated user to an existing family group
  Future<void> joinFamily({
    required String familyId,
    required String userId,
    required String userName,
    required String userEmail,
    required String role, // 'parent' or 'child'
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('users')
        .doc(userId)
        .set({'name': userName, 'role': role, 'email': userEmail});
  }

  // 3. CRITICAL LOOKUP: Find which family a user belongs to by their User ID
  // Uses a Collection Group query to search all "users" subcollections simultaneously
  Future<String?> findFamilyIdByUserId(String userId) async {
    final querySnapshot = await _firestore
        .collectionGroup('users')
        .where(FieldPath.documentId, isEqualTo: userId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Step back up out of the subcollection to get the parent family ID
      return querySnapshot.docs.first.reference.parent.parent!.id;
    }
    return null; // User doesn't belong to a family yet
  }
}
