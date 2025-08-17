import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:wellness_app/core/wellness_app.dart';
import 'package:wellness_app/features/notifications/data/services/fcm_service.dart';
import 'package:wellness_app/core/config/firebase/firebase_options.dart';
import 'package:wellness_app/features/notifications/data/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessagingHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final targetUserId = message.data['userId'] ?? 'unknown';
  if (currentUserId != null && targetUserId != currentUserId) {
    log('Skipping background notification for user $targetUserId (current user: $currentUserId)');
    return;
  }
  await NotificationService.instance.showNotification(message: message);
  log("firebaseBackgroundMessagingHandler: $message");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('Firebase initialized successfully');

  // Initialize NotificationService
  await NotificationService.instance.initLocalNotifications();

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
    await NotificationService.instance.showNotification(message: message);
    await NotificationService.instance.onClickToNotification(json.encode(message.data));
  });

  // Test FCM token update
  await fcmServices.testFcmTokenUpdate();

  runApp(const WellnessApp());
}