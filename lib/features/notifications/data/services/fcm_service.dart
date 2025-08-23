import 'dart:developer';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/config/firebase/firebase_options.dart';
import 'package:wellness_app/features/notifications/data/services/notification_service.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FCMServices {
  static const String _vercelDomain = 'https://wellness-functions.vercel.app';
  static const String _fcmTokenKey = 'fcm_token';

  bool _isInitialized = false;
  FirebaseMessaging? _messaging;
  FirebaseFirestore? _firestore;

  // Ensure Firebase is initialized before using Firebase services
  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      log('Firebase not initialized in FCMServices, initializing now');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log('Firebase initialized in FCMServices');
    }
  }

  // Lazy getter for FirebaseMessaging
  Future<FirebaseMessaging> get messaging async {
    if (_messaging != null) return _messaging!;

    await _ensureFirebaseInitialized();
    _messaging = FirebaseMessaging.instance;
    return _messaging!;
  }

  // Lazy getter for FirebaseFirestore
  Future<FirebaseFirestore> get firestore async {
    if (_firestore != null) return _firestore!;

    await _ensureFirebaseInitialized();
    _firestore = FirebaseFirestore.instance;
    return _firestore!;
  }

  Future<void> initializeCloudMessaging() async {
    if (_isInitialized) {
      log('FCM already initialized, skipping');
      return;
    }

    try {
      // Get messaging instance (ensures Firebase is initialized)
      final fcm = await messaging;

      await Future.wait([
        fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          criticalAlert: true,
        ),
        fcm.setAutoInitEnabled(true),
      ]);

      final token = await getFCMToken();
      if (token != null) {
        await updateFcmToken(token);
      }

      fcm.onTokenRefresh.listen((token) async {
        if (token.isNotEmpty) {
          await updateFcmToken(token);
        }
      });

      _isInitialized = true;
      log("FCM initialized successfully");
    } catch (e, stackTrace) {
      log("Error initializing FCM: $e", stackTrace: stackTrace);
    }
  }

  Future<String?> getFCMToken() async {
    try {
      final fcm = await messaging;
      final token = await fcm.getToken();

      if (token != null && token.isNotEmpty) {
        log("FCM token retrieved: ${token.substring(0, 10)}...");
        return token;
      } else {
        log("No FCM token retrieved");
        return null;
      }
    } catch (e, stackTrace) {
      log("Error retrieving FCM token: $e", stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        log('No internet connection, skipping FCM token update');
        return;
      }
      log('Starting FCM token update for token: ${token.substring(0, 10)}...');

      final user = AuthService().getCurrentUser();
      if (user == null) {
        log('No user signed in, skipping FCM token update');
        return;
      }
      log('User authenticated: ${user.uid}');

      // Check cached token
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString(_fcmTokenKey);
      log(
        'Cached token: ${cachedToken?.substring(0, 10) ?? "null"}, New token: ${token.substring(0, 10)}...',
      );
      if (cachedToken == token) {
        log('FCM token unchanged for user ${user.uid}, skipping update');
        return;
      }

      // Get ID token with forced refresh
      final idToken = await user.getIdToken(true);
      log('ID token obtained: ${idToken != null}');
      if (idToken == null) {
        log('No ID token available for FCM update');
        return;
      }

      // Send HTTP request
      log('Sending request to $_vercelDomain/api/updateFcmToken');
      final response = await http.post(
        Uri.parse('$_vercelDomain/api/updateFcmToken'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'token': token, 'userId': user.uid}),
      );
      log('HTTP response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        await prefs.setString(_fcmTokenKey, token);
        log('FCM token updated for user ${user.uid}');
      } else {
        log('Error updating FCM token: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error updating FCM token: $e', stackTrace: stackTrace);
    }
  }

  Future<void> clearFcmTokenOnSignOut() async {
    try {
      final user = AuthService().getCurrentUser();
      if (user == null) {
        log('No user signed in, no FCM token to clear');
        return;
      }
      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        log('No ID token available for FCM token clear');
        return;
      }
      final response = await http.post(
        Uri.parse('$_vercelDomain/api/clearFcmToken'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'userId': user.uid}),
      );
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_fcmTokenKey);
        log('FCM token cleared for user ${user.uid}');
      } else {
        log('Error clearing FCM token: ${response.body}');
      }
    } catch (e, stackTrace) {
      log('Error clearing FCM token: $e', stackTrace: stackTrace);
    }
  }

  Future<void> listenFCMMessage(BackgroundMessageHandler? handler) async {
    try {
      // Ensure Firebase is initialized
      await _ensureFirebaseInitialized();

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleFCMMessage);

      FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
      ) async {
        log(
          "Notification opened from FCM: title=${message.notification?.title}, data=${message.data}",
        );
        await NotificationService.instance.showNotification(message: message);
        await NotificationService.instance.onClickToNotification(
          json.encode(message.data),
        );
      });

      if (handler != null) {
        // Note: The background handler is actually registered in main.dart before runApp()
        // This line is kept for documentation purposes but doesn't actually work here
        log("FCM background handler is registered in main.dart (not here)");
      } else {
        log("Warning: FCM background handler is null");
      }
    } catch (e, stackTrace) {
      log("Error setting up FCM listeners: $e", stackTrace: stackTrace);
    }
  }

  Future<void> _handleFCMMessage(RemoteMessage message) async {
    try {
      log('Received FCM message title: ${message.notification?.title}');
      log('Received FCM message body: ${message.notification?.body}');
      log('Received FCM message data: ${message.data}');

      // Add content type to data if it's missing
      final data = Map<String, dynamic>.from(message.data);

      // Ensure contentType is present for proper navigation
      if (!data.containsKey('contentType')) {
        if (data.containsKey('type')) {
          data['contentType'] = data['type'];
        } else if (data.containsKey('tipId')) {
          // Try to get content type from Firestore if possible
          try {
            final tipId = data['tipId'];
            final db = await firestore;
            final tipDoc = await db.collection('tips').doc(tipId).get();
            if (tipDoc.exists && tipDoc.data() != null) {
              final tipType = tipDoc.data()!['tipsType'];
              if (tipType != null) {
                data['contentType'] = tipType;
                log('Added contentType=$tipType from Firestore for tip $tipId');
              }
            }
          } catch (e) {
            log('Error getting tip type from Firestore: $e');
          }
        }

        // If still no content type, use a default
        if (!data.containsKey('contentType')) {
          data['contentType'] = 'tip';
          log('No content type found, defaulting to "tip"');
        }
      }

      // Create a new message with the updated data
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

      await NotificationService.instance.showNotification(
        message: updatedMessage,
      );
    } catch (e, stackTrace) {
      log("Error handling foreground FCM message: $e", stackTrace: stackTrace);
      // If we encounter an error with the enhanced version, fall back to the original
      await NotificationService.instance.showNotification(message: message);
    }
  }

  // Test function to debug FCM token update
  Future<void> testFcmTokenUpdate() async {
    try {
      log('Starting testFcmTokenUpdate');
      final token = await getFCMToken();
      if (token != null) {
        log('Test: Clearing cached token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_fcmTokenKey);
        await updateFcmToken(token);
      } else {
        log('Test: Failed to retrieve FCM token');
      }
    } catch (e, stackTrace) {
      log('Error in testFcmTokenUpdate: $e', stackTrace: stackTrace);
    }
  }
}
