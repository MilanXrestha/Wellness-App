// screens/wellness_quiz_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/resources/colors.dart';
import '../../../game_hub/data/services/game_service.dart';
import '../../data/models/quiz_question_model.dart';

class WellnessQuizScreen extends StatefulWidget {
  final String userId;
  final String gameId;
  final Map<String, dynamic> gameConfig;

  const WellnessQuizScreen({
    Key? key,
    required this.userId,
    required this.gameId,
    required this.gameConfig,
  }) : super(key: key);

  @override
  _WellnessQuizScreenState createState() => _WellnessQuizScreenState();
}

class _WellnessQuizScreenState extends State<WellnessQuizScreen>
    with TickerProviderStateMixin {
  final GameService _gameService = GameService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Game state
  List<QuizQuestionModel> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _highestStreak = 0;
  int _correctAnswers = 0;
  bool _isLoading = true;
  bool _isQuizActive = false;
  bool _showInstructions = true;
  bool _answeringEnabled = false;
  int? _selectedAnswerIndex;
  bool _showExplanation = false;
  DateTime? _quizStartTime;

  // Timer
  late Timer _questionTimer;
  int _timeLeft = 0;
  int _defaultTimePerQuestion = 15; // Default, will be overridden by gameConfig

  // Animation controllers
  late AnimationController _timerAnimationController;
  late Animation<double> _timerAnimation;
  late AnimationController _cardAnimationController;

  // Audio players
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _soundEffectPlayer = AudioPlayer();
  bool _isMusicMuted = false;
  bool _isSoundEffectsMuted = false;
  bool _isAudioInitialized = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    // Parse game configuration
    _defaultTimePerQuestion = widget.gameConfig['timePerQuestion'] ?? 15;

    // Setup animations
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _defaultTimePerQuestion),
    );

    _timerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _timerAnimationController, curve: Curves.linear),
    );

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Initialize audio
    _initializeAudio();

    // Load questions
    _loadQuestions();

    // Initialize question timer to avoid null error
    _questionTimer = Timer(Duration.zero, () {});
  }

  @override
  void deactivate() {
    // Ensure audio is paused when navigating away
    if (!_disposed) {
      _backgroundMusicPlayer.pause();
      _soundEffectPlayer.pause();
    }
    super.deactivate();
  }

  Future<void> _initializeAudio() async {
    try {
      // Set release mode for background music to loop
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.setVolume(0.2);

      // Load and play background music
      await _backgroundMusicPlayer.play(
        AssetSource('audio/quiz_background.mp3'),
      );

      _isAudioInitialized = true;
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  Future<void> _playSound(String soundFile, {double volume = 1.0}) async {
    if (_isSoundEffectsMuted || !_isAudioInitialized || _disposed) return;

    try {
      await _soundEffectPlayer.setVolume(volume);
      await _soundEffectPlayer.play(AssetSource(soundFile));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _toggleBackgroundMusic() {
    setState(() {
      _isMusicMuted = !_isMusicMuted;
    });

    if (_isMusicMuted) {
      _backgroundMusicPlayer.pause();
    } else {
      _backgroundMusicPlayer.resume();
    }
  }

  void _toggleSoundEffects() {
    setState(() {
      _isSoundEffectsMuted = !_isSoundEffectsMuted;
    });
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get quiz questions from Firestore
      final snapshot = await _firestore.collection('quiz_questions').get();

      if (snapshot.docs.isEmpty) {
        // If no questions exist, let's create some default ones
        await _createDefaultQuestions();

        // Try to get questions again
        final newSnapshot = await _firestore.collection('quiz_questions').get();
        _questions = newSnapshot.docs
            .map((doc) => QuizQuestionModel.fromFirestore(doc))
            .toList();
      } else {
        _questions = snapshot.docs
            .map((doc) => QuizQuestionModel.fromFirestore(doc))
            .toList();
      }

      // Shuffle questions
      _questions.shuffle(Random());

      // Limit to the number specified in game config
      final questionsPerSession =
          widget.gameConfig['questionsPerSession'] as int? ?? 5;
      if (_questions.length > questionsPerSession) {
        _questions = _questions.sublist(0, questionsPerSession);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _isLoading = false;
        _questions = []; // Empty list will show error state
      });
    }
  }

  Future<void> _createDefaultQuestions() async {
    final batch = _firestore.batch();

    final defaultQuestions = [
      {
        'question': 'What is mindfulness?',
        'options': [
          'Being busy with many tasks',
          'Focusing on the past',
          'Paying attention to the present moment',
          'Planning for the future',
        ],
        'correctOptionIndex': 2,
        'explanation':
        'Mindfulness is the practice of purposely focusing your attention on the present moment—and accepting it without judgment.',
        'category': 'mindfulness',
        'difficulty': 1,
      },
      {
        'question': 'Which of these is NOT a benefit of regular exercise?',
        'options': [
          'Reduced stress levels',
          'Improved mood',
          'Decreased metabolic rate',
          'Better sleep quality',
        ],
        'correctOptionIndex': 2,
        'explanation':
        'Regular exercise actually increases your metabolic rate, helping you burn more calories throughout the day.',
        'category': 'physical',
        'difficulty': 1,
      },
      {
        'question': 'How much water should the average adult drink daily?',
        'options': [
          '1-2 liters',
          '2-3 liters',
          '3-4 liters',
          'It varies based on individual needs',
        ],
        'correctOptionIndex': 3,
        'explanation':
        'While 2-3 liters is often recommended, water needs vary based on activity level, climate, health conditions, and other factors.',
        'category': 'nutrition',
        'difficulty': 2,
      },
      {
        'question': 'What is the recommended amount of sleep for adults?',
        'options': ['4-5 hours', '6-7 hours', '7-9 hours', '10-12 hours'],
        'correctOptionIndex': 2,
        'explanation':
        'Most adults need 7-9 hours of sleep per night for optimal health and well-being.',
        'category': 'sleep',
        'difficulty': 1,
      },
      {
        'question': 'Which of these is a symptom of burnout?',
        'options': [
          'Increased energy',
          'Emotional exhaustion',
          'Improved concentration',
          'Higher productivity',
        ],
        'correctOptionIndex': 1,
        'explanation':
        'Burnout is characterized by emotional exhaustion, cynicism, and reduced professional efficacy.',
        'category': 'mental',
        'difficulty': 2,
      },
      {
        'question': 'What is the "5-4-3-2-1" technique used for?',
        'options': [
          'Weight training',
          'Time management',
          'Grounding during anxiety',
          'Dietary planning',
        ],
        'correctOptionIndex': 2,
        'explanation':
        'The 5-4-3-2-1 technique helps ground people during anxiety by identifying 5 things you see, 4 things you feel, 3 things you hear, 2 things you smell, and 1 thing you taste.',
        'category': 'mental',
        'difficulty': 2,
      },
      {
        'question':
        'Which vitamin is primarily produced when skin is exposed to sunlight?',
        'options': ['Vitamin A', 'Vitamin C', 'Vitamin D', 'Vitamin E'],
        'correctOptionIndex': 2,
        'explanation':
        'Vitamin D is produced when UVB rays from the sun hit cholesterol in the skin cells, triggering a process that creates vitamin D.',
        'category': 'nutrition',
        'difficulty': 1,
      },
      {
        'question':
        'What is the most effective way to reduce stress long-term?',
        'options': [
          'Eliminating all stressors',
          'Regular relaxation practices',
          'Taking time off work',
          'Avoiding difficult situations',
        ],
        'correctOptionIndex': 1,
        'explanation':
        'While removing stressors helps temporarily, developing regular relaxation practices like meditation, deep breathing, or yoga provides sustainable stress management skills.',
        'category': 'stress',
        'difficulty': 2,
      },
      {
        'question': 'Which food is highest in antioxidants?',
        'options': [
          'White bread',
          'Blueberries',
          'Chicken breast',
          'White rice',
        ],
        'correctOptionIndex': 1,
        'explanation':
        'Blueberries are particularly high in antioxidants called anthocyanins, which give them their blue color and provide many health benefits.',
        'category': 'nutrition',
        'difficulty': 1,
      },
      {
        'question': 'What is the "flow state"?',
        'options': [
          'A meditative breathing technique',
          'A state of complete immersion and focus',
          'The movement of energy in the body',
          'A type of yoga practice',
        ],
        'correctOptionIndex': 1,
        'explanation':
        'Flow state is a psychological concept describing complete immersion and focus in an activity, characterized by energized focus, full involvement, and enjoyment.',
        'category': 'mental',
        'difficulty': 3,
      },
    ];

    int index = 0;
    for (var question in defaultQuestions) {
      final docRef = _firestore
          .collection('quiz_questions')
          .doc('default_q${index + 1}');
      batch.set(docRef, question);
      index++;
    }

    await batch.commit();
  }

  void _startQuiz() {
    setState(() {
      _showInstructions = false;
      _isQuizActive = true;
      _quizStartTime = DateTime.now();
      _currentQuestionIndex = 0;
      _score = 0;
      _streak = 0;
      _highestStreak = 0;
      _correctAnswers = 0;
    });

    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _timeLeft = _defaultTimePerQuestion;
    _answeringEnabled = true;
    _selectedAnswerIndex = null;
    _showExplanation = false;

    // Reset and start timer animation
    _timerAnimationController.reset();
    _timerAnimationController.forward();

    // Start question timer
    _questionTimer.cancel(); // Cancel any existing timer
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          // Time's up - handle as wrong answer
          _handleAnswer(null);
        }
      });
    });
  }

  void _handleAnswer(int? selectedIndex) {
    // Cancel the timer
    _questionTimer.cancel();
    _timerAnimationController.stop();

    // Only process if answering is enabled
    if (!_answeringEnabled) return;

    setState(() {
      _answeringEnabled = false;
      _selectedAnswerIndex = selectedIndex;
    });

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = selectedIndex == currentQuestion.correctOptionIndex;

    // Play sound based on answer
    _playSound(
      isCorrect ? 'audio/correct_answer.mp3' : 'audio/wrong_answer.mp3',
    );

    // Update score and streak
    setState(() {
      if (isCorrect) {
        // Base score = 10 points + remaining time bonus + streak bonus
        int timeBonus = _timeLeft * 2; // 2 points per second left
        int streakBonus = _streak > 2
            ? (_streak * 5)
            : 0; // 5 points per streak after 2

        _score += 10 + timeBonus + streakBonus;
        _correctAnswers++;
        _streak++;

        if (_streak > _highestStreak) {
          _highestStreak = _streak;
        }
      } else {
        // Reset streak on wrong answer
        _streak = 0;
      }

      // Show explanation
      _showExplanation = true;
    });

    // Wait before moving to the next question
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted || _disposed) return;

      // Move to next question or end quiz
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
        _startQuestionTimer();
      } else {
        _endQuiz();
      }
    });
  }

  void _endQuiz() {
    // Play success chime sound when quiz is completed
    _playSound('audio/success_chime.mp3', volume: 0.5);

    // Calculate duration
    final quizEndTime = DateTime.now();
    final quizDuration = _quizStartTime != null
        ? quizEndTime.difference(_quizStartTime!)
        : Duration.zero;

    // Save session to Firestore
    _gameService.saveGameSession(
      userId: widget.userId,
      gameId: widget.gameId,
      score: _score,
      streak: _highestStreak,
      duration: quizDuration,
      sessionData: {
        'totalQuestions': _questions.length,
        'correctAnswers': _correctAnswers,
        'accuracy': _questions.isNotEmpty
            ? (_correctAnswers / _questions.length * 100).round()
            : 0,
      },
    );

    // Show results screen
    setState(() {
      _isQuizActive = false;
    });
  }

  @override
  void dispose() {
    _disposed = true;

    // Cancel timer
    _questionTimer.cancel();

    // Dispose animation controllers
    _timerAnimationController.dispose();
    _cardAnimationController.dispose();

    // Release audio resources - important to fix the audio continuing issue
    _backgroundMusicPlayer.stop();
    _soundEffectPlayer.stop();

    _backgroundMusicPlayer.dispose();
    _soundEffectPlayer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () {
            if (_isQuizActive) {
              _showExitConfirmation();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          // Sound effects toggle button
          IconButton(
            icon: Icon(
              _isSoundEffectsMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: _toggleSoundEffects,
            tooltip: 'Toggle Sound Effects',
          ),
          // Background music toggle button
          IconButton(
            icon: Icon(
              _isMusicMuted ? Icons.music_off : Icons.music_note,
              color: Colors.white,
            ),
            onPressed: _toggleBackgroundMusic,
            tooltip: 'Toggle Background Music',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Color(0xFF0D1B2A), Color(0xFF1B263B)]
                : [Color(0xFFE9C46A), Color(0xFFF4A261)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingScreen()
              : _showInstructions
              ? _buildInstructionsScreen()
              : _isQuizActive
              ? _buildQuizScreen()
              : _buildResultsScreen(),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Quiz?'),
        content: Text(
          'Your progress will be lost. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit quiz screen
            },
            child: Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 20.h),
          Text(
            'Loading Questions...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/quiz.json',
              width: 200.w,
              height: 200.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),
            Text(
              'Wellness Trivia',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Test your wellness knowledge',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18.sp,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildInstructionItem(
                    Icons.timer,
                    'Time Limit',
                    'You have $_defaultTimePerQuestion seconds for each question',
                  ),
                  SizedBox(height: 16.h),
                  _buildInstructionItem(
                    Icons.star,
                    'Scoring',
                    'Answer faster for more points. Build streaks for bonuses!',
                  ),
                  SizedBox(height: 16.h),
                  _buildInstructionItem(
                    Icons.lightbulb,
                    'Learn',
                    'Explanations will help you understand each answer',
                  ),
                ],
              ),
            ),
            SizedBox(height: 48.h),
            if (_questions.isEmpty)
              Text(
                'No questions available. Please try again later.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              )
            else
              ElevatedButton(
                onPressed: _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFFF4A261),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: 56.w,
                    vertical: 18.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start Quiz',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.play_arrow_rounded),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
      IconData icon,
      String title,
      String description,
      ) {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: Colors.white, size: 24.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizScreen() {
    if (_currentQuestionIndex >= _questions.length) {
      return _buildLoadingScreen();
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          SizedBox(height: 8.h),

          // Progress and score indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildProgressIndicator(), _buildScoreIndicator()],
          ),

          // Timer
          _buildTimerBar(),

          // Question card
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Question
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16.h),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentQuestion.question,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (currentQuestion.category.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  currentQuestion.category,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                _getCategoryName(currentQuestion.category),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: _getCategoryColor(
                                    currentQuestion.category,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Answer options
                  ...List.generate(currentQuestion.options.length, (index) {
                    final isSelected = _selectedAnswerIndex == index;
                    final isCorrect =
                        index == currentQuestion.correctOptionIndex;

                    // Determine the card color based on selection and correctness
                    Color cardColor = Colors.white;
                    if (!_answeringEnabled && _selectedAnswerIndex != null) {
                      if (isCorrect) {
                        cardColor = Colors.green.shade100;
                      } else if (isSelected) {
                        cardColor = Colors.red.shade100;
                      }
                    }

                    return GestureDetector(
                      onTap: _answeringEnabled
                          ? () => _handleAnswer(index)
                          : null,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? (isCorrect ? Colors.green : Colors.red)
                                : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2.w : 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isCorrect
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2))
                                    : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: !_answeringEnabled && isCorrect
                                    ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24.sp,
                                )
                                    : (!_answeringEnabled &&
                                    isSelected &&
                                    !isCorrect
                                    ? Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 24.sp,
                                )
                                    : Text(
                                  String.fromCharCode(
                                    65 + index,
                                  ), // A, B, C, D
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? (isCorrect
                                        ? Colors.green
                                        : Colors.red)
                                        : Colors.grey.shade700,
                                  ),
                                )),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                currentQuestion.options[index],
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Explanation card (shown after answering)
                  if (_showExplanation && currentQuestion.explanation != null)
                    AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      margin: EdgeInsets.only(top: 16.h, bottom: 16.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1.w,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.amber,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Explanation',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            currentQuestion.explanation!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(Icons.quiz, color: Colors.white, size: 16.sp),
          SizedBox(width: 8.w),
          Text(
            '${_currentQuestionIndex + 1}/${_questions.length}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.amber, size: 16.sp),
          SizedBox(width: 8.w),
          Text(
            '$_score',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (_streak > 1) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.amber,
                    size: 14.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '$_streak',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: _timeLeft < 5 ? Colors.red : Colors.white,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '$_timeLeft seconds',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: _timeLeft < 5 ? Colors.red : Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AnimatedBuilder(
            animation: _timerAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _timeLeft / _defaultTimePerQuestion,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _timeLeft < 5 ? Colors.red : Colors.white,
                ),
                minHeight: 8.h,
                borderRadius: BorderRadius.circular(4.r),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              _score >
                  (_questions.length * 10 * 0.7) // 70% of max base score
                  ? 'assets/animations/trophy.json'
                  : 'assets/animations/congrats.json',
              width: 200.w,
              height: 200.w,
              fit: BoxFit.contain,
              repeat: false,
            ),
            SizedBox(height: 24.h),
            Text(
              _getResultMessage(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'Your final score',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2.w,
                ),
              ),
              child: Text(
                _score.toString(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 32.h),

            // Stats grid
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Questions',
                          '${_questions.length}',
                          Icons.quiz,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildStatCard(
                          'Correct',
                          '$_correctAnswers',
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Accuracy',
                          '${_questions.isNotEmpty ? (_correctAnswers / _questions.length * 100).round() : 0}%',
                          Icons.analytics,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildStatCard(
                          'Best Streak',
                          '$_highestStreak',
                          Icons.local_fire_department,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _questions.shuffle(Random());
                        _showInstructions = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFFF4A261),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.replay),
                        SizedBox(width: 8.w),
                        Text(
                          'Play Again',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        side: BorderSide(color: Colors.white, width: 1.w),
                      ),
                    ),
                    child: Text(
                      'Exit',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getResultMessage() {
    final accuracy = _questions.isNotEmpty
        ? (_correctAnswers / _questions.length * 100).round()
        : 0;

    if (accuracy >= 90) {
      return 'Excellent!';
    } else if (accuracy >= 70) {
      return 'Great Job!';
    } else if (accuracy >= 50) {
      return 'Good Effort!';
    } else {
      return 'Keep Learning!';
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'mindfulness':
        return 'Mindfulness';
      case 'physical':
        return 'Physical Health';
      case 'nutrition':
        return 'Nutrition';
      case 'sleep':
        return 'Sleep';
      case 'mental':
        return 'Mental Health';
      case 'stress':
        return 'Stress Management';
      default:
        return category.substring(0, 1).toUpperCase() + category.substring(1);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'mindfulness':
        return Colors.blue;
      case 'physical':
        return Colors.green;
      case 'nutrition':
        return Colors.orange;
      case 'sleep':
        return Colors.purple;
      case 'mental':
        return Colors.teal;
      case 'stress':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}