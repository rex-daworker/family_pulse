import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_group_model.dart';
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
    String label = '',
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
      'label': label,
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
    String label = '',
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
          'label': label,
        });
  }

  // 2b. A parent renaming another member (or updating their label). Scoped
  // to exactly these two fields — matches the firestore.rules restriction
  // that a non-self update may only touch name/label, never role or email.
  Future<void> updateMemberInfo({
    required String familyId,
    required String userId,
    required String name,
    required String label,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('users')
        .doc(userId)
        .update({'name': name, 'label': label});
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

  // 6. Sub-groups within a family (e.g. "Kids", "Chores squad") — just a
  // name plus a list of member user IDs. Any family member can create or
  // edit one, same permissiveness as events; nothing in the roadmap called
  // for group-specific permissions beyond "you're in the family."
  Future<String> createGroup({
    required String familyId,
    required String name,
    required List<String> memberIds,
  }) async {
    final doc = await _firestore
        .collection('families')
        .doc(familyId)
        .collection('groups')
        .add({
          'name': name,
          'member_ids': memberIds,
          'created_at': FieldValue.serverTimestamp(),
        });
    return doc.id;
  }

  Stream<List<FamilyGroupModel>> getGroups(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('groups')
        .orderBy('created_at')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FamilyGroupModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateGroup({
    required String familyId,
    required String groupId,
    required String name,
    required List<String> memberIds,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('groups')
        .doc(groupId)
        .update({'name': name, 'member_ids': memberIds});
  }

  Future<void> deleteGroup({
    required String familyId,
    required String groupId,
  }) async {
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('groups')
        .doc(groupId)
        .delete();
  }
}
