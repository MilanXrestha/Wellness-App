// services/game_service.dart
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';
import '../models/game_progress_model.dart';
import '../models/game_session_model.dart';
import '../../../achievements/data/models/achievement_model.dart';
import '../../../mood_tracker/data/models/mood_entry_model.dart';
import '../../../achievements/data/models/user_achievement_model.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all available games
  Future<List<GameModel>> getGames() async {
    try {
      final snapshot = await _firestore
          .collection('games')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs.map((doc) => GameModel.fromFirestore(doc)).toList();
    } catch (e) {
      log('Error getting games: $e', name: 'GameService');
      return [];
    }
  }

  // Get a specific game by ID
  Future<GameModel?> getGame(String gameId) async {
    try {
      final doc = await _firestore.collection('games').doc(gameId).get();

      if (!doc.exists) return null;

      return GameModel.fromFirestore(doc);
    } catch (e) {
      log('Error getting game $gameId: $e', name: 'GameService');
      return null;
    }
  }

  // Save a game session and update user progress
  Future<void> saveGameSession({
    required String userId,
    required String gameId,
    required int score,
    required int streak,
    required Duration duration,
    Map<String, dynamic> sessionData = const {},
  }) async {
    try {
      // Create a new game session document
      final sessionRef = _firestore.collection('game_sessions').doc();

      // Create the game session model
      final gameSession = GameSessionModel(
        id: sessionRef.id,
        userId: userId,
        gameId: gameId,
        score: score,
        streak: streak,
        duration: duration,
        playedAt: DateTime.now(),
        sessionData: sessionData,
      );

      // Save the session to Firestore
      await sessionRef.set(gameSession.toFirestore());

      // Update user progress
      await _updateUserProgress(userId, gameId, score, streak);

      // Check for achievements
      await _checkAchievements(userId, gameId, score, streak, duration);

      log(
        'Game session saved for user $userId, game $gameId',
        name: 'GameService',
      );
    } catch (e) {
      log('Error saving game session: $e', name: 'GameService');
      throw Exception('Failed to save game session: $e');
    }
  }

  // Update user progress for a game
  Future<void> _updateUserProgress(
    String userId,
    String gameId,
    int score,
    int streak,
  ) async {
    try {
      // Get current progress
      final progressQuery = await _firestore
          .collection('game_progress')
          .where('userId', isEqualTo: userId)
          .where('gameId', isEqualTo: gameId)
          .limit(1)
          .get();

      final batch = _firestore.batch();

      if (progressQuery.docs.isEmpty) {
        // No progress record yet, create a new one
        final progressRef = _firestore.collection('game_progress').doc();

        final progress = GameProgressModel(
          id: progressRef.id,
          userId: userId,
          gameId: gameId,
          highScore: score,
          totalPlays: 1,
          totalPoints: score,
          longestStreak: streak,
          currentStreak: streak,
          lastPlayed: DateTime.now(),
          gameSpecificData: {},
        );

        batch.set(progressRef, progress.toFirestore());
      } else {
        // Update existing progress
        final progressDoc = progressQuery.docs.first;
        final progress = GameProgressModel.fromFirestore(progressDoc);

        final updatedProgress = progress.copyWith(
          highScore: progress.highScore < score ? score : progress.highScore,
          totalPlays: progress.totalPlays + 1,
          totalPoints: progress.totalPoints + score,
          longestStreak: progress.longestStreak < streak
              ? streak
              : progress.longestStreak,
          currentStreak: streak,
          lastPlayed: DateTime.now(),
        );

        batch.update(progressDoc.reference, updatedProgress.toFirestore());
      }

      // Update user's wellness points in the users collection
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {'wellnessPoints': FieldValue.increment(score)});

      await batch.commit();

      log(
        'User progress updated for $userId, game $gameId',
        name: 'GameService',
      );
    } catch (e) {
      log('Error updating user progress: $e', name: 'GameService');
      throw Exception('Failed to update user progress: $e');
    }
  }

  // Check for achievements unlocked by this game session
  Future<void> _checkAchievements(
    String userId,
    String gameId,
    int score,
    int streak,
    Duration duration,
  ) async {
    try {
      // Get all achievements for this game
      final achievementsSnapshot = await _firestore
          .collection('achievements')
          .where('gameId', isEqualTo: gameId)
          .get();

      // Get user's existing achievements
      final userAchievementsSnapshot = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: userId)
          .get();

      final existingAchievementIds = userAchievementsSnapshot.docs
          .map(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['achievementId'] as String,
          )
          .toSet();

      // Get user's progress for this game
      final progressQuery = await _firestore
          .collection('game_progress')
          .where('userId', isEqualTo: userId)
          .where('gameId', isEqualTo: gameId)
          .limit(1)
          .get();

      if (progressQuery.docs.isEmpty) return;

      final progress = GameProgressModel.fromFirestore(
        progressQuery.docs.first,
      );

      // Check each achievement criteria
      final batch = _firestore.batch();
      bool hasNewAchievements = false;

      for (final doc in achievementsSnapshot.docs) {
        final achievement = AchievementModel.fromFirestore(doc);

        // Skip if already unlocked
        if (existingAchievementIds.contains(achievement.id)) continue;

        // Check if criteria is met
        bool criteriaFulfilled = _checkAchievementCriteria(
          achievement.criteria,
          progress,
          score,
          streak,
          duration,
        );

        if (criteriaFulfilled) {
          // Unlock the achievement
          final achievementRef = _firestore
              .collection('user_achievements')
              .doc();

          final userAchievement = UserAchievementModel(
            id: achievementRef.id,
            userId: userId,
            achievementId: achievement.id,
            unlockedAt: DateTime.now(),
            isNew: true,
          );

          batch.set(achievementRef, userAchievement.toFirestore());

          // Add achievement points to user's wellness points
          final userRef = _firestore.collection('users').doc(userId);
          batch.update(userRef, {
            'wellnessPoints': FieldValue.increment(achievement.pointsAwarded),
          });

          hasNewAchievements = true;
        }
      }

      if (hasNewAchievements) {
        await batch.commit();
        log(
          'New achievements unlocked for $userId in $gameId',
          name: 'GameService',
        );
      }
    } catch (e) {
      log('Error checking achievements: $e', name: 'GameService');
      // Don't throw, just log the error to avoid interrupting the game flow
    }
  }

  // Helper method to check if achievement criteria is met
  bool _checkAchievementCriteria(
    Map<String, dynamic> criteria,
    GameProgressModel progress,
    int currentScore,
    int currentStreak,
    Duration currentDuration,
  ) {
    // Check each criterion
    for (final entry in criteria.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'minScore':
          if (currentScore < value) return false;
          break;
        case 'minHighScore':
          if (progress.highScore < value) return false;
          break;
        case 'minStreak':
          if (currentStreak < value) return false;
          break;
        case 'minLongestStreak':
          if (progress.longestStreak < value) return false;
          break;
        case 'minTotalPlays':
          if (progress.totalPlays < value) return false;
          break;
        case 'minTotalPoints':
          if (progress.totalPoints < value) return false;
          break;
        case 'minDurationSeconds':
          if (currentDuration.inSeconds < value) return false;
          break;
        // Add more criteria as needed
      }
    }

    // All criteria passed
    return true;
  }

  // Get user's achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      // Get the user's unlocked achievements
      final userAchievementsSnapshot = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: userId)
          .orderBy('unlockedAt', descending: true)
          .get();

      if (userAchievementsSnapshot.docs.isEmpty) return [];

      // Get all achievement details
      final achievementsSnapshot = await _firestore
          .collection('achievements')
          .get();

      // Create a map of achievement IDs to details
      final achievementsMap = {
        for (final doc in achievementsSnapshot.docs)
          doc.id: AchievementModel.fromFirestore(doc),
      };

      // Combine user achievements with achievement details
      final result = userAchievementsSnapshot.docs
          .map((doc) {
            final userAchievement = UserAchievementModel.fromFirestore(doc);
            final achievement = achievementsMap[userAchievement.achievementId];

            if (achievement == null) return null;

            return {
              'id': userAchievement.id,
              'achievementId': userAchievement.achievementId,
              'title': achievement.title,
              'description': achievement.description,
              'iconPath': achievement.iconPath,
              'gameId': achievement.gameId,
              'pointsAwarded': achievement.pointsAwarded,
              'unlockedAt': userAchievement.unlockedAt.toIso8601String(),
              'isNew': userAchievement.isNew,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      return result;
    } catch (e) {
      log('Error getting user achievements: $e', name: 'GameService');
      return [];
    }
  }

  // Mark user achievements as seen (not new)
  Future<void> markAchievementsSeen(String userId) async {
    try {
      final userAchievementsSnapshot = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: userId)
          .where('isNew', isEqualTo: true)
          .get();

      if (userAchievementsSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (final doc in userAchievementsSnapshot.docs) {
        batch.update(doc.reference, {'isNew': false});
      }

      await batch.commit();

      log(
        'Marked ${userAchievementsSnapshot.docs.length} achievements as seen for $userId',
        name: 'GameService',
      );
    } catch (e) {
      log('Error marking achievements as seen: $e', name: 'GameService');
    }
  }

  // Get leaderboard for a game
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String gameId, {
    int limit = 10,
  }) async {
    try {
      // Get top scores for this game
      final progressSnapshot = await _firestore
          .collection('game_progress')
          .where('gameId', isEqualTo: gameId)
          .orderBy('highScore', descending: true)
          .limit(limit)
          .get();

      if (progressSnapshot.docs.isEmpty) return [];

      // Get user details for these scores
      final userIds = progressSnapshot.docs
          .map(
            (doc) => (doc.data() as Map<String, dynamic>)['userId'] as String,
          )
          .toList();

      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      // Create a map of user IDs to user details
      final usersMap = {
        for (final doc in usersSnapshot.docs)
          doc.id: doc.data() as Map<String, dynamic>,
      };

      // Combine game progress with user details
      final result = progressSnapshot.docs.map((doc) {
        final progress = GameProgressModel.fromFirestore(doc);
        final user = usersMap[progress.userId] ?? {};

        return {
          'userId': progress.userId,
          'userName': user['userName'] ?? 'Unknown User',
          'photoURL': user['photoURL'],
          'highScore': progress.highScore,
          'totalPlays': progress.totalPlays,
          'longestStreak': progress.longestStreak,
        };
      }).toList();

      return result;
    } catch (e) {
      log('Error getting leaderboard: $e', name: 'GameService');
      return [];
    }
  }

  // Get user's game progress
  Future<List<GameProgressModel>> getUserProgress(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('game_progress')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => GameProgressModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting user progress: $e', name: 'GameService');
      return [];
    }
  }

  // Get user's game progress for a specific game
  Future<GameProgressModel?> getUserGameProgress(
    String userId,
    String gameId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('game_progress')
          .where('userId', isEqualTo: userId)
          .where('gameId', isEqualTo: gameId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return GameProgressModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      log('Error getting user game progress: $e', name: 'GameService');
      return null;
    }
  }

  // Initialize default games in Firestore (admin function)
  Future<void> initializeDefaultGames() async {
    try {
      // Check if games already exist
      final existingGames = await _firestore.collection('games').limit(1).get();
      if (existingGames.docs.isNotEmpty) {
        log('Games already initialized, skipping', name: 'GameService');
        return;
      }

      // Create breathing game
      final breathingGame = GameModel(
        id: 'breathing_game',
        title: 'Mindful Breathing',
        description:
            'Sync your breath with the animation to earn points and find calm',
        animationPath: 'assets/animations/meditation.json',
        type: 'breathing',
        config: {
          'inhaleDuration': 4,
          'holdDuration': 2,
          'exhaleDuration': 4,
          'defaultSessionLength': 60, // seconds
        },
        sortOrder: 1,
        createdAt: DateTime.now(),
      );

      // Create Affirmation Builder game
      final affirmationGame = GameModel(
        id: 'affirmation_builder',
        title: 'Affirmation Builder',
        description: 'Drag and drop words to form positive affirmations',
        animationPath: 'assets/animations/abc_blocks.json',
        type: 'word_puzzle',
        // new type for your game logic
        config: {
          'wordsPerPuzzle': 5, // number of words in each affirmation
          'maxAttempts': 3, // optional: max tries per puzzle
          'defaultSessionLength': 120, // seconds, optional
        },
        sortOrder: 2,
        createdAt: DateTime.now(),
      );

      // Create quiz game
      final quizGame = GameModel(
        id: 'wellness_quiz',
        title: 'Wellness Trivia',
        description: 'Test your knowledge and learn new wellness facts',
        animationPath: 'assets/animations/quiz.json',
        type: 'quiz',
        config: {
          'questionsPerSession': 5,
          'timePerQuestion': 15, // seconds
        },
        sortOrder: 3,
        createdAt: DateTime.now(),
      );

      // Save games to Firestore
      final batch = _firestore.batch();

      batch.set(
        _firestore.collection('games').doc(breathingGame.id),
        breathingGame.toFirestore(),
      );

      batch.set(
        _firestore.collection('games').doc(affirmationGame.id),
        affirmationGame.toFirestore(),
      );

      batch.set(
        _firestore.collection('games').doc(quizGame.id),
        quizGame.toFirestore(),
      );

      // Breathing game achievements
      final breathingAchievements = [
        AchievementModel(
          id: 'first_breath',
          title: 'First Breath',
          description: 'Complete your first breathing session',
          iconPath: 'assets/icons/achievements/first_breath.png',
          gameId: 'breathing_game',
          pointsAwarded: 10,
          criteria: {'minTotalPlays': 1},
        ),
        AchievementModel(
          id: 'breath_master',
          title: 'Breath Master',
          description: 'Achieve a score of 100 in the breathing game',
          iconPath: 'assets/icons/achievements/breath_master.png',
          gameId: 'breathing_game',
          pointsAwarded: 25,
          criteria: {'minScore': 100},
        ),
        AchievementModel(
          id: 'breath_streak',
          title: 'Breath Rhythm',
          description: 'Achieve a streak of 10 in the breathing game',
          iconPath: 'assets/icons/achievements/breath_streak.png',
          gameId: 'breathing_game',
          pointsAwarded: 30,
          criteria: {'minStreak': 10},
        ),
      ];

      // Quiz game achievements
      final quizAchievements = [
        AchievementModel(
          id: 'first_quiz',
          title: 'Wellness Student',
          description: 'Complete your first wellness quiz',
          iconPath: 'assets/icons/achievements/first_quiz.png',
          gameId: 'wellness_quiz',
          pointsAwarded: 10,
          criteria: {'minTotalPlays': 1},
        ),
        AchievementModel(
          id: 'quiz_master',
          title: 'Wellness Scholar',
          description: 'Answer all questions correctly in a quiz',
          iconPath: 'assets/icons/achievements/quiz_master.png',
          gameId: 'wellness_quiz',
          pointsAwarded: 40,
          criteria: {'minScore': 100},
        ),
        // Add these new achievements
        AchievementModel(
          id: 'quiz_streak',
          title: 'Knowledge Streak',
          description: 'Get a streak of 5 correct answers in a row',
          iconPath: 'assets/icons/achievements/quiz_streak.png',
          gameId: 'wellness_quiz',
          pointsAwarded: 25,
          criteria: {'minStreak': 5},
        ),
        AchievementModel(
          id: 'quiz_perfect',
          title: 'Perfect Score',
          description: 'Complete a quiz with 100% accuracy',
          iconPath: 'assets/icons/achievements/quiz_perfect.png',
          gameId: 'wellness_quiz',
          pointsAwarded: 50,
          criteria: {
            'minScore': 200,
          }, // Will only be achieved with perfect scores
        ),
        AchievementModel(
          id: 'quiz_addict',
          title: 'Wellness Expert',
          description: 'Complete 10 quiz sessions',
          iconPath: 'assets/icons/achievements/quiz_addict.png',
          gameId: 'wellness_quiz',
          pointsAwarded: 30,
          criteria: {'minTotalPlays': 10},
        ),
      ];

      // Affirmation game achievements
      final affirmationAchievements = [
        AchievementModel(
          id: 'first_affirmation',
          title: 'Positive Beginner',
          description: 'Complete your first affirmation',
          iconPath: 'assets/icons/achievements/first_affirmation.png',
          gameId: 'affirmation_builder',
          pointsAwarded: 10,
          criteria: {'minTotalPlays': 1},
        ),
        AchievementModel(
          id: 'affirmation_builder',
          title: 'Word Master',
          description: 'Score 100 points in the Affirmation Builder game',
          iconPath: 'assets/icons/achievements/affirmation_master.png',
          gameId: 'affirmation_builder',
          pointsAwarded: 25,
          criteria: {'minScore': 100},
        ),
        AchievementModel(
          id: 'affirmation_streak',
          title: 'Affirmation Flow',
          description: 'Complete 5 affirmations in a row without mistakes',
          iconPath: 'assets/icons/achievements/affirmation_streak.png',
          gameId: 'affirmation_builder',
          pointsAwarded: 30,
          criteria: {'minStreak': 5},
        ),
        AchievementModel(
          id: 'affirmation_addict',
          title: 'Positive Thinker',
          description: 'Complete 20 affirmations total',
          iconPath: 'assets/icons/achievements/affirmation_addict.png',
          gameId: 'affirmation_builder',
          pointsAwarded: 40,
          criteria: {'minTotalPoints': 200},
        ),
      ];

      // Global achievements
      final globalAchievements = [
        AchievementModel(
          id: 'wellness_beginner',
          title: 'Wellness Beginner',
          description: 'Earn 100 wellness points across all games',
          iconPath: 'assets/icons/achievements/wellness_beginner.png',
          gameId: 'global',
          pointsAwarded: 20,
          criteria: {'minTotalPoints': 100},
        ),
        AchievementModel(
          id: 'wellness_enthusiast',
          title: 'Wellness Enthusiast',
          description: 'Play 10 game sessions across all games',
          iconPath: 'assets/icons/achievements/wellness_enthusiast.png',
          gameId: 'global',
          pointsAwarded: 30,
          criteria: {'minTotalPlays': 10},
        ),
      ];

      // Save achievements to Firestore
      final allAchievements = [
        ...breathingAchievements,
        ...quizAchievements,
        ...affirmationAchievements,
        ...globalAchievements,
      ];

      for (final achievement in allAchievements) {
        batch.set(
          _firestore.collection('achievements').doc(achievement.id),
          achievement.toFirestore(),
        );
      }

      await batch.commit();

      log('Default games and achievements initialized', name: 'GameService');
    } catch (e) {
      log('Error initializing default games: $e', name: 'GameService');
      throw Exception('Failed to initialize default games: $e');
    }
  }

  // Save a mood entry
  Future<void> saveMoodEntry({
    required String userId,
    required String mood,
    String? note,
  }) async {
    try {
      final moodRef = _firestore.collection('mood_entries').doc();

      final moodEntry = MoodEntryModel(
        id: moodRef.id,
        userId: userId,
        mood: mood,
        note: note,
        timestamp: DateTime.now(),
      );

      await moodRef.set(moodEntry.toFirestore());

      log('Mood entry saved for user $userId', name: 'GameService');
    } catch (e) {
      log('Error saving mood entry: $e', name: 'GameService');
      throw Exception('Failed to save mood entry: $e');
    }
  }

  // Get user's mood entries
  Future<List<MoodEntryModel>> getUserMoodEntries(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('mood_entries')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MoodEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error getting user mood entries: $e', name: 'GameService');
      return [];
    }
  }

  // Get user's mood statistics
  Future<Map<String, dynamic>> getUserMoodStats(String userId) async {
    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('mood_entries')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo),
          )
          .orderBy('timestamp', descending: true)
          .get();

      final entries = snapshot.docs
          .map((doc) => MoodEntryModel.fromFirestore(doc))
          .toList();

      // Count occurrences of each mood
      final moodCounts = <String, int>{};
      for (final entry in entries) {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }

      // Get most frequent mood
      String? mostFrequentMood;
      int maxCount = 0;
      moodCounts.forEach((mood, count) {
        if (count > maxCount) {
          maxCount = count;
          mostFrequentMood = mood;
        }
      });

      return {
        'entryCount': entries.length,
        'moodCounts': moodCounts,
        'mostFrequentMood': mostFrequentMood,
      };
    } catch (e) {
      log('Error getting user mood stats: $e', name: 'GameService');
      return {
        'entryCount': 0,
        'moodCounts': <String, int>{},
        'mostFrequentMood': null,
      };
    }
  }

  // Get all available achievements
  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    try {
      final snapshot = await _firestore.collection('achievements').get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      log('Error getting all achievements: $e', name: 'GameService');
      return [];
    }
  }

  // Method to get achievements specific to a game
  Future<List<Map<String, dynamic>>> getGameAchievements(String gameId) async {
    try {
      final querySnapshot = await _firestore
          .collection('achievements')
          .where('gameId', isEqualTo: gameId)
          .get();

      return querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      log('Error getting game achievements: $e', name: 'GameService');
      return [];
    }
  }

  // Method to unlock an achievement
  Future<void> unlockAchievement({
    required String userId,
    required String achievementId,
  }) async {
    try {
      // Check if already unlocked
      final existingDocs = await _firestore
          .collection('user_achievements')
          .where('userId', isEqualTo: userId)
          .where('achievementId', isEqualTo: achievementId)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        // Already unlocked, just mark as new
        final docRef = existingDocs.docs.first.reference;
        await docRef.update({'isNew': true});
        return;
      }

      // Get achievement details
      final achievementDoc = await _firestore
          .collection('achievements')
          .doc(achievementId)
          .get();

      if (!achievementDoc.exists) {
        log('Achievement $achievementId not found', name: 'GameService');
        return;
      }

      final achievementData = achievementDoc.data()!;

      // Create user achievement document
      final userAchievementRef = _firestore
          .collection('user_achievements')
          .doc();

      await userAchievementRef.set({
        'userId': userId,
        'achievementId': achievementId,
        'unlockedAt': FieldValue.serverTimestamp(),
        'isNew': true,
      });

      // Update user's wellness points
      final pointsAwarded = achievementData['pointsAwarded'] as int? ?? 0;

      if (pointsAwarded > 0) {
        await _firestore.collection('users').doc(userId).update({
          'wellnessPoints': FieldValue.increment(pointsAwarded),
        });
      }

      log(
        'Achievement $achievementId unlocked for user $userId',
        name: 'GameService',
      );
    } catch (e) {
      log('Error unlocking achievement: $e', name: 'GameService');
    }
  }
}
