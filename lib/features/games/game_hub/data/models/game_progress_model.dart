// models/game_progress_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GameProgressModel {
  final String id;
  final String userId;
  final String gameId;
  final int highScore;
  final int totalPlays;
  final int totalPoints;
  final int longestStreak;
  final int currentStreak;
  final DateTime lastPlayed;
  final Map<String, dynamic> gameSpecificData;

  GameProgressModel({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.highScore,
    required this.totalPlays,
    required this.totalPoints,
    required this.longestStreak,
    required this.currentStreak,
    required this.lastPlayed,
    required this.gameSpecificData,
  });

  // Factory constructor to create a GameProgressModel from a Firestore document
  factory GameProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameProgressModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      gameId: data['gameId'] ?? '',
      highScore: data['highScore'] ?? 0,
      totalPlays: data['totalPlays'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      lastPlayed: (data['lastPlayed'] as Timestamp).toDate(),
      gameSpecificData: data['gameSpecificData'] ?? {},
    );
  }

  // Convert GameProgressModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'gameId': gameId,
      'highScore': highScore,
      'totalPlays': totalPlays,
      'totalPoints': totalPoints,
      'longestStreak': longestStreak,
      'currentStreak': currentStreak,
      'lastPlayed': Timestamp.fromDate(lastPlayed),
      'gameSpecificData': gameSpecificData,
    };
  }

  // Create a copy of this GameProgressModel with updated values
  GameProgressModel copyWith({
    String? id,
    String? userId,
    String? gameId,
    int? highScore,
    int? totalPlays,
    int? totalPoints,
    int? longestStreak,
    int? currentStreak,
    DateTime? lastPlayed,
    Map<String, dynamic>? gameSpecificData,
  }) {
    return GameProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameId: gameId ?? this.gameId,
      highScore: highScore ?? this.highScore,
      totalPlays: totalPlays ?? this.totalPlays,
      totalPoints: totalPoints ?? this.totalPoints,
      longestStreak: longestStreak ?? this.longestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      gameSpecificData: gameSpecificData ?? this.gameSpecificData,
    );
  }
}
