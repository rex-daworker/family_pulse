import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime startTime;
  final DateTime endTime;
  final String userId;
  final String userName;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.userId,
    required this.userName,
  });

  /// Builds an EventModel from a Firestore document snapshot's data map.
  factory EventModel.fromMap(Map<String, dynamic> data, String id) {
    return EventModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      startTime: (data['start_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['end_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
    );
  }

  /// Converts this object back into a map, ready to write to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'start_time': startTime,
      'end_time': endTime,
      'user_id': userId,
      'user_name': userName,
    };
  }
}
