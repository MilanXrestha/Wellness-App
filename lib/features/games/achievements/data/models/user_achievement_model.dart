// models/user_achievement_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAchievementModel {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final bool isNew; // To show a notification/badge for new achievements

  UserAchievementModel({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.isNew = true,
  });

  // Factory constructor to create a UserAchievementModel from a Firestore document
  factory UserAchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserAchievementModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      achievementId: data['achievementId'] ?? '',
      unlockedAt: (data['unlockedAt'] as Timestamp).toDate(),
      isNew: data['isNew'] ?? true,
    );
  }

  // Convert UserAchievementModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'isNew': isNew,
    };
  }

  // Create a copy of this UserAchievementModel with updated values
  UserAchievementModel copyWith({
    String? id,
    String? userId,
    String? achievementId,
    DateTime? unlockedAt,
    bool? isNew,
  }) {
    return UserAchievementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isNew: isNew ?? this.isNew,
    );
  }
}
