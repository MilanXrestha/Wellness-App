import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/reminders/data/models/reminder_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import 'package:wellness_app/features/notifications/data/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'reminder_history_screen.dart';

class ReminderScreen extends StatefulWidget {
  final ReminderModel? reminder;

  const ReminderScreen({super.key, this.reminder});

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  String? selectedType;
  String? selectedCategoryId;
  String? selectedFrequency;
  TimeOfDay? selectedTime;
  int? selectedDayOfWeek;
  List<CategoryModel> categories = [];
  List<TipModel> tips = [];
  bool isLoadingCategories = true;
  bool isSaving = false;
  bool includePremium = false;

  // Content type options with their display names
  final Map<String, String> contentTypes = {
    'tip': 'Wellness Tips',
    'quote': 'Daily Quotes',
    'audio': 'Audio Content',
    'video': 'Video Content',
    'image': 'Image Content',
    'healthTips': 'Health Tips',
    'all': 'All Content Types'
  };

  @override
  void initState() {
    super.initState();
    log('ReminderScreen initState: widget.reminder = ${widget.reminder}');
    _fetchCategoriesAndTips();
    if (widget.reminder != null) {
      log('Editing reminder with ID: ${widget.reminder!.id}');
      selectedType = widget.reminder!.type;
      selectedCategoryId = widget.reminder!.categoryId;
      selectedFrequency = widget.reminder!.frequency;
      final timeParts = widget.reminder!.time.split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      selectedDayOfWeek = widget.reminder!.dayOfWeek;
    } else {
      selectedType = null;
      selectedCategoryId = 'all';
      selectedFrequency = null;
      selectedTime = null;
      selectedDayOfWeek = null;
    }

    // Initialize notification service as early as possible
    NotificationService.instance.initLocalNotifications();
    NotificationService.instance.requestExactAlarmPermission();
  }

