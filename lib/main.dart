import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wellness_app/core/wellness_app.dart';
import 'package:wellness_app/features/notifications/data/services/fcm_service.dart';
import 'package:wellness_app/core/config/firebase/firebase_options.dart';
import 'package:wellness_app/features/notifications/data/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessagingHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Add content type handling for background messages
  final data = Map<String, dynamic>.from(message.data);
  if (!data.containsKey('contentType') && data.containsKey('type')) {
    data['contentType'] = data['type'];
  }

  final updatedMessage = RemoteMessage(
    senderId: message.senderId,
    category: message.category,
    collapseKey: message.collapseKey,
    contentAvailable: message.contentAvailable,
    data: data,
    from: message.from,
    messageId: message.messageId,
    messageType: message.messageType,
    mutableContent: message.mutableContent,
    notification: message.notification,
    sentTime: message.sentTime,
    threadId: message.threadId,
    ttl: message.ttl,
  );

  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final targetUserId = updatedMessage.data['userId'] ?? 'unknown';
  if (currentUserId != null && targetUserId != currentUserId) {
    log('Skipping background notification for user $targetUserId (current user: $currentUserId)');
    return;
  }

  await NotificationService.instance.showNotification(message: updatedMessage);
  log("firebaseBackgroundMessagingHandler: $updatedMessage");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('Firebase initialized successfully');

  // Initialize NotificationService early
  await NotificationService.instance.initLocalNotifications();

  // Request notification permissions early
  await NotificationService.instance.requestExactAlarmPermission();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessagingHandler);

  // Initialize FCM
  final FCMServices fcmServices = FCMServices();
  await fcmServices.initializeCloudMessaging();
  fcmServices.listenFCMMessage(firebaseBackgroundMessagingHandler);

  // Handle auth-based token sync
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      final token = await fcmServices.getFCMToken();
      if (token != null) {
        await fcmServices.updateFcmToken(token);
      }
    } else {
      await fcmServices.clearFcmTokenOnSignOut();
    }
  });

  // Handle initial and opened notifications
  await NotificationService.instance.handleInitialNotification();
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    log("Notification opened from FCM: title=${message.notification?.title}, data=${message.data}");

    // Add content type if missing
    final data = Map<String, dynamic>.from(message.data);
    if (!data.containsKey('contentType') && data.containsKey('type')) {
      data['contentType'] = data['type'];
    }

    await NotificationService.instance.showNotification(message: message);
    await NotificationService.instance.onClickToNotification(json.encode(data));
  });

  // Check for pending notifications to sync
  await NotificationService.instance.syncPendingNotifications();

  // Test FCM token update
  await fcmServices.testFcmTokenUpdate();

  runApp(const WellnessApp());
}