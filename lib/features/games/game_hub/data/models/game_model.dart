// models/game_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GameModel {
  final String id;
  final String title;
  final String description;
  final String animationPath;
  final String type; // 'breathing', 'tap', 'quiz', etc.
  final Map<String, dynamic> config; // Game-specific configuration
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.animationPath,
    required this.type,
    required this.config,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create a GameModel from a Firestore document
  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      animationPath: data['animationPath'] ?? '',
      type: data['type'] ?? '',
      config: data['config'] ?? {},
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert GameModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'animationPath': animationPath,
      'type': type,
      'config': config,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
