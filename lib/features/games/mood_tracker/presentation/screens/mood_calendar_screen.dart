// screens/mood_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../../core/resources/colors.dart';
import '../../../game_hub/data/services/game_service.dart';
import '../../data/models/mood_entry_model.dart';

class MoodCalendarScreen extends StatefulWidget {
  final String userId;

  const MoodCalendarScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MoodCalendarScreenState createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends State<MoodCalendarScreen> with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late AnimationController _animController;
  final ScrollController _scrollController = ScrollController();

  // Map to store mood entries by date
  Map<DateTime, MoodEntryModel> _moodEntries = {};
  bool _isLoading = true;

  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadMoodEntries();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoodEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all mood entries for the user
      final entries = await _gameService.getUserMoodEntries(
        widget.userId,
        limit: 100,
      );

      // Create a map of entries by date
      final Map<DateTime, MoodEntryModel> entriesByDate = {};
      for (var entry in entries) {
        // Remove time component to match calendar dates
        final date = DateTime(
          entry.timestamp.year,
          entry.timestamp.month,
          entry.timestamp.day,
        );
        entriesByDate[date] = entry;
      }

      setState(() {
        _moodEntries = entriesByDate;
        _isLoading = false;
      });

      _animController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load mood entries'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Method to save updated note
  Future<void> _saveNote(String note, MoodEntryModel entry) async {
    try {
      // Create a new entry with the updated note
      await _gameService.saveMoodEntry(
        userId: widget.userId,
        mood: entry.mood,
        note: note,
      );

      // Reload entries to refresh the data
      await _loadMoodEntries();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note updated successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update note: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Show dialog to edit note
  void _showEditNoteDialog(MoodEntryModel entry) {
    final TextEditingController _noteController = TextEditingController(text: entry.note);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          'Edit Note',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: TextField(
          controller: _noteController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter your thoughts...',
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              color: isDarkMode ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.black12 : Colors.white,
            border: OutlineInputBorder(
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
            fontSize: 16.sp,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveNote(_noteController.text, entry);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
          'Mood Calendar',
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
            ? _buildLoadingState(isDarkMode)
            : AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _animController,
              child: child,
            );
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                _buildCalendarHeader(isDarkMode),
                _buildCalendar(isDarkMode),
                SizedBox(height: 16.h),
                _buildSelectedDayInfo(isDarkMode),
                // Add some bottom padding to ensure we can scroll to see everything
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading your mood history...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.MMMM().format(_focusedDay),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                DateFormat.y().format(_focusedDay),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Today button with tooltip
              Tooltip(
                message: 'Go to today',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40.r),
                    onTap: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDay = DateTime.now();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Refresh button with tooltip
              Tooltip(
                message: 'Refresh entries',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40.r),
                    onTap: _loadMoodEntries,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            // No auto-scrolling here - removed to fix the issue
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            weekendTextStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            todayTextStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            selectedTextStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            markerDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          headerVisible: false,
          daysOfWeekStyle: DaysOfWeekStyle(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black12
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            weekdayStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            weekendStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, _) {
              // Check if this date has a mood entry
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final entry = _moodEntries[normalizedDate];

              if (entry != null) {
                return Container(
                  margin: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      entry.mood,
                      style: TextStyle(
                        fontSize: 22.sp,
                      ),
                    ),
                  ),
                );
              }

              // Return just the date number for days without mood entries
              return Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.sp,
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              );
            },

            todayBuilder: (context, date, _) {
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final entry = _moodEntries[normalizedDate];

              return Container(
                margin: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: entry != null
                      ? Text(
                    entry.mood,
                    style: TextStyle(
                      fontSize: 22.sp,
                    ),
                  )
                      : Text(
                    '${date.day}',
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
              );
            },

            selectedBuilder: (context, date, _) {
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final entry = _moodEntries[normalizedDate];

              return Container(
                margin: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: entry != null
                      ? Text(
                    entry.mood,
                    style: TextStyle(
                      fontSize: 22.sp,
                    ),
                  )
                      : Text(
                    '${date.day}',
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayInfo(bool isDarkMode) {
    final normalizedSelectedDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    final entry = _moodEntries[normalizedSelectedDay];

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      padding: EdgeInsets.all(20.w),
      // Give it a fixed height rather than Expanded
      height: 300.h,
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: entry == null
          ? _buildEmptyDayInfo(isDarkMode)
          : _buildMoodDayInfo(entry, isDarkMode),
    );
  }

  Widget _buildEmptyDayInfo(bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mood,
          size: 48.sp,
          color: isDarkMode
              ? AppColors.darkTextSecondary.withOpacity(0.3)
              : AppColors.lightTextSecondary.withOpacity(0.3),
        ),
        SizedBox(height: 16.h),
        Text(
          'No mood recorded for this day',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16.sp,
            color: isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'Return to the main screen to record how you\'re feeling today',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.sp,
            color: isDarkMode
                ? AppColors.darkTextSecondary.withOpacity(0.7)
                : AppColors.lightTextSecondary.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMoodDayInfo(MoodEntryModel entry, bool isDarkMode) {
    final formattedDate = DateFormat.yMMMMd().format(entry.timestamp);
    final formattedTime = DateFormat.jm().format(entry.timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  entry.mood,
                  style: TextStyle(fontSize: 32.sp),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    formattedTime,
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
            ),
            // Edit button
            IconButton(
              icon: Icon(
                Icons.edit,
                color: AppColors.primary,
                size: 22.sp,
              ),
              onPressed: () => _showEditNoteDialog(entry),
              tooltip: 'Edit note',
            ),
          ],
        ),

        SizedBox(height: 12.h),
        Divider(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          thickness: 1,
        ),
        SizedBox(height: 8.h),

        // Note section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notes:',
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
        SizedBox(height: 8.h),

        // Note content or empty note message
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black12
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: entry.note != null && entry.note!.isNotEmpty
                ? SingleChildScrollView(
              child: Text(
                entry.note!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  height: 1.5,
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No notes for this mood entry',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      fontStyle: FontStyle.italic,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () => _showEditNoteDialog(entry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Add Note',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}