// models/quiz_question_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizQuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;
  final String category;
  final int difficulty; // 1 = Easy, 2 = Medium, 3 = Hard

  QuizQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
    required this.category,
    required this.difficulty,
  });

  factory QuizQuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizQuestionModel(
      id: doc.id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctOptionIndex: data['correctOptionIndex'] ?? 0,
      explanation: data['explanation'],
      category: data['category'] ?? 'general',
      difficulty: data['difficulty'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'category': category,
      'difficulty': difficulty,
    };
  }
}
