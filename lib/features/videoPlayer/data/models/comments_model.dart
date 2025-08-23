// Comment Model
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class CommentModel {
  final String id;
  final String tipsId; // Changed from tipId to tipsId
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final DateTime createdAt;
  final String? parentId; // For replies (null if it's a top-level comment)
  final int likeCount;

  CommentModel({
    required this.id,
    required this.tipsId, // Changed from tipId to tipsId
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.likeCount = 0,
  });

  factory CommentModel.fromFirestore(Map<String, dynamic> data, String id) {
    try {
      return CommentModel(
        id: id,
        tipsId: data['tipsId'] ?? '',
        // Changed from tipId to tipsId
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? 'Anonymous',
        userPhotoUrl: data['userPhotoUrl'] ?? '',
        text: data['text'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        parentId: data['parentId'],
        likeCount: data['likeCount'] ?? 0,
      );
    } catch (e, stackTrace) {
      print('Error parsing CommentModel for id $id: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipsId': tipsId, // Changed from tipId to tipsId
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentId': parentId,
      'likeCount': likeCount,
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String? ?? '',
      tipsId: json['tipsId'] as String? ?? '',
      // Changed from tipId to tipsId
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Anonymous',
      userPhotoUrl: json['userPhotoUrl'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      parentId: json['parentId'] as String?,
      likeCount: json['likeCount'] as int? ?? 0,
    );
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] as String? ?? '',
      tipsId: map['tipsId'] as String? ?? '',
      // Changed from tipId to tipsId
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Anonymous',
      userPhotoUrl: map['userPhotoUrl'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      parentId: map['parentId'] as String?,
      likeCount: map['likeCount'] as int? ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string in CommentModel: $value, error: $e');
        return null;
      }
    }
    return null;
  }

  List<int> toProto() {
    final proto = pb.CommentModel()
      ..id = id
      ..tipsId =
          tipsId // Changed from tipId to tipsId
      ..userId = userId
      ..userName = userName
      ..userPhotoUrl = userPhotoUrl
      ..text = text
      ..createdAt = createdAt.toIso8601String();

    if (parentId != null) {
      proto.parentId = parentId!;
    }

    proto.likeCount = likeCount;

    return proto.writeToBuffer();
  }

  factory CommentModel.fromProto(List<int> bytes) {
    final proto = pb.CommentModel.fromBuffer(bytes);
    return CommentModel(
      id: proto.id,
      tipsId: proto.tipsId,
      // Changed from tipId to tipsId
      userId: proto.userId,
      userName: proto.userName,
      userPhotoUrl: proto.userPhotoUrl,
      text: proto.text,
      createdAt: DateTime.parse(proto.createdAt),
      parentId: proto.hasParentId() ? proto.parentId : null,
      likeCount: proto.likeCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipsId': tipsId, // Changed from tipId to tipsId
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
      'likeCount': likeCount,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipsId': tipsId, // Changed from tipId to tipsId
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
      'likeCount': likeCount,
    };
  }

  // Helper to create a new comment
  factory CommentModel.create({
    required String tipsId, // Changed from tipId to tipsId
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String text,
    String? parentId,
  }) {
    return CommentModel(
      id: '',
      // Will be set when saved to Firestore
      tipsId: tipsId,
      // Changed from tipId to tipsId
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      text: text,
      createdAt: DateTime.now(),
      parentId: parentId,
      likeCount: 0,
    );
  }

  // Helper to create a reply to a specific comment
  factory CommentModel.createReply({
    required String tipsId, // Changed from tipId to tipsId
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String text,
    required String parentCommentId,
  }) {
    return CommentModel(
      id: '',
      // Will be set when saved to Firestore
      tipsId: tipsId,
      // Changed from tipId to tipsId
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      text: text,
      createdAt: DateTime.now(),
      parentId: parentCommentId,
      likeCount: 0,
    );
  }

  // Helper to get a copy with updated fields
  CommentModel copyWith({
    String? id,
    String? tipsId, // Changed from tipId to tipsId
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? text,
    DateTime? createdAt,
    String? parentId,
    int? likeCount,
  }) {
    return CommentModel(
      id: id ?? this.id,
      tipsId: tipsId ?? this.tipsId,
      // Changed from tipId to tipsId
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
      likeCount: likeCount ?? this.likeCount,
    );
  }

  // Helper to check if this comment is a reply
  bool get isReply => parentId != null;

  // Format the timestamp as a readable string
  String getFormattedTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
