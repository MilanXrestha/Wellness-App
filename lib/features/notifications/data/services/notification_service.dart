import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import 'package:wellness_app/features/reminders/data/models/reminder_model.dart';
import 'package:wellness_app/features/notifications/data/models/notification_model.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:developer';
import 'package:wellness_app/core/config/firebase/firebase_options.dart';

import '../../../../core/config/routes/route_name.dart';
import '../../../../core/db/database_helper.dart';

class NotificationService {
  NotificationService._privateConstructor();

  static final NotificationService _instance = NotificationService._privateConstructor();
  static NotificationService get instance => _instance;

  static const String _vercelDomain = 'https://wellness-functions.vercel.app';
  static const String _pendingNotificationKey = 'pending_notification';
  static const String _pendingRemindersKey = 'pending_reminders';
  static const String _hasRequestedExactAlarmKey = 'has_requested_exact_alarm';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  FirebaseFirestore? _firestore;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isInitialized = false;
  bool _isFirestoreInitialized = false;

  // Lazy getter for Firestore to ensure Firebase is initialized first
  Future<FirebaseFirestore> get firestore async {
    if (_firestore != null && _isFirestoreInitialized) {
      return _firestore!;
    }

    try {
      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        log('Firebase not initialized in NotificationService, initializing now');
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }

      _firestore = FirebaseFirestore.instance;
      _isFirestoreInitialized = true;
      log('Firestore initialized in NotificationService');
      return _firestore!;
    } catch (e) {
      log('Error initializing Firestore: $e');
      throw Exception('Failed to initialize Firestore: $e');
    }
  }

  Future<void> initLocalNotifications() async {
    if (_isInitialized) {
      log('NotificationService already initialized, skipping');
      return;
    }

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
      log('Local time zone set to: ${tz.local.name}');

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_notification');
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          final String? payload = notificationResponse.payload;
          if (payload != null) {
            log('Notification clicked from local notifications: $payload');
            await onClickToNotification(payload);
          } else {
            log('Notification clicked but payload is null');
          }
        },
      );

      // Register background/terminated state handler
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then((details) async {
        if (details != null && details.didNotificationLaunchApp && details.notificationResponse?.payload != null) {
          log('App launched from notification: ${details.notificationResponse?.payload}');
          await onClickToNotification(details.notificationResponse!.payload!);
        }
      });

      await _createNotificationChannel();
      await _requestNotificationPermission();
      _isInitialized = true;
      log("Local notifications initialized successfully");
    } catch (e, stackTrace) {
      log("Error initializing local notifications: $e", stackTrace: stackTrace);
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'wellness_channel',
      'Wellness Notifications',
      description: 'Notifications for wellness updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      log('Notification channel wellness_channel created');
    } else {
      log('Android plugin implementation not found; cannot create channel');
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) {
        log('Android platform implementation not found');
        return;
      }
      final bool granted = await androidPlugin.requestNotificationsPermission() ?? false;
      log('Notification permission requested: $granted');
    } catch (e, stackTrace) {
      log('Error requesting notification permission: $e', stackTrace: stackTrace);
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequestedExactAlarm = prefs.getBool(_hasRequestedExactAlarmKey) ?? false;
      if (hasRequestedExactAlarm) {
        log('SCHEDULE_EXACT_ALARM permission already requested, skipping');
        return true;
      }

      final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) {
        log('Android platform implementation not found');
        return false;
      }

      final bool? granted = await androidPlugin.requestExactAlarmsPermission();
      if (granted == true) {
        await prefs.setBool(_hasRequestedExactAlarmKey, true);
        log('SCHEDULE_EXACT_ALARM permission granted');
        return true;
      } else {
        log('SCHEDULE_EXACT_ALARM permission denied');
        return false;
      }
    } catch (e, stackTrace) {
      log('Error requesting SCHEDULE_EXACT_ALARM permission: $e', stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> showNotification({required RemoteMessage message}) async {
    try {
      final currentUserId = AuthService().getCurrentUser()?.uid;
      final targetUserId = message.data['userId'] ?? 'unknown';
      if (currentUserId != null && targetUserId != currentUserId) {
        log('Skipping notification for user $targetUserId (current user: $currentUserId)');
        return;
      }

      log('Local notification remote message: ${message.toMap()}');

      const String channelId = 'wellness_channel';
      const String channelName = 'Wellness Notifications';
      const String channelDesc = 'Notifications for wellness updates';

      final int notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          showWhen: true,
          icon: 'ic_notification',
          fullScreenIntent: true, // Make notification clickable even when screen is locked
          category: AndroidNotificationCategory.message, // Ensure high priority
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final payloadJson = json.encode(message.data);
      log('Showing notification with payload: $payloadJson');

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        message.notification?.title ?? message.data['title'] ?? 'No Title',
        message.notification?.body ?? message.data['body'] ?? 'No Body',
        platformChannelSpecifics,
        payload: payloadJson,
      );

      // Don't create a notification record in the database since this
      // is just displaying a notification, not storing it for history

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingNotificationKey, payloadJson);
      log('Stored pending notification payload: ${message.data}');
    } catch (e, stackTrace) {
      log("Error showing notification: $e", stackTrace: stackTrace);
    }
  }

  Future<void> scheduleReminderNotification(ReminderModel reminder) async {
    try {
      await initLocalNotifications();
      final currentUserId = AuthService().getCurrentUser()?.uid;
      if (currentUserId == null || currentUserId != reminder.userId) {
        log('No authenticated user or userId mismatch for reminder ${reminder.id}, skipping');
        return;
      }

      String title = 'Your ${reminder.type.capitalize()} Reminder';
      String body = 'Time to check your ${reminder.type} content';
      String? tipId;
      String contentType = reminder.type; // Default content type

      if (await DataRepository.instance.isOnline()) {
        // Get tips matching this reminder's criteria
        final tips = await DataRepository.instance.getTipsByCategory(
          reminder.categoryId,
          includePremium: false,
        ).timeout(Duration(seconds: 2), onTimeout: () {
          log('Timeout fetching tips for reminder ${reminder.id}');
          return [];
        });
        log('Fetched ${tips.length} tips for category ${reminder.categoryId}, type: ${reminder.type}');

        // Filter tips based on reminder type
        final filteredTips = tips.where((tip) {
          if (reminder.type == 'all') return true;
          return tip.tipsType == reminder.type;
        }).toList();

        if (filteredTips.isNotEmpty) {
          // Select a random tip to show
          final tip = filteredTips[DateTime.now().millisecondsSinceEpoch % filteredTips.length];
          log('Selected tip: ${tip.tipsId}, title: ${tip.tipsTitle}, type: ${tip.tipsType}');
          body = tip.tipsTitle;
          tipId = tip.tipsId;
          contentType = tip.tipsType; // Set actual content type from tip
        } else {
          log('No tips found for reminder ${reminder.id}, using default message');
        }
      } else {
        log('Offline: Using default notification message for reminder ${reminder.id}');
      }

      // Create a unique ID for this notification
      final notificationId = const Uuid().v4().hashCode.abs();

      // Parse the time from reminder
      final timeParts = reminder.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Calculate scheduled date
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      final timeDiff = scheduledDate.difference(now).inSeconds;
      log('Current time (local): $now, Scheduled date (local): $scheduledDate, time difference: $timeDiff seconds');

      // If time has already passed today, schedule for tomorrow
      if (timeDiff < 0) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        log('Scheduled date moved to next day: $scheduledDate');
      }

      // Create notification details
      const androidDetails = AndroidNotificationDetails(
        'wellness_channel',
        'Wellness Reminders',
        channelDescription: 'Notifications for wellness reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      final notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Create payload with content type information
      final payload = {
        'tipId': tipId,
        'type': reminder.type,
        'userId': reminder.userId,
        'isFromReminder': true,
        'contentType': contentType, // Include content type for proper navigation
      };
      final payloadJson = json.encode(payload);

      // Request exact alarm permission
      final exactAlarmsPermitted = await requestExactAlarmPermission();
      final scheduleMode = exactAlarmsPermitted
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      // Schedule the notification based on frequency
      if (reminder.frequency == 'daily') {
        await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            title,
            body,
            scheduledDate,
            notificationDetails,
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: payloadJson
        );
        log('Scheduled daily notification $notificationId for reminder ${reminder.id} at ${reminder.time} with mode $scheduleMode');
      } else if (reminder.frequency == 'weekly' && reminder.dayOfWeek != null) {
        // Adjust date to next occurrence of the specified day of week
        while (scheduledDate.weekday != reminder.dayOfWeek) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        log('Adjusted weekly scheduled date: $scheduledDate');

        await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            title,
            body,
            scheduledDate,
            notificationDetails,
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payloadJson
        );
        log('Scheduled weekly notification $notificationId for reminder ${reminder.id} on day ${reminder.dayOfWeek} at ${reminder.time} with mode $scheduleMode');
      }

      // Update reminder with notification ID
      final updatedReminder = ReminderModel(
        id: reminder.id,
        userId: reminder.userId,
        categoryId: reminder.categoryId,
        type: reminder.type,
        frequency: reminder.frequency,
        time: reminder.time,
        dayOfWeek: reminder.dayOfWeek,
        createdAt: reminder.createdAt,
        notificationId: notificationId,
      );
      await DataRepository.instance.updateReminder(updatedReminder);
      log('Updated reminder ${reminder.id} with notificationId $notificationId');
    } catch (e, stackTrace) {
      log('Error scheduling notification for reminder ${reminder.id}: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> queueNotification(ReminderModel reminder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingReminders = prefs.getStringList(_pendingRemindersKey) ?? [];
      pendingReminders.add(jsonEncode(reminder.toJson()));
      await prefs.setStringList(_pendingRemindersKey, pendingReminders);
      log('Notification queued for reminder: ${reminder.id}');

      // Even if we're offline, try to schedule the local notification
      // since this doesn't require network
      try {
        await scheduleReminderNotification(reminder);
        log('Successfully scheduled local notification for offline reminder: ${reminder.id}');
      } catch (e, stackTrace) {
        log('Failed to schedule local notification for offline reminder: $e', error: e, stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      log('Failed to queue notification: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> syncPendingNotifications() async {
    try {
      if (!await DataRepository.instance.isOnline()) {
        log('Offline: Skipping notification sync');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final pendingReminders = prefs.getStringList(_pendingRemindersKey) ?? [];

      for (var reminderJson in pendingReminders) {
        final reminder = ReminderModel.fromJson(jsonDecode(reminderJson));
        log('Scheduling queued notification for reminder: ${reminder.id}');
        try {
          await scheduleReminderNotification(reminder);
        } catch (e, stackTrace) {
          log('Failed to schedule queued notification for ${reminder.id}: $e', error: e, stackTrace: stackTrace);
          continue;
        }
      }
      await prefs.setStringList(_pendingRemindersKey, []);
      log('Cleared queued notifications');
    } catch (e, stackTrace) {
      log('Error syncing pending notifications: $e', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> cancelReminderNotification(String reminderId) async {
    try {
      final reminder = await DataRepository.instance.getReminderById(reminderId);
      if (reminder != null && reminder.notificationId != null) {
        await flutterLocalNotificationsPlugin.cancel(reminder.notificationId!);
        log('Cancelled notification ${reminder.notificationId} for reminder $reminderId');
      } else {
        log('No notificationId found for reminder $reminderId');
      }
    } catch (e, stackTrace) {
      log('Error cancelling notification for reminder $reminderId: $e', stackTrace: stackTrace);
    }
  }

  Future<void> onClickToNotification(String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      log("Notification clicked with payload: $data");

      final tipId = data['tipId'] as String?;
      final type = data['type'] as String? ?? 'tip';
      final contentType = data['contentType'] as String? ?? type; // Default to type if contentType not specified
      final isFromReminder = data['isFromReminder'] as bool? ?? false;
      final userId = data['userId'] as String? ?? '';

      if (tipId != null && tipId.isNotEmpty) {
        // Fetch the tip from Firestore
        final db = await firestore; // Use the async getter
        final tipDoc = await db.collection('tips').doc(tipId).get();
        if (!tipDoc.exists) {
          log('Tip not found for tipId: $tipId');
          return;
        }

        final tip = TipModel.fromFirestore(tipDoc.data()! as Map<String, dynamic>, tipId);
        log('Fetched tip: ${tip.tipsId}, type: ${tip.tipsType}');

        // Save notification click to database to mark as read
        if (isFromReminder) {
          try {
            final notificationModel = NotificationModel(
              id: const Uuid().v4(),
              userId: userId,
              title: 'Reminder: ${tip.tipsTitle}',
              body: tip.tipsDescription.length > 100
                  ? '${tip.tipsDescription.substring(0, 100)}...'
                  : tip.tipsDescription,
              type: tip.tipsType,
              isRead: true, // Mark as read since user clicked it
              payload: data,
              timestamp: DateTime.now(),
            );

            await DatabaseHelper.instance.insertNotification(notificationModel);
            final db = await firestore; // Use the async getter
            await db
                .collection('notifications')
                .doc(notificationModel.id)
                .set(notificationModel.toFirestore());
            log('Created read notification record for reminder click: ${notificationModel.id}');
          } catch (e) {
            log('Error creating notification record: $e');
          }
        }

        // Get the navigator instance
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          // Navigate based on content type
          switch (tip.tipsType) {
            case 'video':
              navigator.pushNamed(
                RoutesName.videoPlayerScreen,
                arguments: {
                  'tip': tip,
                  'categoryName': isFromReminder ? 'Video Content' : 'Videos',
                  'featuredTips': <TipModel>[], // Optional: fetch related videos
                },
              );
              log('Navigated to VideoPlayerScreen with tipId: ${tip.tipsId}');
              break;

            case 'audio':
              navigator.pushNamed(
                RoutesName.mediaPlayerScreen,
                arguments: {
                  'tip': tip,
                  'categoryName': isFromReminder ? 'Audio Content' : 'Audio',
                  'featuredTips': <TipModel>[], // Optional: fetch related audio
                },
              );
              log('Navigated to MediaPlayerScreen with tipId: ${tip.tipsId}');
              break;

            case 'image':
              navigator.pushNamed(
                RoutesName.imageViewerScreen,
                arguments: {
                  'tip': tip,
                  'imageTips': <TipModel>[tip], // Optional: fetch related images
                  'initialIndex': 0,
                },
              );
              log('Navigated to ImageViewerScreen with tipId: ${tip.tipsId}');
              break;

            default:
            // Default for tips, quotes, etc.
              navigator.pushNamed(
                RoutesName.tipsDetailScreen,
                arguments: {
                  'tip': tip,
                  'categoryName': isFromReminder
                      ? 'Recently Added'
                      : (tip.tipsType == 'tip' ? 'Health Tips' : 'Latest Quotes'),
                  'userId': userId,
                  'featuredTips': <TipModel>[],
                  'allHealthTips': false,
                  'allQuotes': false,
                },
              );
              log('Navigated to TipsDetailScreen with tipId: ${tip.tipsId}');
              break;
          }

          // Clear pending notification after handling
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_pendingNotificationKey);
        } else {
          log('NavigatorState is null, cannot navigate');
        }
      } else {
        log('No valid tipId in payload, cannot navigate');
      }
    } catch (e, stackTrace) {
      log("Error handling notification click: $e", stackTrace: stackTrace);
    }
  }

  Future<void> handleInitialNotification() async {
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        log('Handling initial FCM message: ${initialMessage.data}');
        await showNotification(message: initialMessage);
        await onClickToNotification(json.encode(initialMessage.data));
      }

      // Check for pending notifications
      final prefs = await SharedPreferences.getInstance();
      final storedPayload = prefs.getString(_pendingNotificationKey);
      if (storedPayload != null) {
        log('Handling stored notification payload: $storedPayload');
        await onClickToNotification(storedPayload);
      }

      // Check for app launch from notification
      final NotificationAppLaunchDetails? launchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null) {
          log('App launched by notification: $payload');
          await onClickToNotification(payload);
        }
      }
    } catch (e, stackTrace) {
      log("Error handling initial notification: $e", stackTrace: stackTrace);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}