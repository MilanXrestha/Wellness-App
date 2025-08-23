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
  // Try to initialize Firebase, but don't block if it fails
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    log('Error initializing Firebase in background handler: $e');
    // Continue anyway - we'll try to handle what we can
  }

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

  // Try to get current user, but proceed even if this fails
  String? currentUserId;
  try {
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  } catch (e) {
    log('Error getting current user in background handler: $e');
  }

  final targetUserId = updatedMessage.data['userId'] ?? 'unknown';
  if (currentUserId != null && targetUserId != currentUserId) {
    log(
      'Skipping background notification for user $targetUserId (current user: $currentUserId)',
    );
    return;
  }

  try {
    await NotificationService.instance.showNotification(message: updatedMessage);
  } catch (e) {
    log('Error showing notification in background handler: $e');
  }
  log("firebaseBackgroundMessagingHandler: $updatedMessage");
}

void main() async {
  // Basic Flutter initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Register background handler BEFORE any Firebase initialization
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessagingHandler);

  // Try to initialize Firebase, but don't block app launch if it fails
  try {
    if (Firebase.apps.isEmpty) {
      log('Initializing Firebase in main');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log('Firebase initialized in main successfully');
    }
  } catch (e) {
    log('Failed to initialize Firebase in main: $e');
    // Continue anyway - WellnessApp will handle offline mode
  }

  // Start the app
  runApp(const WellnessApp());
}