import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_member_model.dart';
import '../models/family_model.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Create a brand new family and add the creator as the first parent member
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
      'user_id': userId, // needed for collection group lookups
      'name': userName,
      'role': 'parent',
      'email': userEmail,
    });

    return familyDocRef.id;
  }

  // 2. Add an existing authenticated user to an existing family group
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
          'user_id': userId, // needed for collection group lookups
          'name': userName,
          'role': role,
          'email': userEmail,
        });
  }

  // 3. Find which family a user belongs to by their User ID.
  // Queries on a real 'user_id' field — FieldPath.documentId doesn't work
  // in collection group queries (it requires a full document path).
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

  // 4. Fetch a family's own info (name, creation date) by its ID — this ID
  // doubles as the referral code members join with, so the Settings screen
  // can show "name / created / code" together in one place.
  Future<FamilyModel?> getFamily(String familyId) async {
    final doc = await _firestore.collection('families').doc(familyId).get();
    if (!doc.exists) return null;
    return FamilyModel.fromMap(doc.data()!, doc.id);
  }

  // 5. Live list of everyone in a family — the Free Time finder uses this
  // to know whose calendars to check. This is a plain (non-collection-group)
  // query against one family's `users` subcollection, so it's covered by
  // the more specific `families/{familyId}/users/{userId}` rule (any
  // member can read the whole subcollection), not the collection-group
  // rule that only permits reading your own membership doc.
  Stream<List<FamilyMember>> getFamilyMembers(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FamilyMember.fromMap(doc.data()))
              .toList(),
        );
  }
}
