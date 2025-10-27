// widgets/mood_tracker_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/resources/colors.dart';
import '../../../game_hub/data/services/game_service.dart';
import '../../data/models/mood_entry_model.dart';

import '../screens/mood_calendar_screen.dart';

class MoodTrackerWidget extends StatefulWidget {
  final String userId;

  const MoodTrackerWidget({Key? key, required this.userId}) : super(key: key);

  @override
  _MoodTrackerWidgetState createState() => _MoodTrackerWidgetState();
}

class _MoodTrackerWidgetState extends State<MoodTrackerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GameService _gameService = GameService();
  String? _selectedMood;
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  // Define available moods
  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😄', 'label': 'Happy', 'color': Colors.yellow},
    {'emoji': '😊', 'label': 'Good', 'color': Colors.lightGreen},
    {'emoji': '😐', 'label': 'Okay', 'color': Colors.lightBlue},
    {'emoji': '😔', 'label': 'Sad', 'color': Colors.blueGrey},
    {'emoji': '😫', 'label': 'Stressed', 'color': Colors.orange},
    {'emoji': '😴', 'label': 'Tired', 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMoodEntry() async {
    if (_selectedMood == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _gameService.saveMoodEntry(
        userId: widget.userId,
        mood: _selectedMood!,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      // Reset form
      setState(() {
        _selectedMood = null;
        _noteController.clear();
        _isSubmitting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mood saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save mood: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with proper spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'How are you feeling today?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              // Using SizedBox with fixed width for the icon to prevent overflow
              SizedBox(
                width: 40.w,
                child: IconButton(
                  icon: Icon(
                    Icons.calendar_month_rounded,
                    color: isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    size: 22.sp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MoodCalendarScreen(userId: widget.userId),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Emoji row with SingleChildScrollView
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood['emoji'];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = isSelected ? null : mood['emoji'];
                      });

                      if (_selectedMood != null) {
                        _animationController.forward(from: 0.0);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(isSelected ? 12.w : 8.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mood['color'].withOpacity(isDarkMode ? 0.3 : 0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? mood['color'] : Colors.transparent,
                          width: 2.w,
                        ),
                      ),
                      child: Text(
                        mood['emoji'],
                        style: TextStyle(
                            fontSize: isSelected ? 28.sp : 24.sp),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 16.h),

          if (_selectedMood != null)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _animationController.value,
                  child: SizeTransition(
                    sizeFactor: _animationController,
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a note (optional):',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'What\'s on your mind?',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        color: isDarkMode
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.black12 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveMoodEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2.w,
                        ),
                      )
                          : Text(
                        'Save Mood',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showMoodHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMoodHistorySheet(context),
    );
  }

  Widget _buildMoodHistorySheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mood History',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Stats section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _gameService.getUserMoodStats(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final stats =
                        snapshot.data ??
                            {
                              'entryCount': 0,
                              'moodCounts': <String, int>{},
                              'mostFrequentMood': null,
                            };

                    return Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Past 7 Days',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn(
                                'Entries',
                                stats['entryCount'].toString(),
                                Icons.calendar_today,
                                isDarkMode,
                              ),
                              if (stats['mostFrequentMood'] != null)
                                _buildStatColumn(
                                  'Most Frequent',
                                  stats['mostFrequentMood'],
                                  Icons.favorite,
                                  isDarkMode,
                                  isEmoji: true,
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // History list
              Expanded(
                child: FutureBuilder<List<MoodEntryModel>>(
                  future: _gameService.getUserMoodEntries(
                    widget.userId,
                    limit: 20,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final entries = snapshot.data ?? [];

                    if (entries.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mood,
                              size: 48.sp,
                              color: isDarkMode
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No mood entries yet',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16.sp,
                                color: isDarkMode
                                    ? Colors.white38
                                    : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 8.h,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _buildMoodEntryItem(entry, isDarkMode);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(
      String label,
      String value,
      IconData icon,
      bool isDarkMode, {
        bool isEmoji = false,
      }) {
    return Column(
      children: [
        isEmoji
            ? Text(value, style: TextStyle(fontSize: 24.sp))
            : Icon(icon, size: 24.sp, color: AppColors.primary),
        SizedBox(height: 8.h),
        Text(
          isEmoji ? 'Most Frequent' : label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.sp,
            color: isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        if (!isEmoji)
          Text(
            value,
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
    );
  }

  Widget _buildMoodEntryItem(MoodEntryModel entry, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Row(
            children: [
              Text(entry.mood, style: TextStyle(fontSize: 24.sp)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(entry.timestamp),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      _formatTime(entry.timestamp),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.sp,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Divider(color: isDarkMode ? Colors.white12 : Colors.black12),
            SizedBox(height: 8.h),
            Text(
              entry.note!,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                color: isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}