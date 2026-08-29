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
    this.recurrence = 'none',
    this.recurrenceEndDate,
    this.seriesId,
    this.reminderMinutesBefore,
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

  /// 'none' | 'daily' | 'weekly' | 'monthly' | 'yearly' — see
  /// core/recurrence_options.dart. Stored on every occurrence, not just the
  /// first one, so a single occurrence still reads as "part of a series"
  /// after the app has only ever fetched it on its own.
  final String recurrence;

  /// Optional cutoff for a recurring series — occurrences are only
  /// materialized up to this date (or a built-in cap, whichever is
  /// sooner). Null means "no end date set".
  final DateTime? recurrenceEndDate;

  /// Shared by every occurrence generated from the same recurring event,
  /// so they can be recognized as one series later even though each is a
  /// separate Firestore document. Null for a plain one-off event.
  final String? seriesId;

  /// Minutes before `startTime` to fire a local reminder notification.
  /// Null means no reminder is set for this occurrence.
  final int? reminderMinutesBefore;

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

    final recurrenceEndValue = data['recurrence_end_date'];

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
      recurrence: data['recurrence'] ?? 'none',
      recurrenceEndDate: recurrenceEndValue is Timestamp
          ? recurrenceEndValue.toDate()
          : null,
      seriesId: data['series_id'] as String?,
      reminderMinutesBefore: (data['reminder_minutes_before'] as num?)?.toInt(),
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
      'recurrence': recurrence,
      'recurrence_end_date': recurrenceEndDate,
      'series_id': seriesId,
      'reminder_minutes_before': reminderMinutesBefore,
    };
  }
}