  Future<void> _fetchCategoriesAndTips() async {
    try {
      setState(() {
        isLoadingCategories = true;
      });
      final userId = AuthService().getCurrentUser()?.uid ?? '';

      // Check if user can access premium content
      final canAccessPremium = await DataRepository.instance.canAccessPremiumContent(userId);

      // Fetch categories and tips in parallel
      final results = await Future.wait([
        DataRepository.instance.getCategories(),
        DataRepository.instance.getTips(includePremium: canAccessPremium)
      ]);

      final fetchedCategories = results[0] as List<CategoryModel>;
      final fetchedTips = results[1] as List<TipModel>;

      log('Fetched ${fetchedCategories.length} categories and ${fetchedTips.length} tips');
      log('Tip types: ${fetchedTips.map((tip) => tip.tipsType).toSet().toList()}');

      setState(() {
        categories = fetchedCategories;
        tips = fetchedTips;
        includePremium = canAccessPremium;
        isLoadingCategories = false;

        // Validate selected category still exists
        if (selectedCategoryId != null &&
            selectedCategoryId != 'all' &&
            !categories.any((c) => c.categoryId == selectedCategoryId)) {
          selectedCategoryId = 'all';
          if (widget.reminder != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Selected category no longer exists. Reset to All.',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      });
    } catch (e, stackTrace) {
      log('Error fetching data: $e', stackTrace: stackTrace);
      setState(() {
        isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              hourMinuteTextColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              dialBackgroundColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              dayPeriodTextColor:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              entryModeIconColor: AppColors.accentBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _selectDayOfWeek(BuildContext context) async {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final int? selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        title: Text(
          'Select Day of Week',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: days.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final day = entry.value;
              return ListTile(
                title: Text(
                  day,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                trailing: selectedDayOfWeek == index
                    ? Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, index),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        selectedDayOfWeek = selected;
      });
    }
  }

  Future<bool> _validateReminderContent() async {
    if (selectedType == null || selectedCategoryId == null) {
      return false;
    }

    // For "all" category, no validation needed
    if (selectedCategoryId == 'all') {
      return true;
    }

    // For specific category, check if there are any tips of the selected type
    final filteredTips = tips.where((tip) =>
    tip.categoryId == selectedCategoryId &&
        (selectedType == 'all' || tip.tipsType == selectedType)
    ).toList();

    return filteredTips.isNotEmpty;
  }

  Future<bool> _isReminderInLocalCache(String reminderId) async {
    try {
      final reminder = await DataRepository.instance.getReminderById(reminderId);
      return reminder != null;
    } catch (e) {
      log('Error checking local cache for reminder $reminderId: $e');
      return false;
    }
  }

  Future<void> _saveReminder() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    final userId = AuthService().getCurrentUser()?.uid;
    if (userId == null ||
        selectedType == null ||
        selectedFrequency == null ||
        selectedTime == null ||
        (selectedFrequency == 'weekly' && selectedDayOfWeek == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fill all fields'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => isSaving = false);
      }
      return;
    }

    // Validate content availability
    final hasValidContent = await _validateReminderContent();
    if (!hasValidContent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No ${selectedType == 'all' ? 'content' : selectedType} available for the selected category.',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => isSaving = false);
      }
      return;
    }

    // Request exact alarm permission
    final exactAlarmPermitted = await NotificationService.instance.requestExactAlarmPermission();
    if (!exactAlarmPermitted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Exact alarm permission is required for reliable reminders',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => isSaving = false);
      }
      return;
    }

    // Create reminder object
    final reminder = ReminderModel(
      id: widget.reminder?.id ?? const Uuid().v4(),
      userId: userId,
      type: selectedType!,
      categoryId: selectedCategoryId ?? 'all',
      frequency: selectedFrequency!,
      time:
      '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
      dayOfWeek: selectedFrequency == 'weekly' ? selectedDayOfWeek : null,
      createdAt: widget.reminder?.createdAt ?? DateTime.now(),
      notificationId: widget.reminder?.notificationId,
    );

    bool saveSuccess = false;
    bool isOnline = false;

    // Show initial saving message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saving reminder...'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Check online status
    try {
      isOnline = await DataRepository.instance.isOnline();
      log('Online status: $isOnline');
    } catch (e) {
      log('Error checking online status: $e');
      isOnline = false;
    }

    try {
      // First save to local database
      if (widget.reminder != null) {
        await DataRepository.instance.updateReminder(reminder);
        log('Updated reminder in local database: ${reminder.id}');
      } else {
        await DataRepository.instance.addReminder(reminder);
        log('Added reminder to local database: ${reminder.id}');
      }

      // Cancel existing notification if updating
      if (widget.reminder != null && widget.reminder!.notificationId != null) {
        await NotificationService.instance.cancelReminderNotification(reminder.id);
        log('Cancelled existing notification for reminder: ${reminder.id}');
      }

      // Schedule notification
      try {
        await NotificationService.instance.scheduleReminderNotification(reminder);
        log('Successfully scheduled notification for reminder: ${reminder.id}');
      } catch (e) {
        log('Error scheduling notification, queuing for later: $e');
        await NotificationService.instance.queueNotification(reminder);
      }

      // Check if reminder was saved successfully in local database
      saveSuccess = await _isReminderInLocalCache(reminder.id);
      log('Reminder saved successfully in local database: $saveSuccess');

    } catch (e, stackTrace) {
      log('Error saving reminder: $e', stackTrace: stackTrace);
      saveSuccess = await _isReminderInLocalCache(reminder.id);
    }

    // Final snackbar and navigation
    if (mounted) {
      if (saveSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.reminder != null
                  ? 'Reminder updated successfully${isOnline ? '' : ' (offline)'}'
                  : 'Reminder saved successfully${isOnline ? '' : ' (offline)'}',
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save reminder'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      setState(() => isSaving = false);
    }
  }

  Future<void> _deleteReminder(ReminderModel reminder) async {
    try {
      // Cancel notification first
      await NotificationService.instance.cancelReminderNotification(reminder.id);
      // Then delete the reminder
      await DataRepository.instance.deleteReminder(reminder.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reminder deleted successfully'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, stackTrace) {
      log('Error deleting reminder: $e', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting reminder: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToReminderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReminderHistoryScreen()),
    );
  }

  InputDecoration _getDropdownDecoration(bool isDarkMode) {
    return InputDecoration(
      filled: true,
      fillColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          width: 1.w,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          width: 1.w,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
          width: 1.5.w,
        ),
      ),
      hintStyle: TextStyle(
        color: isDarkMode ? AppColors.darkTextHint : AppColors.lightTextHint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Filter categories based on selected content type
    List<DropdownMenuItem<String>> categoryItems = [
      DropdownMenuItem(
        value: 'all',
        child: Text(
          'All Categories',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: isDarkMode
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ),
    ];

    // Create a map of category IDs to names
    final categoryMap = <String, String>{'all': 'All Categories'};

    // If no content type is selected or 'all' is selected, show all categories
    if (selectedType == null || selectedType == 'all') {
      for (var category in categories) {
        categoryMap[category.categoryId] = category.categoryName;
      }
    } else {
      // Filter categories that have tips matching the selected content type
      final matchingCategoryIds = tips
          .where((tip) => tip.tipsType.toLowerCase() == selectedType!.toLowerCase())
          .map((tip) => tip.categoryId)
          .toSet();

      log('Selected type: $selectedType, Matching category IDs: $matchingCategoryIds');

      if (matchingCategoryIds.isEmpty) {
        // If no tips match, show all categories and inform the user
        for (var category in categories) {
          categoryMap[category.categoryId] = category.categoryName;
        }

        if (mounted && selectedType != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No ${contentTypes[selectedType!] ?? StringExtension(selectedType!).capitalize()} content available for any category. Showing all categories.',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Only include categories with matching content
        for (var category in categories) {
          if (matchingCategoryIds.contains(category.categoryId)) {
            categoryMap[category.categoryId] = category.categoryName;
          }
        }
      }
    }

    // Convert the category map to dropdown items
    categoryItems.addAll(
      categoryMap.entries
          .where((entry) => entry.key != 'all')
          .map(
            (entry) => DropdownMenuItem(
          value: entry.key,
          child: Text(
            entry.value,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      )
          .toList(),
    );

    // Make sure selected category is still valid
    if (selectedCategoryId != null && !categoryMap.containsKey(selectedCategoryId)) {
      selectedCategoryId = 'all';
    }

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
              color: isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.reminder != null ? 'Edit Reminder' : 'Create Reminder',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.history,
                color: isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              onPressed: _navigateToReminderHistory,
              tooltip: 'View Reminder History',
            ),
          ],
        ),
        body: isLoadingCategories
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content Type',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16.sp,
                  fontFamily: 'Poppins',
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                decoration: _getDropdownDecoration(isDarkMode),
                value: selectedType,
                hint: Text(
                  'Select Content Type',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                ),
                items: contentTypes.entries.map(
                      (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ).toList(),
                onChanged: (value) => setState(() {
                  selectedType = value;
                  selectedCategoryId = 'all'; // Reset category when type changes
                }),
              ),
              SizedBox(height: 16.h),
              Text(
                'Category',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16.sp,
                  fontFamily: 'Poppins',
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                decoration: _getDropdownDecoration(isDarkMode),
                value: selectedCategoryId,
                hint: Text(
                  'Select Category',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                ),
                items: categoryItems,
                onChanged: (value) => setState(() => selectedCategoryId = value),
              ),
              SizedBox(height: 16.h),
              Text(
                'Frequency',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16.sp,
                  fontFamily: 'Poppins',
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                decoration: _getDropdownDecoration(isDarkMode),
                value: selectedFrequency,
                hint: Text(
                  'Select Frequency',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'daily',
                    child: Text(
                      'Daily',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text(
                      'Weekly',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  selectedFrequency = value;
                  if (value != 'weekly') selectedDayOfWeek = null;
                }),
              ),
              if (selectedFrequency == 'weekly') ...[
                SizedBox(height: 16.h),
                Text(
                  'Day of Week',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 16.sp,
                    fontFamily: 'Poppins',
                    color: isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: () => _selectDayOfWeek(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                        width: 1.w,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      color: isDarkMode
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      boxShadow: isDarkMode
                          ? []
                          : [
                        BoxShadow(
                          color: AppColors.lightTextPrimary
                              .withOpacity(0.2),
                          blurRadius: 6.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDayOfWeek == null
                              ? 'Select Day'
                              : [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday',
                          ][selectedDayOfWeek! - 1],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16.sp,
                            fontFamily: 'Poppins',
                            color: isDarkMode
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 20.sp,
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Text(
                'Time',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 16.sp,
                  fontFamily: 'Poppins',
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade600
                          : Colors.grey.shade300,
                      width: 1.w,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    boxShadow: isDarkMode
                        ? []
                        : [
                      BoxShadow(
                        color: AppColors.lightTextPrimary
                            .withOpacity(0.2),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedTime == null
                            ? 'Select Time'
                            : selectedTime!.format(context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16.sp,
                          fontFamily: 'Poppins',
                          color: isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Icon(
                        Icons.schedule,
                        size: 20.sp,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? AppColors.primary
                            : AppColors.lightTextPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: isDarkMode ? 2 : 2,
                        shadowColor: isDarkMode ? null : Colors.grey.shade300,
                      ),
                      child: isSaving
                          ? SizedBox(
                        height: 24.h,
                        width: 24.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.w,
                        ),
                      )
                          : Text(
                        widget.reminder != null
                            ? 'Update'
                            : 'Save Reminder',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  if (widget.reminder != null) ...[
                    SizedBox(width: 12.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await _deleteReminder(widget.reminder!);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: BorderSide(
                            color: isDarkMode
                                ? AppColors.error
                                : Colors.grey.shade300,
                            width: 1.w,
                          ),
                          foregroundColor: isDarkMode
                              ? AppColors.error
                              : AppColors.lightTextPrimary,
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0.0, duration: 300.ms),
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