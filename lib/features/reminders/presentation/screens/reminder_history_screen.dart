import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/reminders/data/models/reminder_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import 'package:wellness_app/features/notifications/data/services/notification_service.dart';
import '../../../../core/db/database_helper.dart';
import 'reminder_screen.dart';

class ReminderHistoryScreen extends StatefulWidget {
  const ReminderHistoryScreen({super.key});

  @override
  _ReminderHistoryScreenState createState() => _ReminderHistoryScreenState();
}

class _ReminderHistoryScreenState extends State<ReminderHistoryScreen> {
  List<ReminderModel> reminders = [];
  Map<String, String> categoryNames = {};
  bool isLoading = true;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Check online status
      isOffline = !(await DataRepository.instance.isOnline());

      await Future.wait([
        _fetchReminders(),
        _fetchCategories(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchReminders() async {
    try {
      final userId = AuthService().getCurrentUser()?.uid;
      if (userId != null) {
        log('Fetching reminders for user ID: $userId');

        // Clear existing reminders
        setState(() {
          reminders.clear();
        });

        // First, try to get reminders directly from Firestore
        try {
          log('Querying Firestore for reminders');
          final snapshot = await FirebaseFirestore.instance
              .collection('reminders')
              .where('userId', isEqualTo: userId)
              .get();

          log('Firestore returned ${snapshot.docs.length} reminders');

          if (snapshot.docs.isNotEmpty) {
            final firestoreReminders = snapshot.docs
                .map((doc) => ReminderModel.fromFirestore(doc.data(), doc.id))
                .toList();

            // Add to local state
            setState(() {
              reminders.addAll(firestoreReminders);
            });

            // Also update local database
            for (var reminder in firestoreReminders) {
              await DatabaseHelper.instance.insertReminder(reminder);
            }
          }
        } catch (e) {
          log('Error fetching from Firestore: $e');
        }

        // If no reminders from Firestore or if there was an error, try local database
        if (reminders.isEmpty) {
          log('Falling back to local database');
          final localReminders = await DatabaseHelper.instance.getRemindersByUser(userId);
          log('Local database returned ${localReminders.length} reminders');

          setState(() {
            reminders.addAll(localReminders);
          });
        }

        log('Total reminders found: ${reminders.length}');
      } else {
        log('No user ID available');
      }
    } catch (e) {
      log('Error in _fetchReminders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching reminders: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _fetchCategories() async {
    try {
      // First try local database
      final categories = await DataRepository.instance.getCategories();
      final categoryMap = {
        for (var category in categories)
          category.categoryId: category.categoryName
      };

      // If we're online, also try Firestore for any new categories
      if (!isOffline) {
        final snapshot = await FirebaseFirestore.instance.collection('categories').get();
        for (var doc in snapshot.docs) {
          final category = CategoryModel.fromFirestore(doc.data(), doc.id);
          categoryMap[category.categoryId] = category.categoryName;
        }
      }

      if (mounted) {
        setState(() {
          categoryNames = categoryMap;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching categories: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteReminder(ReminderModel reminder) async {
    try {
      // First cancel the notification
      await NotificationService.instance.cancelReminderNotification(reminder.id);

      // Then delete the reminder from the database
      await DataRepository.instance.deleteReminder(reminder.id);

      if (mounted) {
        setState(() {
          reminders.removeWhere((r) => r.id == reminder.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reminder deleted successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting reminder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Get an icon based on reminder type
  IconData _getReminderTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.headphones;
      case 'image':
        return Icons.image;
      case 'quote':
        return Icons.format_quote;
      case 'healthtips':
        return Icons.medical_services;
      case 'tip':
        return Icons.lightbulb;
      case 'all':
        return Icons.apps;
      default:
        return Icons.schedule;
    }
  }

  // Get a color based on reminder type
  Color _getReminderTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Colors.red[400]!;
      case 'audio':
        return Colors.purple[400]!;
      case 'image':
        return Colors.blue[400]!;
      case 'quote':
        return Colors.amber[400]!;
      case 'healthtips':
        return Colors.green[400]!;
      case 'all':
        return Colors.teal[400]!;
      default:
        return AppColors.primary;
    }
  }

  void _viewReminder(ReminderModel reminder) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [AppColors.darkSurface, AppColors.darkBackground]
                  : [AppColors.lightSurface, AppColors.lightBackground],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDarkMode ? AppColors.darkTextHint : AppColors.lightTextHint,
              width: 1.w,
            ),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getReminderTypeColor(reminder.type).withOpacity(0.1),
                    ),
                    child: Icon(
                      _getReminderTypeIcon(reminder.type),
                      color: _getReminderTypeColor(reminder.type),
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Reminder Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                'Type: ${StringExtension(reminder.type).capitalize()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14.sp,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Category: ${categoryNames[reminder.categoryId] ?? (reminder.categoryId == 'all' ? 'All Categories' : 'Unknown')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14.sp,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Frequency: ${StringExtension(reminder.frequency).capitalize()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14.sp,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Time: ${reminder.time}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14.sp,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              if (reminder.frequency == 'weekly' && reminder.dayOfWeek != null) ...[
                SizedBox(height: 8.h),
                Text(
                  'Day: ${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][reminder.dayOfWeek! - 1]}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
              SizedBox(height: 8.h),
              Text(
                'Created: ${reminder.createdAt.toString().substring(0, 16)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14.sp,
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _editReminder(reminder);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.1,
          end: 0.0,
          duration: 300.ms,
        ),
      ),
    );
  }

  void _editReminder(ReminderModel reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderScreen(reminder: reminder),
      ),
    ).then((_) => _fetchReminders());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Reminder History',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          actions: [
            if (isOffline)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Icon(
                  Icons.cloud_off,
                  color: Colors.orange,
                  size: 20.sp,
                ),
              ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              onPressed: _fetchData,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReminderScreen()),
              ).then((_) => _fetchReminders()),
              tooltip: 'Add Reminder',
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : reminders.isEmpty
            ? RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.primary,
          child: ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height / 3),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48.sp,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary.withOpacity(0.5)
                          : AppColors.lightTextSecondary.withOpacity(0.5),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No reminders found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16.sp,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReminderScreen()),
                      ).then((_) => _fetchReminders()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Create Reminder',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.primary,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Dismissible(
                key: Key(reminder.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.w),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      title: Text(
                        'Delete Reminder',
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to delete this reminder?',
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.accentBlue),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await _deleteReminder(reminder);
                },
                child: Animate(
                  effects: [
                    FadeEffect(duration: 300.ms, delay: (index * 100).ms),
                    SlideEffect(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                      duration: 300.ms,
                      delay: (index * 100).ms,
                    ),
                  ],
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                      elevation: 6,
                      shadowColor: AppColors.shadow,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode
                                ? [AppColors.darkSurface, AppColors.darkBackground]
                                : [AppColors.lightSurface, AppColors.lightBackground],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isDarkMode
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                            width: 1.w,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.r),
                          onTap: () => _viewReminder(reminder),
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getReminderTypeColor(reminder.type).withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    _getReminderTypeIcon(reminder.type),
                                    color: _getReminderTypeColor(reminder.type),
                                    size: 24.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${StringExtension(reminder.type).capitalize()} Reminder',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Category: ${categoryNames[reminder.categoryId] ?? (reminder.categoryId == 'all' ? 'All Categories' : 'Unknown')}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 14.sp,
                                          color: isDarkMode
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Time: ${reminder.time}${reminder.frequency == 'weekly' && reminder.dayOfWeek != null ? ' (${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][reminder.dayOfWeek! - 1]})' : ''}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 14.sp,
                                          color: isDarkMode
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        children: [
                                          Text(
                                            'Created: ${reminder.createdAt.toString().substring(0, 10)}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontSize: 12.sp,
                                              color: isDarkMode
                                                  ? AppColors.darkTextSecondary.withOpacity(0.7)
                                                  : AppColors.lightTextSecondary.withOpacity(0.7),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: reminder.notificationId != null
                                                  ? Colors.green.withOpacity(0.2)
                                                  : Colors.orange.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              reminder.notificationId != null ? 'Active' : 'Pending',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: reminder.notificationId != null
                                                    ? Colors.green
                                                    : Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: isDarkMode
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    size: 20.sp,
                                  ),
                                  onPressed: () => _editReminder(reminder),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}