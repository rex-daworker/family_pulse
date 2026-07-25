import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  EventModel({
    this.id = '',
    required this.title,
    required this.description,
    required this.date,
    this.category = '',
    this.startTime,
    this.endTime,
    this.userId = '',
    this.userName = '',
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String category;
  final DateTime? startTime;
  final DateTime? endTime;
  final String userId;
  final String userName;

  /// Builds an EventModel from a Firestore document snapshot's data map.
  factory EventModel.fromMap(Map<String, dynamic> data, String id) {
    final dateValue = data['date'];
    final startTimeValue = data['start_time'];
    final endTimeValue = data['end_time'];

    DateTime resolvedDate = DateTime.now();
    if (dateValue is Timestamp) {
      resolvedDate = dateValue.toDate();
    } else if (dateValue is DateTime) {
      resolvedDate = dateValue;
    } else if (dateValue is String) {
      resolvedDate = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else if (startTimeValue is Timestamp) {
      // Fallback for events written before the "date" field existed —
      // derive it from start_time instead of defaulting to today.
      resolvedDate = startTimeValue.toDate();
    }

    return EventModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: resolvedDate,
      category: data['category'] ?? '',
      startTime: startTimeValue is Timestamp
          ? startTimeValue.toDate()
          : (startTimeValue is DateTime ? startTimeValue : null),
      endTime: endTimeValue is Timestamp
          ? endTimeValue.toDate()
          : (endTimeValue is DateTime ? endTimeValue : null),
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
    );
  }

  /// Converts this object back into a map, ready to write to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'category': category,
      'start_time': startTime ?? date,
      'end_time': endTime ?? date,
      'user_id': userId,
      'user_name': userName,
    };
  }
}