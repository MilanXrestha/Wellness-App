// screens/breathing_game_screen.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../../core/resources/colors.dart';
import '../../../game_hub/data/services/game_service.dart';

class BreathingGameScreen extends StatefulWidget {
  final String userId;
  final String gameId;
  final Map<String, dynamic> gameConfig;

  const BreathingGameScreen({
    Key? key,
    required this.userId,
    required this.gameId,
    required this.gameConfig,
  }) : super(key: key);

  @override
  BreathingGameScreenState createState() => BreathingGameScreenState();
}

enum BreathPhase { inhale, exhale, paused, completed }

class BreathingGameScreenState extends State<BreathingGameScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _breathAnimController;
  late AnimationController _backgroundAnimController;
  late AnimationController _rippleAnimController;
  late Animation<double> _breathAnimation;

  // Game state
  late Timer _sessionTimer;
  BreathPhase _currentPhase = BreathPhase.paused;
  int _completedRounds = 0;
  int _totalRounds = 0;
  int _score = 0;
  bool _gameActive = false;
  bool _showInstructions = true;
  bool _showLevelSelection = false;
  bool _showCountdown = false;
  bool _showCompletion = false;
  int _countdownValue = 3;
  DateTime? _sessionStartTime;
  bool _waitingForVoice = false; // Add this to track TTS completion

  // Duration settings
  Duration _inhaleDuration = const Duration(seconds: 4);
  Duration _exhaleDuration = const Duration(seconds: 6);
  int _remainingSeconds = 0;

  final GameService _gameService = GameService();

  // Audio players
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _soundEffectPlayer = AudioPlayer();
  bool _isMusicMuted = false;
  bool _isSoundEffectsMuted = false;
  bool _isVibrationEnabled = true;
  bool _isAudioInitialized = false;

  // Text to speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsSpeaking = false;

  @override
  void initState() {
    super.initState();

    // Initialize TTS
    _initTts();

    // Parse game configuration (but use our fixed durations)
    _totalRounds = widget.gameConfig['totalRounds'] ?? 10;
    _remainingSeconds =
        (_inhaleDuration.inSeconds + _exhaleDuration.inSeconds) * _totalRounds;

    // Setup breathing animation
    _breathAnimController = AnimationController(
      vsync: this,
      duration: _inhaleDuration,
    );

    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathAnimController, curve: Curves.easeInOut),
    );

    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _rippleAnimController = AnimationController(
      vsync: this,
      duration: _inhaleDuration,
    );

    // Setup initial timer
    _sessionTimer = Timer(Duration.zero, () {});

    // Initialize audio
    _initializeAudio();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Add listener for TTS completion
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isTtsSpeaking = false;
        if (_waitingForVoice) {
          _waitingForVoice = false;
          _proceedAfterVoice();
        }
      });
    });
  }

  Future<void> _speak(String text) async {
    if (_isSoundEffectsMuted) return;
    setState(() {
      _isTtsSpeaking = true;
    });
    await _flutterTts.speak(text);
  }

  void _proceedAfterVoice() {
    if (_showCountdown && _countdownValue <= 0) {
      // If countdown has reached 0 and TTS finished saying "GO"
      setState(() {
        _showCountdown = false;
        _gameActive = true;
        _score = 0;
        _completedRounds = 0;
        _remainingSeconds =
            (_inhaleDuration.inSeconds + _exhaleDuration.inSeconds) *
            _totalRounds;
        _sessionStartTime = DateTime.now();
      });

      // Start the session
      _startBreathingCycle();

      // Start the session timer
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _completeSession();
          }
        });
      });
    }
  }

  Future<void> _initializeAudio() async {
    try {
      // Set release mode for background music to loop
      await _backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer.setVolume(0.3);

      // Load and play rain sound
      await _backgroundMusicPlayer.play(AssetSource('audio/rain_sound.mp3'));

      _isAudioInitialized = true;
    } catch (e) {
      log('Error initializing audio: $e', name: 'BreathingGame');
    }
  }

  Future<void> _playSound(String soundFile, {double volume = 1.0}) async {
    if (_isSoundEffectsMuted || !_isAudioInitialized) return;

    try {
      await _soundEffectPlayer.setVolume(volume);
      await _soundEffectPlayer.play(AssetSource(soundFile));

      // Vibrate if enabled
      if (_isVibrationEnabled) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      log('Error playing sound: $e', name: 'BreathingGame');
    }
  }

  void _vibrate() {
    if (_isVibrationEnabled) {
      HapticFeedback.mediumImpact();
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

  void _toggleVibration() {
    setState(() {
      _isVibrationEnabled = !_isVibrationEnabled;
    });

    // Give feedback that vibration setting changed
    if (_isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _breathAnimController.dispose();
    _backgroundAnimController.dispose();
    _rippleAnimController.dispose();
    _sessionTimer.cancel();
    _backgroundMusicPlayer.dispose();
    _soundEffectPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _showLevelScreen() {
    setState(() {
      _showInstructions = false;
      _showLevelSelection = true;
    });
  }

  void _startLevel(int rounds) {
    setState(() {
      _showLevelSelection = false;
      _totalRounds = rounds;
      _remainingSeconds =
          (_inhaleDuration.inSeconds + _exhaleDuration.inSeconds) *
          _totalRounds;
      _currentPhase = BreathPhase.paused; // Reset phase to paused
    });
    _startGame();
  }

  void _startGame() {
    setState(() {
      _showCountdown = true;
      _countdownValue = 3;
    });

    // Start countdown with voice synchronization
    _runCountdown();
  }

  void _runCountdown() {
    if (_countdownValue > 0) {
      // Speak the current number and wait for completion
      _speak(_countdownValue.toString());
      _vibrate();

      // Set up timer to check when TTS finishes
      Timer(const Duration(milliseconds: 800), () {
        if (!_isTtsSpeaking) {
          // If TTS finished quickly, proceed with countdown
          setState(() {
            _countdownValue--;
          });
          _runCountdown();
        } else {
          // If TTS is still speaking, wait for it to finish
          setState(() {
            _waitingForVoice = true;
          });
          // The _proceedAfterVoice method will be called when TTS finishes
        }
      });
    } else {
      // When countdown reaches 0, say "GO!" and wait before starting
      _speak("GO!");
      _vibrate();
      // We'll wait for TTS to finish before starting the game
      setState(() {
        _waitingForVoice = true;
      });
    }
  }

  void _startBreathingCycle() {
    _transitionToPhase(BreathPhase.inhale);
  }

  void _transitionToPhase(BreathPhase phase) {
    if (_currentPhase == BreathPhase.completed) return;

    setState(() {
      _currentPhase = phase;
    });

    switch (phase) {
      case BreathPhase.inhale:
        _playSound('audio/bell_ting.mp3', volume: 0.5);
        _breathAnimController.duration = _inhaleDuration;
        _rippleAnimController.duration = _inhaleDuration;
        _breathAnimController.forward(from: 0.0);
        _rippleAnimController.forward(from: 0.0);

        // Schedule transition to exhale after inhale duration
        Future.delayed(_inhaleDuration, () {
          if (_currentPhase != BreathPhase.paused &&
              _currentPhase != BreathPhase.completed) {
            _transitionToPhase(BreathPhase.exhale);
          }
        });
        break;

      case BreathPhase.exhale:
        _playSound('audio/bell_ting_low.mp3', volume: 0.5);
        _breathAnimController.duration = _exhaleDuration;
        _rippleAnimController.duration = _exhaleDuration;
        _breathAnimController.reverse(from: 1.0);
        _rippleAnimController.reverse(from: 1.0);

        // Schedule transition back to inhale after exhale completes
        Future.delayed(_exhaleDuration, () {
          if (_currentPhase != BreathPhase.paused &&
              _currentPhase != BreathPhase.completed) {
            // Complete one full breath cycle
            setState(() {
              _completedRounds++;
              _score += 10;
            });

            // Check if all rounds are completed
            if (_completedRounds >= _totalRounds) {
              _completeSession();
            } else {
              _transitionToPhase(BreathPhase.inhale);
            }
          }
        });
        break;

      case BreathPhase.paused:
      case BreathPhase.completed:
        // Nothing to do here
        break;
    }
  }

  void _completeSession() {
    _sessionTimer.cancel();
    _breathAnimController.stop();

    setState(() {
      _gameActive = false;
      _currentPhase = BreathPhase.completed;
    });

    // Calculate session duration
    final sessionDuration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration(
            seconds:
                (_inhaleDuration.inSeconds + _exhaleDuration.inSeconds) *
                    _totalRounds -
                _remainingSeconds,
          );

    // Save game session to Firestore with breathing-specific data
    _gameService
        .saveGameSession(
          userId: widget.userId,
          gameId: widget.gameId,
          score: _score,
          streak: _completedRounds,
          duration: sessionDuration,
          sessionData: {
            'totalRounds': _totalRounds,
            'completedRounds': _completedRounds,
            'difficultyLevel': _getDifficultyLevel(),
            'inhaleDuration': _inhaleDuration.inSeconds,
            'exhaleDuration': _exhaleDuration.inSeconds,
            'totalBreathingTime':
                _completedRounds *
                (_inhaleDuration.inSeconds + _exhaleDuration.inSeconds),
            'accuracy': 100, // Since it's passive, accuracy is always 100%
          },
        )
        .then((_) {
          // Check for achievements after saving session
          _checkBreathingAchievements();
        });

    // Only show completion animation if at least one round was completed
    if (_completedRounds > 0) {
      setState(() {
        _showCompletion = true;
      });

      // Play success sound - Changed to success_chime.mp3
      _playSound('audio/success_chime.mp3');

      // Show completion animation for a few seconds, then show results
      Future.delayed(const Duration(seconds: 4), () {
        _showResultsDialog();
      });
    } else {
      // If no rounds completed, just show the results dialog
      _showResultsDialog();
    }
  }

  // Helper method to determine difficulty level
  String _getDifficultyLevel() {
    if (_totalRounds <= 3) return 'beginner';
    if (_totalRounds <= 10) return 'intermediate';
    return 'advanced';
  }

  // Check for breathing-specific achievements
  Future<void> _checkBreathingAchievements() async {
    try {
      // Get all breathing game achievements
      final breathingAchievements = await _gameService.getGameAchievements(
        'breathing_game',
      );

      // Get user's unlocked achievements
      final userAchievements = await _gameService.getUserAchievements(
        widget.userId,
      );
      final unlockedIds = userAchievements
          .map((a) => a['achievementId'] as String)
          .toSet();

      // Get user's breathing stats
      final progressSnapshot = await _gameService.getUserGameProgress(
        widget.userId,
        widget.gameId,
      );

      // Check each achievement to see if it should be unlocked
      for (final achievement in breathingAchievements) {
        // Skip if already unlocked
        if (unlockedIds.contains(achievement['id'])) continue;

        final criteria = achievement['criteria'] as Map<String, dynamic>;
        bool shouldUnlock = false;

        // Check different types of criteria specific to breathing game
        if (criteria.containsKey('completedRounds') &&
            progressSnapshot != null &&
            progressSnapshot.gameSpecificData.containsKey(
              'totalBreathingRounds',
            )) {
          final requiredRounds = criteria['completedRounds'] as int;
          final totalRounds =
              progressSnapshot.gameSpecificData['totalBreathingRounds']
                  as int? ??
              0;

          if (totalRounds >= requiredRounds) {
            shouldUnlock = true;
          }
        }

        if (criteria.containsKey('singleSessionRounds') &&
            _completedRounds >= (criteria['singleSessionRounds'] as int)) {
          shouldUnlock = true;
        }

        if (criteria.containsKey('difficultyCompleted') &&
            criteria['difficultyCompleted'] == _getDifficultyLevel()) {
          shouldUnlock = true;
        }

        if (criteria.containsKey('totalSessions') &&
            progressSnapshot != null &&
            progressSnapshot.totalPlays >= (criteria['totalSessions'] as int)) {
          shouldUnlock = true;
        }

        // If criteria met, unlock achievement
        if (shouldUnlock) {
          await _gameService.unlockAchievement(
            userId: widget.userId,
            achievementId: achievement['id'],
          );

          // Show achievement unlock notification
          _showAchievementUnlocked(achievement);
        }
      }
    } catch (e) {
      log('Error checking breathing achievements: $e', name: 'BreathingGame');
    }
  }

  void _showAchievementUnlocked(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/achievement_unlocked.json',
                width: 150.w,
                height: 150.w,
                fit: BoxFit.contain,
                repeat: false,
              ),
              SizedBox(height: 16.h),
              Text(
                'Achievement Unlocked!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                achievement['title'] ?? 'New Achievement',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                achievement['description'] ?? '',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '+${achievement['pointsAwarded']} points',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'Awesome!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultsDialog(),
    );
  }

  Widget _buildResultsDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Calculate total session time in minutes
    final totalSessionTime =
        (_completedRounds *
            (_inhaleDuration.inSeconds + _exhaleDuration.inSeconds)) /
        60;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24.w),
        width: 300.w, // Set fixed width to avoid overflow
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Session Complete',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 48.sp,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Wellness Score',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              _score.toString(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 42.sp,
                fontWeight: FontWeight.w700,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatColumn(
                  'Rounds Completed',
                  '$_completedRounds/$_totalRounds',
                ),
                SizedBox(width: 24.w),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Total Breathing Time: ${totalSessionTime.toStringAsFixed(1)} minutes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Done',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showLevelSelection = true;
                  _showCompletion = false;
                  _currentPhase = BreathPhase.paused;
                  _gameActive = false;
                  _completedRounds = 0;
                  _score = 0;
                });
              },
              child: Text(
                'Try Another Level',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.sp,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
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
            if (_gameActive) {
              _completeSession();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          // Vibration toggle button - Updated to match pattern of other toggles
          IconButton(
            icon: Icon(
              _isVibrationEnabled ? Icons.vibration : Icons.vibration_outlined,
              color: Colors.white,
            ),
            onPressed: _toggleVibration,
            tooltip: 'Toggle Vibration',
          ),
          // Sound effects toggle button
          IconButton(
            icon: Icon(
              _isSoundEffectsMuted
                  ? Icons.notifications_off
                  : Icons.notifications,
              color: Colors.white,
            ),
            onPressed: _toggleSoundEffects,
            tooltip: 'Toggle Bell Sounds',
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
          if (_gameActive)
            TextButton(
              onPressed: _completeSession,
              child: Text(
                'End',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _backgroundAnimController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Color.lerp(
                          Color(0xFF0D1B2A),
                          Color(0xFF1B263B),
                          _backgroundAnimController.value,
                        )!,
                        Color.lerp(
                          Color(0xFF415A77),
                          Color(0xFF778DA9),
                          _backgroundAnimController.value,
                        )!,
                      ]
                    : [
                        Color.lerp(
                          Color(0xFF6B9BD1),
                          Color(0xFF5A8FC8),
                          _backgroundAnimController.value,
                        )!,
                        Color.lerp(
                          Color(0xFF87CEEB),
                          Color(0xFF98D8F4),
                          _backgroundAnimController.value,
                        )!,
                      ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background elements
              ..._buildBackgroundElements(),

              // Main content
              Positioned.fill(
                child: _showInstructions
                    ? _buildInstructions()
                    : _showLevelSelection
                    ? _buildLevelSelection()
                    : _showCountdown
                    ? _buildCountdown()
                    : _showCompletion
                    ? _buildCompletionAnimation()
                    : _buildGameContent(),
              ),

              // Session timer
              if (_gameActive)
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: Colors.white, size: 16.sp),
                        SizedBox(width: 8.w),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Progress counter
              if (_gameActive)
                Positioned(
                  top: 16.h,
                  right: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '$_completedRounds/$_totalRounds',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Choose Your Level',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Select based on your experience',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              fontWeight: FontWeight.w300,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 40.h),

          // Beginner level
          _buildLevelCard(
            title: 'Beginner',
            description: '3 breathing rounds',
            duration: '30 seconds',
            icon: Icons.star_outline,
            color: Colors.green,
            onTap: () => _startLevel(3),
          ),
          SizedBox(height: 20.h),

          // Intermediate level
          _buildLevelCard(
            title: 'Intermediate',
            description: '10 breathing rounds',
            duration: '1:40 minutes',
            icon: Icons.star_half,
            color: Colors.blue,
            onTap: () => _startLevel(10),
          ),
          SizedBox(height: 20.h),

          // Advanced level
          _buildLevelCard(
            title: 'Advanced',
            description: '20 breathing rounds',
            duration: '3:20 minutes',
            icon: Icons.star,
            color: Colors.purple,
            onTap: () => _startLevel(20),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required String title,
    required String description,
    required String duration,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30.sp),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    duration,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/congrats.json',
            width: 300.w,
            height: 300.w,
            fit: BoxFit.contain,
            repeat: false,
          ),
          SizedBox(height: 24.h),
          Text(
            "Well Done!",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "You completed $_completedRounds breathing cycles",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _countdownValue == 0 ? "GO!" : (_countdownValue).toString(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 80.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "Relax and get comfortable",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundElements() {
    return [
      // Floating clouds/bubbles
      Positioned(
        top: 100.h,
        left: -50.w,
        child: AnimatedBuilder(
          animation: _backgroundAnimController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.95 + (_backgroundAnimController.value * 0.1),
              child: Container(
                width: 150.w,
                height: 150.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: 150.h,
        right: -30.w,
        child: AnimatedBuilder(
          animation: _backgroundAnimController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_backgroundAnimController.value * 0.1),
              child: Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Beautiful animated icon or lottie
          Container(
            width: 200.w,
            height: 200.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/meditation.json',
                  width: 200.w,
                  height: 200.w,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          Text(
            'Mindful Breathing',
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
            'Find your inner peace',
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
                  Icons.air,
                  'Follow the breath',
                  'Inhale for 4 seconds, exhale for 6 seconds',
                ),
                SizedBox(height: 16.h),
                _buildInstructionItem(
                  Icons.access_time_filled,
                  'Take your time',
                  'Each breath cycle takes 10 seconds',
                ),
                SizedBox(height: 16.h),
                _buildInstructionItem(
                  Icons.spa_rounded,
                  'Choose your level',
                  'Select beginner, intermediate, or advanced',
                ),
              ],
            ),
          ),
          SizedBox(height: 48.h),
          ElevatedButton(
            onPressed: _showLevelScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF5A8FC8),
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 56.w, vertical: 18.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Level',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ],
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

  Widget _buildGameContent() {
    return Column(
      children: [
        // Score display
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, color: Colors.amber, size: 24.sp),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      _score.toString(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Breathing circle
        Expanded(child: Center(child: _buildBreathingCircle())),

        // Phase indicator
        _buildPhaseIndicator(),
      ],
    );
  }

  Widget _buildBreathingCircle() {
    return AnimatedBuilder(
      animation: _breathAnimController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ripple effects
            ..._buildRippleEffects(),

            // Outer circle (fixed)
            Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2.w,
                ),
              ),
            ),

            // Main breathing circle
            Transform.scale(
              scale: _breathAnimation.value,
              child: Container(
                width: 220.w,
                height: 220.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 3.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                // Breathing text in center
                child: Center(
                  child: Text(
                    _currentPhase == BreathPhase.inhale ? "INHALE" : "EXHALE",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildRippleEffects() {
    final List<Widget> ripples = [];

    if (_currentPhase == BreathPhase.inhale) {
      // Expanding ripples for inhale
      ripples.add(
        AnimatedBuilder(
          animation: _rippleAnimController,
          builder: (context, child) {
            final scale = 0.8 + (_rippleAnimController.value * 0.4);
            final opacity = 0.3 - (_rippleAnimController.value * 0.3);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 260.w,
                height: 260.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(opacity),
                    width: 2.w,
                  ),
                ),
              ),
            );
          },
        ),
      );

      ripples.add(
        AnimatedBuilder(
          animation: _rippleAnimController,
          builder: (context, child) {
            final scale = 0.9 + (_rippleAnimController.value * 0.3);
            final opacity = 0.2 - (_rippleAnimController.value * 0.2);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 280.w,
                height: 280.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(opacity),
                    width: 1.5.w,
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else if (_currentPhase == BreathPhase.exhale) {
      // Contracting ripples for exhale
      ripples.add(
        AnimatedBuilder(
          animation: _rippleAnimController,
          builder: (context, child) {
            final scale = 1.2 - (_rippleAnimController.value * 0.4);
            final opacity = 0.3 - ((1 - _rippleAnimController.value) * 0.3);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 260.w,
                height: 260.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(opacity),
                    width: 2.w,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return ripples;
  }

  Widget _buildPhaseIndicator() {
    String phaseText = '';
    Color phaseColor = Colors.white;
    IconData phaseIcon = Icons.air;

    switch (_currentPhase) {
      case BreathPhase.inhale:
        phaseText = 'Breathe In (4s)';
        phaseColor = Colors.lightBlueAccent;
        phaseIcon = Icons.arrow_upward_rounded;
        break;
      case BreathPhase.exhale:
        phaseText = 'Breathe Out (6s)';
        phaseColor = Colors.greenAccent;
        phaseIcon = Icons.arrow_downward_rounded;
        break;
      case BreathPhase.paused:
      case BreathPhase.completed:
        phaseText = '';
        phaseColor = Colors.white;
        phaseIcon = Icons.play_arrow_rounded;
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 48.h),
      child: AnimatedOpacity(
        opacity:
            _currentPhase == BreathPhase.paused ||
                _currentPhase == BreathPhase.completed
            ? 0.0
            : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: phaseColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: phaseColor.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(phaseIcon, color: phaseColor, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                phaseText,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: phaseColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
