import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final String name;
  final DateTime createdAt;

  FamilyModel({required this.id, required this.name, required this.createdAt});

  /// Builds a FamilyModel from a Firestore document snapshot's data map.
  factory FamilyModel.fromMap(Map<String, dynamic> data, String id) {
    return FamilyModel(
      id: id,
      name: data['name'] ?? '',
      // Firestore timestamps come back as a Timestamp object, not DateTime,
      // so we convert it here. Falls back to "now" if missing.
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this object back into a map, ready to write to Firestore.
  Map<String, dynamic> toMap() {
    return {'name': name, 'created_at': createdAt};
  }
}
