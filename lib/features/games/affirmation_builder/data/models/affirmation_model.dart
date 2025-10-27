// models/affirmation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AffirmationModel {
  final String id;
  final String text;
  final List<String> words;
  final String category;
  final int difficulty;
  final String? hint;

  AffirmationModel({
    required this.id,
    required this.text,
    required this.words,
    required this.category,
    required this.difficulty,
    this.hint,
  });

  // Factory constructor to create an AffirmationModel from a Firestore document
  factory AffirmationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AffirmationModel(
      id: doc.id,
      text: data['text'] ?? '',
      words: List<String>.from(data['words'] ?? []),
      category: data['category'] ?? 'general',
      difficulty: data['difficulty'] ?? 1,
      hint: data['hint'],
    );
  }

  // Convert AffirmationModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'words': words,
      'category': category,
      'difficulty': difficulty,
      'hint': hint,
    };
  }

  // Create a shuffled list of words for the game
  List<String> getShuffledWords() {
    final shuffledWords = List<String>.from(words);
    shuffledWords.shuffle();
    return shuffledWords;
  }
}
