// models/achievement_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final String gameId; // Can be 'global' for app-wide achievements
  final int pointsAwarded;
  final Map<String, dynamic> criteria; // Criteria to unlock this achievement

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.gameId,
    required this.pointsAwarded,
    required this.criteria,
  });

  // Factory constructor to create an AchievementModel from a Firestore document
  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AchievementModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      iconPath: data['iconPath'] ?? '',
      gameId: data['gameId'] ?? '',
      pointsAwarded: data['pointsAwarded'] ?? 0,
      criteria: data['criteria'] ?? {},
    );
  }

  // Convert AchievementModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'gameId': gameId,
      'pointsAwarded': pointsAwarded,
      'criteria': criteria,
    };
  }
}
