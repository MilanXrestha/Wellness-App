// Like Model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class LikeModel {
  final String id; // Usually userId_tipsId format
  final String tipsId; // Changed from tipId to tipsId
  final String userId;
  final DateTime createdAt;

  LikeModel({
    required this.id,
    required this.tipsId, // Changed from tipId to tipsId
    required this.userId,
    required this.createdAt,
  });

  factory LikeModel.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      return LikeModel(
        id: id,
        tipsId: data['tipsId'] ?? '', // Changed from tipId to tipsId
        userId: data['userId'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    } catch (e, stackTrace) {
      print('Error parsing LikeModel for id $id: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipsId': tipsId, // Changed from tipId to tipsId
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'] as String? ?? '',
      tipsId: json['tipsId'] as String? ?? '', // Changed from tipId to tipsId
      userId: json['userId'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  factory LikeModel.fromMap(Map<String, dynamic> map) {
    return LikeModel(
      id: map['id'] as String? ?? '',
      tipsId: map['tipsId'] as String? ?? '', // Changed from tipId to tipsId
      userId: map['userId'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in LikeModel: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  List<int> toProto() {
    final proto = pb.LikeModel()
      ..id = id
      ..tipsId =
          tipsId // Changed from tipId to tipsId
      ..userId = userId
      ..createdAt = createdAt.toIso8601String();

    return proto.writeToBuffer();
  }

  factory LikeModel.fromProto(List<int> bytes) {
    final proto = pb.LikeModel.fromBuffer(bytes);
    return LikeModel(
      id: proto.id,
      tipsId: proto.tipsId, // Changed from tipId to tipsId
      userId: proto.userId,
      createdAt: DateTime.parse(proto.createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipsId': tipsId, // Changed from tipId to tipsId
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipsId': tipsId, // Changed from tipId to tipsId
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper to create a like with the standard format userId_tipsId
  factory LikeModel.create(String userId, String tipsId) {
    // Changed parameter name
    return LikeModel(
      id: '${userId}_${tipsId}',
      tipsId: tipsId, // Changed from tipId to tipsId
      userId: userId,
      createdAt: DateTime.now(),
    );
  }

  // Helper to check if a like matches a specific user and tip
  bool matches(String userId, String tipsId) {
    // Changed parameter name
    return this.userId == userId &&
        this.tipsId == tipsId; // Changed from tipId to tipsId
  }
}
