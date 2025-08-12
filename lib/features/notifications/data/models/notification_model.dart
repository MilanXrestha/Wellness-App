
// Notification Model
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:protobuf/protobuf.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final Map<String, dynamic> payload;
  final DateTime? timestamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.payload,
    this.timestamp,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      payload: Map<String, dynamic>.from(data['payload'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      timestamp: _parseDate(json['timestamp']),
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? '',
      isRead: (map['isRead'] as int? ?? 0) == 1,
      payload: jsonDecode(map['payload'] as String? ?? '{}'),
      timestamp: _parseDate(map['timestamp']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in NotificationModel: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  List<int> toProto() {
    final proto = pb.NotificationModel()
      ..id = id
      ..userId = userId
      ..title = title
      ..body = body
      ..type = type
      ..isRead = isRead
      ..payload.addAll(payload.map((k, v) => MapEntry(k, v.toString())))
      ..timestamp = timestamp?.toIso8601String() ?? '';
    return proto.writeToBuffer();
  }

  factory NotificationModel.fromProto(List<int> bytes) {
    final proto = pb.NotificationModel.fromBuffer(bytes);
    return NotificationModel(
      id: proto.id,
      userId: proto.userId,
      title: proto.title,
      body: proto.body,
      type: proto.type,
      isRead: proto.isRead,
      payload: proto.payload,
      timestamp: proto.hasTimestamp() ? DateTime.parse(proto.timestamp) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'payload': payload,
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'payload': payload,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead ? 1 : 0,
      'payload': jsonEncode(payload),
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}