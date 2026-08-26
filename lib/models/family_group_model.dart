import 'package:cloud_firestore/cloud_firestore.dart';

/// A sub-group within a family — e.g. "Kids" or "Chores squad" — just a
/// name and which members belong to it. Deliberately minimal for now: no
/// group-specific calendar or events yet, that's still on the roadmap.
class FamilyGroupModel {
  FamilyGroupModel({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> memberIds;
  final DateTime createdAt;

  factory FamilyGroupModel.fromMap(Map<String, dynamic> data, String id) {
    return FamilyGroupModel(
      id: id,
      name: data['name'] ?? '',
      memberIds: List<String>.from(data['member_ids'] ?? const []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
