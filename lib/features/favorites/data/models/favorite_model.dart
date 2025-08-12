// Favorite Model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class FavoriteModel {
  final String id;
  final String userId;
  final String tipId;
  final DateTime? createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.tipId,
    this.createdAt,
  });

  factory FavoriteModel.fromFirestore(Map<String, dynamic> data, String id) {
    return FavoriteModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      tipId: data['tipId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      tipId: json['tipId'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
    );
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      tipId: map['tipId'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in FavoriteModel: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  List<int> toProto() {
    final proto = pb.FavoriteModel()
      ..id = id
      ..userId = userId
      ..tipId = tipId
      ..createdAt = createdAt?.toIso8601String() ?? '';
    return proto.writeToBuffer();
  }

  factory FavoriteModel.fromProto(List<int> bytes) {
    final proto = pb.FavoriteModel.fromBuffer(bytes);
    return FavoriteModel(
      id: proto.id,
      userId: proto.userId,
      tipId: proto.tipId,
      createdAt: proto.hasCreatedAt() ? DateTime.parse(proto.createdAt) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tipId': tipId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tipId': tipId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'tipId': tipId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
