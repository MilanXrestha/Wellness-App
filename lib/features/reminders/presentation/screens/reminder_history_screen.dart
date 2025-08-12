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
import 'reminder_screen.dart';

class ReminderHistoryScreen extends StatefulWidget {
  const ReminderHistoryScreen({super.key});

  @override
  _ReminderHistoryScreenState createState() => _ReminderHistoryScreenState();
}

class _ReminderHistoryScreenState extends State<ReminderHistoryScreen> {
  List<ReminderModel> reminders = [];
  Map<String, String> categoryNames = {};

  @override
  void initState() {
    super.initState();
    _fetchReminders();
    _fetchCategories();
  }

  Future<void> _fetchReminders() async {
    try {
      final userId = AuthService().getCurrentUser()?.uid;
      if (userId != null) {
        final fetchedReminders = await DataRepository.instance.getReminders(userId);
        setState(() {
          reminders = fetchedReminders;
        });
      }
    } catch (e) {
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
      final snapshot = await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        categoryNames = {
          for (var doc in snapshot.docs)
            doc.id: CategoryModel.fromFirestore(doc.data(), doc.id).categoryName
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching categories: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteReminder(ReminderModel reminder) async {
    try {
      await DataRepository.instance.deleteReminder(reminder.id);
      await NotificationService.instance.cancelReminderNotification(reminder.id);
      setState(() {
        reminders.removeWhere((r) => r.id == reminder.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reminder deleted successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting reminder: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: AppColors.primary,
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
                'Category: ${categoryNames[reminder.categoryId] ?? 'Unknown'}',
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
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
            IconButton(
              icon: Icon(
                Icons.add,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReminderScreen()),
              ).then((_) => _fetchReminders()),
            ),
          ],
        ),
        body: reminders.isEmpty
            ? Center(
          child: Text(
            'No reminders found',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16.sp,
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        )
            : ListView.builder(
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
                          color: isDarkMode ? AppColors.darkTextHint : AppColors.lightTextHint,
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
                                  color: AppColors.primary.withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.schedule,
                                  color: AppColors.primary,
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
                                      'Category: ${categoryNames[reminder.categoryId] ?? 'Unknown'}',
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
                                    Text(
                                      'Created: ${reminder.createdAt.toString().substring(0, 16)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 12.sp,
                                        color: isDarkMode
                                            ? AppColors.darkTextSecondary.withOpacity(0.7)
                                            : AppColors.lightTextSecondary.withOpacity(0.7),
                                      ),
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
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}