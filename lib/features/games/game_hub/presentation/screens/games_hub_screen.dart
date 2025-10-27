// screens/games_hub_screen.dart
import 'dart:developer';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/resources/colors.dart';
import '../../../achievements/presentation/screens/achievements_screen.dart';
import '../../../affirmation_builder/presentation/screens/affirmation_builder_screen.dart';
import '../../../breathing_game/presentation/screens/breathing_game_screen.dart';
import '../../../mood_tracker/presentation/widgets/mood_tracker_widget.dart';
import '../../../wellness_trivia/presentation/screens/wellness_quiz_screen.dart';
import '../../data/models/game_model.dart';
import '../../data/services/game_service.dart';

class GamesHubScreen extends StatefulWidget {
  final String userId;

  const GamesHubScreen({super.key, required this.userId});

  @override
  GamesHubScreenState createState() => GamesHubScreenState();
}

class GamesHubScreenState extends State<GamesHubScreen>
    with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  List<GameModel> _games = [];
  bool _isLoading = true;
  int _currentGameIndex = 0;
  final CarouselSliderController _carouselController =
  CarouselSliderController();
  Map<String, dynamic>? _cachedUserStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _initializeGamesAndLoad();
    _loadUserStats(); // Load stats once when screen initializes
  }

  Future<void> _initializeGamesAndLoad() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize default games first
      await _gameService.initializeDefaultGames();
      log('Default games initialized', name: 'GamesHubScreen');

      // Then fetch games from Firestore
      final games = await _gameService.getGames();
      log('Fetched ${games.length} games', name: 'GamesHubScreen');

      // Also refresh stats
      _cachedUserStats = null;
      await _loadUserStats();

      // To avoid shimmering effect, only update state once all data is loaded
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error initializing/loading games: $e', name: 'GamesHubScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserStats() async {
    if (_cachedUserStats != null) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Get user's wellness points from user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      final wellnessPoints = userDoc.data()?['wellnessPoints'] ?? 0;

      // Get user's achievements
      final achievements = await _gameService.getUserAchievements(
        widget.userId,
      );

      // Get user's game progress
      final progress = await _gameService.getUserProgress(widget.userId);

      // Calculate total games played
      int totalPlays = 0;
      for (final gameProgress in progress) {
        totalPlays += gameProgress.totalPlays;
      }

      _cachedUserStats = {
        'points': wellnessPoints,
        'achievements': achievements.length,
        'gamesPlayed': totalPlays,
      };

      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      log('Error fetching user stats: $e', name: 'GamesHubScreen');
      _cachedUserStats = {'points': 0, 'achievements': 0, 'gamesPlayed': 0};

      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  // New method to refresh only user stats without reloading everything
  Future<void> _refreshUserStats() async {
    try {
      final stats = await _getUserStats();

      if (mounted) {
        setState(() {
          _cachedUserStats = stats;
        });
      }
    } catch (e) {
      log('Error refreshing user stats: $e', name: 'GamesHubScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Wellness Hub',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: isDarkMode
            ? AppColors.darkBackground.withOpacity(0.85)
            : AppColors.lightBackground.withOpacity(0.85),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDarkMode
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.lightBackground, AppColors.lightSurface],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _initializeGamesAndLoad,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  _buildStatsRow(isDarkMode),
                  SizedBox(height: 24.h),

                  // Current Mood title and widget
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'Current Mood',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: MoodTrackerWidget(userId: widget.userId),
                  ),
                  SizedBox(height: 24.h),

                  // Games section title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'Choose a Game',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Games carousel or loading/empty states
                  _isLoading
                      ? _buildShimmerCarousel(isDarkMode)
                      : _games.isEmpty
                      ? _buildEmptyState()
                      : _buildGamesCarousel(isDarkMode),

                  // Extra space at the bottom to ensure nothing is cut off
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: _isLoadingStats
          ? _buildStatsShimmer(isDarkMode)
          : Row(
        children: [
          // Points Card
          Expanded(
            flex: 3,
            child: _buildStatCard(
              title: 'Wellness Points',
              value: _cachedUserStats!['points'].toString(),
              icon: Icons.stars_rounded,
              color: Colors.amber,
              isDarkMode: isDarkMode,
            ),
          ),
          SizedBox(width: 12.w),
          // Achievements Card (Clickable)
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AchievementScreen(userId: widget.userId),
                ),
              ).then((_) => _refreshUserStats()), // Refresh stats when returning
              child: _buildStatCard(
                title: 'Achievements',
                value: _cachedUserStats!['achievements'].toString(),
                icon: Icons.emoji_events_rounded,
                color: Colors.deepPurpleAccent,
                isDarkMode: isDarkMode,
                isClickable: true,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Games Played Card
          Expanded(
            flex: 3,
            child: _buildStatCard(
              title: 'Games Played ',
              value: _cachedUserStats!['gamesPlayed'].toString(),
              icon: Icons.sports_esports_rounded,
              color: Colors.greenAccent,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
    bool isClickable = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isClickable
            ? Border.all(color: color.withOpacity(0.3), width: 2.w)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22.sp, color: color),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.sp,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          if (isClickable) ...[
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.sp,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 8.sp, color: color),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Row(
        children: List.generate(
          3,
              (index) => Expanded(
            flex: index == 1 ? 4 : 3, // Middle card is slightly wider
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.white, // Required for Shimmer
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCarousel(bool isDarkMode) {
    return SizedBox(
      height: 450.h,
      child: Column(
        children: [
          // Carousel shimmer
          SizedBox(
            height: 370.h,
            child: Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 50.w),
                decoration: BoxDecoration(
                  color: Colors.white, // Required for Shimmer
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),
          ),

          // Fake indicator dots
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3, // Simulate 3 dots
                  (index) => Container(
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 250.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 64.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'No games available yet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Check back soon for new wellness games!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _initializeGamesAndLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesCarousel(bool isDarkMode) {
    return SizedBox(
      height: 450.h, // Increased height to fix overflow
      child: Column(
        children: [
          // Carousel for the games - with increased height
          SizedBox(
            height: 370.h, // Increased height to make cards bigger
            child: CarouselSlider.builder(
              itemCount: _games.length,
              carouselController: _carouselController,
              options: CarouselOptions(
                height: 370.h,
                // Explicitly set height
                viewportFraction: 0.7,
                // Increased from 0.75 to show more of the card
                enlargeCenterPage: true,
                enableInfiniteScroll: _games.length > 1,
                // Only enable infinite scroll if multiple games
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                // Setting these parameters for smoother scrolling
                scrollPhysics: BouncingScrollPhysics(),
                autoPlay: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentGameIndex = index;
                  });
                },
              ),
              itemBuilder: (context, index, realIndex) {
                final game = _games[index];
                final isActive = index == _currentGameIndex;

                // Wrapped in RepaintBoundary for better performance
                return RepaintBoundary(
                  child: AnimatedScale(
                    scale: isActive ? 1.0 : 0.85,
                    duration: Duration(milliseconds: 300),
                    child: _buildGameCard(game, isDarkMode, isActive),
                  ),
                );
              },
            ),
          ),

          // Carousel indicator dots
          SizedBox(height: 8.h), // Reduced spacing
          if (_games.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _games.asMap().entries.map((entry) {
                return Container(
                  width: 8.w,
                  height: 8.w,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentGameIndex == entry.key
                        ? AppColors.primary
                        : (isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade300),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameModel game, bool isDarkMode, bool isActive) {
    // Define color based on game type
    Color gameColor;
    switch (game.type) {
      case 'breathing':
        gameColor = Colors.blue;
        break;
      case 'tap':
        gameColor = Colors.green;
        break;
      case 'quiz':
        gameColor = Colors.orange;
        break;
      default:
        gameColor = Colors.purple;
    }

    return GestureDetector(
      onTap: () => _launchGame(game),
      child: Hero(
        tag: 'game_${game.id}', // Hero tag for smooth transition
        child: Material(
          type: MaterialType.transparency,
          // Required for Hero animation with text
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: gameColor.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Stack(
                children: [
                  // Background gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            gameColor.withOpacity(0.05),
                            gameColor.withOpacity(0.15),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Game animation/image - increased size
                      Expanded(
                        flex: 5,
                        child: Container(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 200.w,
                            height: 200.w,
                            child: Lottie.asset(
                              game.animationPath,
                              frameRate: FrameRate(30),
                              fit: BoxFit.contain,
                              animate: isActive, // Only animate when this card is selected
                            ),
                          ),
                        ),
                      ),

                      // Game info
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.white.withOpacity(0.9),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.title,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20.sp, // Increased from 18.sp
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                game.description,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                  color: isDarkMode
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Spacer(),
                              SizedBox(
                                width: double.infinity,
                                // Make button full width
                                child: ElevatedButton(
                                  onPressed: () => _launchGame(game),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: gameColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 14.h, // Increased padding
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    // Center the content
                                    children: [
                                      Icon(Icons.play_arrow, size: 22.sp),
                                      // Increased icon size
                                      SizedBox(width: 8.w),
                                      // Increased spacing
                                      Text(
                                        "Play Now",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16.sp,
                                          // Increased font size
                                          fontWeight: FontWeight.w500,
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getUserStats() async {
    try {
      // Get user's wellness points from user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      final wellnessPoints = userDoc.data()?['wellnessPoints'] ?? 0;

      // Get user's achievements
      final achievements = await _gameService.getUserAchievements(
        widget.userId,
      );

      // Get user's game progress
      final progress = await _gameService.getUserProgress(widget.userId);

      // Calculate total games played
      int totalPlays = 0;
      for (final gameProgress in progress) {
        totalPlays += gameProgress.totalPlays;
      }

      return {
        'points': wellnessPoints,
        'achievements': achievements.length,
        'gamesPlayed': totalPlays,
      };
    } catch (e) {
      log('Error fetching user stats: $e', name: 'GamesHubScreen');
      return {'points': 0, 'achievements': 0, 'gamesPlayed': 0};
    }
  }

  Future<Map<String, dynamic>> _getGameStats(String gameId) async {
    try {
      final progress = await _gameService.getUserGameProgress(
        widget.userId,
        gameId,
      );

      if (progress == null) {
        return {'hasPlayed': false, 'highScore': 0, 'totalPlays': 0};
      }

      return {
        'hasPlayed': true,
        'highScore': progress.highScore,
        'totalPlays': progress.totalPlays,
      };
    } catch (e) {
      log('Error fetching game stats: $e', name: 'GamesHubScreen');
      return {'hasPlayed': false, 'highScore': 0, 'totalPlays': 0};
    }
  }

  void _launchGame(GameModel game) {
    Widget gameScreen;

    switch (game.type) {
      case 'breathing':
        gameScreen = BreathingGameScreen(
          userId: widget.userId,
          gameId: game.id,
          gameConfig: game.config,
        );
        break;
      case 'quiz':
        gameScreen = WellnessQuizScreen(
          userId: widget.userId,
          gameId: game.id,
          gameConfig: game.config,
        );
        break;
      case 'word_puzzle':
        gameScreen = AffirmationBuilderScreen(
          userId: widget.userId,
          gameId: game.id,
          gameConfig: game.config,
        );
        break;
      default:
        gameScreen = Scaffold(
          appBar: AppBar(title: Text('Coming Soon')),
          body: Center(child: Text('Game Coming Soon')),
        );
    }

    // Launch the game and refresh stats when returning
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return gameScreen;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.1);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ).then((_) {
      // Refresh stats when returning from game
      _refreshUserStats();
    });
  }
}