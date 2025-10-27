// models/game_session_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GameSessionModel {
  final String id;
  final String userId;
  final String gameId;
  final int score;
  final int streak;
  final Duration duration;
  final DateTime playedAt;
  final Map<String, dynamic> sessionData;

  GameSessionModel({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.score,
    required this.streak,
    required this.duration,
    required this.playedAt,
    required this.sessionData,
  });

  // Factory constructor to create a GameSessionModel from a Firestore document
  factory GameSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameSessionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      gameId: data['gameId'] ?? '',
      score: data['score'] ?? 0,
      streak: data['streak'] ?? 0,
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
      playedAt: (data['playedAt'] as Timestamp).toDate(),
      sessionData: data['sessionData'] ?? {},
    );
  }

  // Convert GameSessionModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'gameId': gameId,
      'score': score,
      'streak': streak,
      'durationSeconds': duration.inSeconds,
      'playedAt': Timestamp.fromDate(playedAt),
      'sessionData': sessionData,
    };
  }
}
