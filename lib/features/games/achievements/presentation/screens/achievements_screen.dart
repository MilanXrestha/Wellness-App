// screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/resources/colors.dart';
import '../../../game_hub/data/services/game_service.dart';

class AchievementScreen extends StatefulWidget {
  final String userId;

  const AchievementScreen({super.key, required this.userId});

  @override
  _AchievementScreenState createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  final GameService _gameService = GameService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _unlockedAchievements = [];
  Map<String, List<Map<String, dynamic>>> _groupedAchievements = {};
  List<Map<String, dynamic>> _allAchievements = [];

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all achievements the user has unlocked
      final unlockedAchievements = await _gameService.getUserAchievements(
        widget.userId,
      );

      // Get all available achievements (including locked ones)
      final allAchievements = await _gameService.getAllAchievements();

      // Create a set of unlocked achievement IDs for quick lookup
      final unlockedIds = unlockedAchievements
          .map((a) => a['achievementId'] as String)
          .toSet();

      // Group achievements by game
      final groupedAchievements = <String, List<Map<String, dynamic>>>{};

      for (var achievement in allAchievements) {
        final gameId = achievement['gameId'] as String;

        if (!groupedAchievements.containsKey(gameId)) {
          groupedAchievements[gameId] = [];
        }

        // Add "unlocked" field to each achievement
        achievement['unlocked'] = unlockedIds.contains(achievement['id']);
        groupedAchievements[gameId]!.add(achievement);
      }

      setState(() {
        _unlockedAchievements = unlockedAchievements;
        _groupedAchievements = groupedAchievements;
        _allAchievements = allAchievements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load achievements'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Achievements',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
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
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _buildAchievementsList(isDarkMode),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildAchievementsList(bool isDarkMode) {
    if (_allAchievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64.sp,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
            SizedBox(height: 16.h),
            Text(
              'No achievements available yet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    // First, show unlocked achievements summary
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressSection(isDarkMode),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'All Achievements',
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
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: 16.h),
            children: _groupedAchievements.entries.map((entry) {
              return _buildGameAchievementsSection(
                entry.key,
                entry.value,
                isDarkMode,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(bool isDarkMode) {
    // Calculate total achievements and completion percentage
    final totalAchievements = _allAchievements.length;
    final unlockedCount = _unlockedAchievements.length;
    final completionPercentage = totalAchievements > 0
        ? (unlockedCount / totalAchievements * 100).round()
        : 0;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'Your Progress',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unlockedCount / $totalAchievements',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Achievements Unlocked',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? AppColors.darkSurface : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70.w,
                      height: 70.w,
                      child: CircularProgressIndicator(
                        value: completionPercentage / 100,
                        strokeWidth: 8.w,
                        backgroundColor: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '$completionPercentage%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameAchievementsSection(
    String gameId,
    List<Map<String, dynamic>> achievements,
    bool isDarkMode,
  ) {
    // Get game title based on gameId
    String gameTitle = 'Game';
    switch (gameId) {
      case 'breathing_game':
        gameTitle = 'Mindful Breathing';
        break;
      case 'affirmation_builder':
        gameTitle = 'Affirmation Builder';
        break;
      case 'wellness_quiz':
        gameTitle = 'Wellness Trivia';
        break;
      case 'global':
        gameTitle = 'General Wellness';
        break;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: _getGameColor(gameId).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getGameIcon(gameId),
                    color: _getGameColor(gameId),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  gameTitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildAchievementItem(achievement, isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  Color _getGameColor(String gameId) {
    switch (gameId) {
      case 'breathing_game':
        return Colors.blue;
      case 'stress_relief_tap':
        return Colors.green;
      case 'wellness_quiz':
        return Colors.orange;
      case 'global':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getGameIcon(String gameId) {
    switch (gameId) {
      case 'breathing_game':
        return Icons.air;
      case 'stress_relief_tap':
        return Icons.touch_app;
      case 'wellness_quiz':
        return Icons.quiz;
      case 'global':
        return Icons.favorite;
      default:
        return Icons.emoji_events;
    }
  }

  Widget _buildAchievementItem(
    Map<String, dynamic> achievement,
    bool isDarkMode,
  ) {
    final bool isUnlocked = achievement['unlocked'] ?? false;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.amber.withOpacity(0.2)
                  : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              color: isUnlocked ? Colors.amber : Colors.grey,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'] ?? 'Achievement',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    decoration: isUnlocked
                        ? TextDecoration.none
                        : TextDecoration.none,
                  ),
                ),
                Text(
                  achievement['description'] ?? '',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.sp,
                    color: isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                if (isUnlocked) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Unlocked',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.sp,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        color: isDarkMode ? Colors.grey : Colors.grey.shade600,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Locked',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.sp,
                          color: isDarkMode
                              ? Colors.grey
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isUnlocked)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '+${achievement['pointsAwarded'] ?? 0}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
