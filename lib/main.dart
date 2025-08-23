import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wellness_app/core/config/firebase/firebase_options.dart';
import 'package:wellness_app/core/wellness_app.dart';
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
    log(
      'Skipping background notification for user $targetUserId (current user: $currentUserId)',
    );
    return;
  }

  await NotificationService.instance.showNotification(message: updatedMessage);
  log("firebaseBackgroundMessagingHandler: $updatedMessage");
}

void main() async {
  // Basic Flutter initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (this is quick and essential)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Register background handler BEFORE running the app
  // This is the recommended way to ensure all messages are caught
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessagingHandler);

  // Start the app immediately
  runApp(const WellnessApp());
}
