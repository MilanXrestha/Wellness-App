// User Model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:protobuf/protobuf.dart';
import 'package:wellness_app/generated/protos/wellness_data.pb.dart' as pb;

class UserModel {
  final String userId;
  final String userEmail;
  final String userName;
  final String userRole;
  final bool preferenceCompleted;
  final DateTime createdAt;
  final String? photoURL;
  final String? fcmToken;

  UserModel({
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userRole,
    required this.preferenceCompleted,
    required this.createdAt,
    this.photoURL,
    this.fcmToken,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> map, [String? id]) {
    final createdAtField = map['createdAt'];
    final createdAtParsed = createdAtField is Timestamp
        ? createdAtField.toDate()
        : DateTime.parse(createdAtField.toString());

    return UserModel(
      userId: id ?? map['userId'] as String,
      userEmail: map['userEmail'] as String,
      userName: map['userName'] as String,
      userRole: map['userRole'] as String,
      preferenceCompleted: map['preferenceCompleted'] as bool,
      createdAt: createdAtParsed,
      photoURL: map['photoURL'] as String?,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final createdAtField = json['createdAt'];
    final createdAtParsed = createdAtField is Timestamp
        ? createdAtField.toDate()
        : DateTime.parse(createdAtField.toString());

    return UserModel(
      userId: json['userId'] as String,
      userEmail: json['userEmail'] as String,
      userName: json['userName'] as String,
      userRole: json['userRole'] as String,
      preferenceCompleted: json['preferenceCompleted'] as bool,
      createdAt: createdAtParsed,
      photoURL: json['photoURL'] as String?,
      fcmToken: json['fcmToken'] as String?,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final createdAtField = map['createdAt'];
    final createdAtParsed = createdAtField is Timestamp
        ? createdAtField.toDate()
        : DateTime.parse(createdAtField.toString());

    return UserModel(
      userId: map['userId'] as String,
      userEmail: map['userEmail'] as String,
      userName: map['userName'] as String,
      userRole: map['userRole'] as String,
      preferenceCompleted: (map['preferenceCompleted'] is bool)
          ? map['preferenceCompleted'] as bool
          : (map['preferenceCompleted'] as int) == 1,
      createdAt: createdAtParsed,
      photoURL: map['photoURL'] as String?,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  List<int> toProto() {
    final proto = pb.UserModel()
      ..userId = userId
      ..userEmail = userEmail
      ..userName = userName
      ..userRole = userRole
      ..preferenceCompleted = preferenceCompleted
      ..createdAt = createdAt.toIso8601String()
      ..photoURL = photoURL ?? ''
      ..fcmToken = fcmToken ?? '';
    return proto.writeToBuffer();
  }

  factory UserModel.fromProto(List<int> bytes) {
    final proto = pb.UserModel.fromBuffer(bytes);
    return UserModel(
      userId: proto.userId,
      userEmail: proto.userEmail,
      userName: proto.userName,
      userRole: proto.userRole,
      preferenceCompleted: proto.preferenceCompleted,
      createdAt: DateTime.parse(proto.createdAt),
      photoURL: proto.hasPhotoURL() ? proto.photoURL : null,
      fcmToken: proto.hasFcmToken() ? proto.fcmToken : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userRole': userRole,
      'preferenceCompleted': preferenceCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoURL': photoURL,
      'fcmToken': fcmToken,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userRole': userRole,
      'preferenceCompleted': preferenceCompleted,
      'createdAt': createdAt.toIso8601String(),
      'photoURL': photoURL,
      'fcmToken': fcmToken,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userRole': userRole,
      'preferenceCompleted': preferenceCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'photoURL': photoURL,
      'fcmToken': fcmToken,
    };
  }
}
