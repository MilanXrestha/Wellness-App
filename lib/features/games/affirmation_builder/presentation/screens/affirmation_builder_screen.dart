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
import '../../data/models/affirmation_model.dart';

class AffirmationBuilderScreen extends StatefulWidget {
  final String userId;
  final String gameId;
  final Map<String, dynamic> gameConfig;

  const AffirmationBuilderScreen({
    Key? key,
    required this.userId,
    required this.gameId,
    required this.gameConfig,
  }) : super(key: key);

  @override
  _AffirmationBuilderScreenState createState() =>
      _AffirmationBuilderScreenState();
}

class _AffirmationBuilderScreenState extends State<AffirmationBuilderScreen>
    with TickerProviderStateMixin {
  final GameService _gameService = GameService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Game state
  List<AffirmationModel> _affirmations = [];
  int _currentAffirmationIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _highestStreak = 0;
  int _completedAffirmations = 0;
  bool _isLoading = true;
  bool _isGameActive = false;
  bool _showInstructions = true;
  DateTime? _gameStartTime;

  // Words for current affirmation
  List<String> _availableWords = [];
  List<String> _placedWords = [];

  // Timer
  late Timer _gameTimer;
  int _timeLeft = 0;
  int _defaultSessionLength = 120; // Default, will be overridden by gameConfig

  // Animation controllers
  late AnimationController _timerAnimationController;
  late AnimationController _wordAnimationController;

  // Audio players
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _soundEffectPlayer = AudioPlayer();
  bool _isMusicMuted = false;
  bool _isSoundEffectsMuted = false;
  bool _isAudioInitialized = false;

  @override
  void initState() {
    super.initState();

    // Parse game configuration
    _defaultSessionLength = widget.gameConfig['defaultSessionLength'] ?? 120;

    // Setup animations
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _defaultSessionLength),
    );

    _wordAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize audio
    _initializeAudio();

    // Load affirmations
    _loadAffirmations();
  }

  Future<void> _initializeAudio() async {
    try {
      // Set release mode for background music to loop
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.setVolume(0.2);

      // Load and play background music
      await _backgroundMusicPlayer.play(
        AssetSource('audio/affirmation_background.mp3'),
      );

      setState(() {
        _isAudioInitialized = true;
      });
      print('Audio initialized successfully');
    } catch (e) {
      print('Error initializing audio: $e');
      setState(() {
        _isAudioInitialized = false;
      });
    }
  }

  Future<void> _playSound(String soundFile, {double volume = 1.0}) async {
    if (_isSoundEffectsMuted || !_isAudioInitialized) return;

    try {
      print('Playing sound: $soundFile');
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

  Future<void> _loadAffirmations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get affirmations from Firestore
      final snapshot = await _firestore.collection('affirmations').get();

      if (snapshot.docs.isEmpty) {
        // If no affirmations exist, let's create some default ones
        await _createDefaultAffirmations();

        // Try to get affirmations again
        final newSnapshot = await _firestore.collection('affirmations').get();
        _affirmations = newSnapshot.docs
            .map((doc) => AffirmationModel.fromFirestore(doc))
            .toList();
      } else {
        _affirmations = snapshot.docs
            .map((doc) => AffirmationModel.fromFirestore(doc))
            .toList();
      }

      // Shuffle affirmations
      _affirmations.shuffle(Random());

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading affirmations: $e');
      setState(() {
        _isLoading = false;
        _affirmations = []; // Empty list will show error state
      });
    }
  }

  Future<void> _createDefaultAffirmations() async {
    final batch = _firestore.batch();

    final defaultAffirmations = [
      {
        'text': 'I am strong and capable.',
        'words': ['I', 'am', 'strong', 'and', 'capable'],
        'category': 'strength',
        'difficulty': 1,
      },
      {
        'text': 'I deserve love and happiness.',
        'words': ['I', 'deserve', 'love', 'and', 'happiness'],
        'category': 'self-love',
        'difficulty': 1,
      },
      {
        'text': 'My mind is calm and peaceful.',
        'words': ['My', 'mind', 'is', 'calm', 'and', 'peaceful'],
        'category': 'mindfulness',
        'difficulty': 1,
      },
      {
        'text': 'I choose positivity today.',
        'words': ['I', 'choose', 'positivity', 'today'],
        'category': 'positivity',
        'difficulty': 1,
      },
      {
        'text': 'I am grateful for this moment.',
        'words': ['I', 'am', 'grateful', 'for', 'this', 'moment'],
        'category': 'gratitude',
        'difficulty': 2,
      },
      {
        'text': 'My potential is limitless.',
        'words': ['My', 'potential', 'is', 'limitless'],
        'category': 'growth',
        'difficulty': 1,
      },
      {
        'text': 'I embrace all my emotions.',
        'words': ['I', 'embrace', 'all', 'my', 'emotions'],
        'category': 'emotional-health',
        'difficulty': 2,
      },
      {
        'text': 'Every day I am getting better.',
        'words': ['Every', 'day', 'I', 'am', 'getting', 'better'],
        'category': 'growth',
        'difficulty': 2,
      },
      {
        'text': 'I radiate confidence and grace.',
        'words': ['I', 'radiate', 'confidence', 'and', 'grace'],
        'category': 'confidence',
        'difficulty': 2,
      },
      {
        'text': 'I trust my inner wisdom.',
        'words': ['I', 'trust', 'my', 'inner', 'wisdom'],
        'category': 'self-trust',
        'difficulty': 1,
      },
      {
        'text': 'I am worthy of good things.',
        'words': ['I', 'am', 'worthy', 'of', 'good', 'things'],
        'category': 'self-worth',
        'difficulty': 2,
      },
      {
        'text': 'My body is healthy and strong.',
        'words': ['My', 'body', 'is', 'healthy', 'and', 'strong'],
        'category': 'physical-health',
        'difficulty': 2,
      },
      {
        'text': 'I create my own happiness.',
        'words': ['I', 'create', 'my', 'own', 'happiness'],
        'category': 'happiness',
        'difficulty': 1,
      },
      {
        'text': 'I am enough just as I am.',
        'words': ['I', 'am', 'enough', 'just', 'as', 'I', 'am'],
        'category': 'self-acceptance',
        'difficulty': 2,
      },
      {
        'text': 'I choose to focus on the good.',
        'words': ['I', 'choose', 'to', 'focus', 'on', 'the', 'good'],
        'category': 'positivity',
        'difficulty': 3,
      },
    ];

    int index = 0;
    for (var affirmation in defaultAffirmations) {
      final docRef = _firestore
          .collection('affirmations')
          .doc('default_a${index + 1}');
      batch.set(docRef, affirmation);
      index++;
    }

    await batch.commit();
  }

  void _startGame() {
    if (_affirmations.isEmpty) {
      // Handle no affirmations case
      return;
    }

    setState(() {
      _showInstructions = false;
      _isGameActive = true;
      _gameStartTime = DateTime.now();
      _currentAffirmationIndex = 0;
      _score = 0;
      _streak = 0;
      _highestStreak = 0;
      _completedAffirmations = 0;
      _timeLeft = _defaultSessionLength;

      // Set up the first affirmation
      _setupCurrentAffirmation();
    });

    // Start timer
    _startGameTimer();
  }

  void _setupCurrentAffirmation() {
    final currentAffirmation = _affirmations[_currentAffirmationIndex];
    setState(() {
      _availableWords = currentAffirmation.getShuffledWords();
      _placedWords = List.filled(currentAffirmation.words.length, '');
    });
  }

  void _startGameTimer() {
    // Reset and start timer animation
    _timerAnimationController.reset();
    _timerAnimationController.forward();

    // Start game timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          // Time's up - end the game
          _endGame();
        }
      });
    });
  }

  void _moveToNextAffirmation() {
    // Play completion sound
    _playSound('assets/audio/affirmation_complete.mp3');

    // Update state
    setState(() {
      _completedAffirmations++;
      _currentAffirmationIndex++;

      // Check if we've reached the end of available affirmations
      if (_currentAffirmationIndex >= _affirmations.length) {
        _endGame();
        return;
      }

      // Otherwise, set up the next affirmation
      _setupCurrentAffirmation();
    });
  }

  void _placeWord(String word, int index) {
    if (_placedWords[index].isNotEmpty) {
      return; // Slot already filled
    }

    setState(() {
      // Place the word
      _placedWords[index] = word;

      // Remove from available words
      _availableWords.remove(word);

      // Play sound
      _playSound('audio/word_place.mp3');
    });

    // Check if the affirmation is complete
    _checkAffirmationComplete();
  }

  void _removeWord(int index) {
    if (_placedWords[index].isEmpty) {
      return; // No word to remove
    }

    setState(() {
      // Get the word
      final word = _placedWords[index];

      // Remove it from placed words
      _placedWords[index] = '';

      // Add back to available words
      _availableWords.add(word);

      // Play sound
      _playSound('audio/word_remove.mp3');
    });
  }

  void _checkAffirmationComplete() {
    // Check if all slots are filled
    if (_placedWords.contains('')) {
      return; // Not all slots filled
    }

    final currentAffirmation = _affirmations[_currentAffirmationIndex];

    // Check if words are in correct order
    bool isCorrect = true;
    for (int i = 0; i < currentAffirmation.words.length; i++) {
      if (_placedWords[i] != currentAffirmation.words[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      // Award points
      final difficultyMultiplier = currentAffirmation.difficulty;
      final wordsCount = currentAffirmation.words.length;

      setState(() {
        // Base score: 10 points per word × difficulty
        int baseScore = 10 * wordsCount * difficultyMultiplier;

        // Time bonus: up to 50% extra for completing quickly
        int timeBonus = 0;
        // We'll base this on the expected time per word
        final expectedTimePerWord = 5; // seconds
        final expectedTime = expectedTimePerWord * wordsCount;
        final timeTaken = _defaultSessionLength - _timeLeft;

        if (timeTaken < expectedTime) {
          timeBonus = (baseScore * 0.5).round();
        } else if (timeTaken < expectedTime * 1.5) {
          timeBonus = (baseScore * 0.25).round();
        }

        // Streak bonus
        _streak++;
        if (_streak > _highestStreak) {
          _highestStreak = _streak;
        }

        int streakBonus = _streak > 1 ? (_streak * 5) : 0;

        // Total score for this affirmation
        int affirmationScore = baseScore + timeBonus + streakBonus;
        _score += affirmationScore;

        // Show success animation/feedback before moving to next
        // This will be handled in the UI with a short delay
      });

      // Show success animation briefly before moving to next
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          _moveToNextAffirmation();
        }
      });
    } else {
      // Wrong order - provide feedback
      _playSound('audio/wrong_order.mp3');

      // Reset streak
      setState(() {
        _streak = 0;
      });

      // Shake the words to indicate wrong order
      _wordAnimationController.reset();
      _wordAnimationController.forward();
    }
  }

  void _endGame() {
    // Cancel timer
    _gameTimer.cancel();
    _timerAnimationController.stop();

    // Calculate duration
    final gameEndTime = DateTime.now();
    final gameDuration = _gameStartTime != null
        ? gameEndTime.difference(_gameStartTime!)
        : Duration.zero;

    // Save session to Firestore
    _gameService.saveGameSession(
      userId: widget.userId,
      gameId: widget.gameId,
      score: _score,
      streak: _highestStreak,
      duration: gameDuration,
      sessionData: {
        'totalAffirmations': _affirmations.length,
        'completedAffirmations': _completedAffirmations,
        'timeLeft': _timeLeft,
      },
    );

    // Show results screen
    setState(() {
      _isGameActive = false;
    });
  }

  @override
  void dispose() {
    if (_isGameActive) {
      _gameTimer.cancel();
    }
    _timerAnimationController.dispose();
    _wordAnimationController.dispose();

    // Stop and dispose audio players
    try {
      _backgroundMusicPlayer.pause();
      _soundEffectPlayer.pause();
      Future.wait([
        _backgroundMusicPlayer.stop(),
        _soundEffectPlayer.stop(),
        _backgroundMusicPlayer.dispose(),
        _soundEffectPlayer.dispose(),
      ]);
    } catch (e) {
      print('Error disposing audio players: $e');
    }

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
            if (_isGameActive) {
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
                ? [Color(0xFF3A506B), Color(0xFF1C2541)]
                : [Color(0xFF7B68EE), Color(0xFF9370DB)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingScreen()
              : _showInstructions
              ? _buildInstructionsScreen()
              : _isGameActive
              ? _buildGameScreen()
              : _buildResultsScreen(),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Game?'),
        content: Text(
          'Your progress will be lost. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Stop audio before exiting
              try {
                await _backgroundMusicPlayer.pause();
                await _soundEffectPlayer.pause();
                await _backgroundMusicPlayer.stop();
                await _soundEffectPlayer.stop();
              } catch (e) {
                print('Error stopping audio on exit: $e');
              }
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit game screen
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
            'Loading Affirmations...',
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
              'assets/animations/abc_blocks.json',
              width: 200.w,
              height: 200.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),
            Text(
              'Affirmation Builder',
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
              'Build positive affirmations by arranging words',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
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
                    Icons.drag_indicator,
                    'Drag & Drop',
                    'Drag words from below and drop them into slots to form the affirmation',
                  ),
                  SizedBox(height: 16.h),
                  _buildInstructionItem(
                    Icons.timer,
                    'Time Limit',
                    'Complete as many affirmations as you can before time runs out',
                  ),
                  SizedBox(height: 16.h),
                  _buildInstructionItem(
                    Icons.psychology,
                    'Positive Thinking',
                    'Build affirmations to reinforce positive self-talk',
                  ),
                ],
              ),
            ),
            SizedBox(height: 48.h),
            if (_affirmations.isEmpty)
              Text(
                'No affirmations available. Please try again later.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              )
            else
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF7B68EE),
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
                      'Start Game',
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

  Widget _buildGameScreen() {
    if (_currentAffirmationIndex >= _affirmations.length) {
      return _buildLoadingScreen();
    }

    final currentAffirmation = _affirmations[_currentAffirmationIndex];

    return Column(
      children: [
        SizedBox(height: 8.h),

        // Progress and score indicators
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Progress counter
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${_currentAffirmationIndex + 1}/${_affirmations.length}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Score indicator
              Container(
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
                  ],
                ),
              ),
            ],
          ),
        ),

        // Timer bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    color: _timeLeft < 10 ? Colors.red : Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '$_timeLeft seconds',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: _timeLeft < 10 ? Colors.red : Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              LinearProgressIndicator(
                value: _timeLeft / _defaultSessionLength,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _timeLeft < 10 ? Colors.red : Colors.white,
                ),
                minHeight: 8.h,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ],
          ),
        ),

        // Category indicator
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: _getCategoryColor(
              currentAffirmation.category,
            ).withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            _getCategoryName(currentAffirmation.category),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: _getCategoryColor(currentAffirmation.category),
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Affirmation target area - where words are placed
        Expanded(
          flex: 3,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2.w,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Form a positive affirmation:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),

                // Word slots area - multi-row layout with Wrap
                Expanded(
                  child: AnimatedBuilder(
                    animation: _wordAnimationController,
                    builder: (context, child) {
                      // Apply a shake animation if the order is wrong
                      return Transform.translate(
                        offset: _wordAnimationController.status ==
                            AnimationStatus.forward
                            ? Offset(
                          sin(_wordAnimationController.value * 10 * pi) *
                              10,
                          0,
                        )
                            : Offset.zero,
                        child: child,
                      );
                    },
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: List.generate(
                        _placedWords.length,
                            (index) => _buildWordSlot(index),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Available words area - where words can be dragged from
        Expanded(
          flex: 2,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Words:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 8.h),

                // Draggable words
                Expanded(
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _availableWords
                        .map((word) => _buildDraggableWord(word))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildWordSlot(int index) {
    final isEmpty = _placedWords[index].isEmpty;

    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: !isEmpty ? () => _removeWord(index) : null,
          child: Container(
            width: 80.w,
            height: 45.h,
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty
                  ? Colors.green.withOpacity(0.3)
                  : (isEmpty
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.9)),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.green
                    : Colors.white.withOpacity(0.5),
                width: 2.w,
              ),
            ),
            child: Center(
              child: isEmpty
                  ? Icon(
                Icons.add,
                color: Colors.white.withOpacity(0.5),
                size: 20.sp,
              )
                  : Text(
                _placedWords[index],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
      onWillAccept: (data) => isEmpty && data != null,
      onAccept: (word) {
        _placeWord(word, index);
      },
    );
  }

  Widget _buildDraggableWord(String word) {
    return Draggable<String>(
      data: word,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            word,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.w),
        ),
        child: Text(
          word,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.transparent,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          word,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
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
              _score > 100
                  ? 'assets/animations/trophy.json'
                  : 'assets/animations/congrats.json',
              width: 200.w,
              height: 200.w,
              fit: BoxFit.contain,
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
                          'Completed',
                          '$_completedAffirmations',
                          Icons.check_circle,
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
                        _affirmations.shuffle(Random());
                        _showInstructions = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF7B68EE),
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
    if (_completedAffirmations >= 10) {
      return 'Amazing Job!';
    } else if (_completedAffirmations >= 5) {
      return 'Well Done!';
    } else if (_completedAffirmations > 0) {
      return 'Good Start!';
    } else {
      return 'Keep Practicing!';
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'strength':
        return 'Strength';
      case 'self-love':
        return 'Self-Love';
      case 'mindfulness':
        return 'Mindfulness';
      case 'positivity':
        return 'Positivity';
      case 'gratitude':
        return 'Gratitude';
      case 'growth':
        return 'Growth';
      case 'emotional-health':
        return 'Emotional Health';
      case 'confidence':
        return 'Confidence';
      case 'self-trust':
        return 'Self-Trust';
      case 'self-worth':
        return 'Self-Worth';
      case 'physical-health':
        return 'Physical Health';
      case 'happiness':
        return 'Happiness';
      case 'self-acceptance':
        return 'Self-Acceptance';
      default:
        return category.substring(0, 1).toUpperCase() + category.substring(1);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'strength':
        return Colors.red;
      case 'self-love':
        return Colors.pink;
      case 'mindfulness':
        return Colors.blue;
      case 'positivity':
        return Colors.amber;
      case 'gratitude':
        return Colors.green;
      case 'growth':
        return Colors.teal;
      case 'emotional-health':
        return Colors.orange;
      case 'confidence':
        return Colors.purple;
      case 'self-trust':
        return Colors.cyan;
      case 'self-worth':
        return Colors.deepPurple;
      case 'physical-health':
        return Colors.lightGreen;
      case 'happiness':
        return Colors.yellow;
      case 'self-acceptance':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }
}