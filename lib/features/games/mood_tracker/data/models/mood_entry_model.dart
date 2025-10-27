// models/mood_entry_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntryModel {
  final String id;
  final String userId;
  final String mood; // Emoji representation
  final String? note;
  final DateTime timestamp;

  MoodEntryModel({
    required this.id,
    required this.userId,
    required this.mood,
    this.note,
    required this.timestamp,
  });

  factory MoodEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      mood: data['mood'] ?? '',
      note: data['note'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mood': mood,
      'note': note,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
