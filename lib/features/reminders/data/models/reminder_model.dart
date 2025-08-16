// Reminder Model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:protobuf/protobuf.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class ReminderModel {
  final String id;
  final String userId;
  final String type;
  final String categoryId;
  final String frequency;
  final String time;
  final int? dayOfWeek;
  final DateTime? createdAt;
  final int? notificationId;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.categoryId,
    required this.frequency,
    required this.time,
    this.dayOfWeek,
    this.createdAt,
    this.notificationId,
  });

  factory ReminderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReminderModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      frequency: data['frequency'] as String? ?? '',
      time: _parseTime(data['time']),
      dayOfWeek: data['dayOfWeek'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      notificationId: data['notificationId'] as int?,
    );
  }

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      time: _parseTime(json['time']),
      dayOfWeek: json['dayOfWeek'] as int?,
      createdAt: _parseDate(json['createdAt']),
      notificationId: json['notificationId'] as int?,
    );
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      time: map['time'] as String? ?? '',
      dayOfWeek: map['dayOfWeek'] as int?,
      createdAt: _parseDate(map['createdAt']),
      notificationId: map['notificationId'] as int?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in ReminderModel: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  static String _parseTime(dynamic value) {
    if (value is String) {
      try {
        DateFormat('HH:mm').parse(value);
        return value;
      } catch (e) {
        print('Invalid time format in ReminderModel: $value, error: $e');
        return '';
      }
    } else if (value is Timestamp) {
      return DateFormat('HH:mm').format(value.toDate());
    }
    return '';
  }

  List<int> toProto() {
    final proto = pb.ReminderModel()
      ..id = id
      ..userId = userId
      ..type = type
      ..categoryId = categoryId
      ..frequency = frequency
      ..time = time
      ..dayOfWeek = dayOfWeek ?? 0
      ..createdAt = createdAt?.toIso8601String() ?? ''
      ..notificationId = notificationId ?? 0;
    return proto.writeToBuffer();
  }

  factory ReminderModel.fromProto(List<int> bytes) {
    final proto = pb.ReminderModel.fromBuffer(bytes);
    return ReminderModel(
      id: proto.id,
      userId: proto.userId,
      type: proto.type,
      categoryId: proto.categoryId,
      frequency: proto.frequency,
      time: proto.time,
      dayOfWeek: proto.hasDayOfWeek() ? proto.dayOfWeek : null,
      createdAt: proto.hasCreatedAt() ? DateTime.parse(proto.createdAt) : null,
      notificationId: proto.hasNotificationId() ? proto.notificationId : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'categoryId': categoryId,
      'frequency': frequency,
      'time': time,
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (notificationId != null) 'notificationId': notificationId,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'categoryId': categoryId,
      'frequency': frequency,
      'time': time,
      'dayOfWeek': dayOfWeek,
      'createdAt': createdAt?.toIso8601String(),
      'notificationId': notificationId,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'categoryId': categoryId,
      'frequency': frequency,
      'time': time,
      'dayOfWeek': dayOfWeek,
      'createdAt': createdAt?.toIso8601String(),
      'notificationId': notificationId,
    };
  }
}