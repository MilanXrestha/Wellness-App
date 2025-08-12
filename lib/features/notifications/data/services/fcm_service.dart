import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/features/notifications/data/services/notification_service.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FCMServices {
  static const String _vercelDomain = 'https://wellness-functions.vercel.app';
  static const String _fcmTokenKey = 'fcm_token';

  Future<void> initializeCloudMessaging() async {
    try {
      await Future.wait([
        FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        ),
        FirebaseMessaging.instance.setAutoInitEnabled(true),
      ]);
      final token = await getFCMToken();
      if (token != null) {
        await updateFcmToken(token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        if (token.isNotEmpty) {
          await updateFcmToken(token);
        }
      });
      log("FCM initialized successfully");
    } catch (e, stackTrace) {
      log("Error initializing FCM: $e", stackTrace: stackTrace);
    }
  }

  Future<String?> getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        log("FCM token retrieved: $token");
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
      log('Starting FCM token update for token: $token');

      final user = AuthService().getCurrentUser();
      if (user == null) {
        log('No user signed in, skipping FCM token update');
        return;
      }
      log('User authenticated: ${user.uid}');

      // Check cached token
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString(_fcmTokenKey);
      log('Cached token: $cachedToken, New token: $token');
      if (cachedToken == token) {
        log('FCM token unchanged for user ${user.uid}, skipping update');
        return;
      }

      // Get ID token with forced refresh
      final idToken = await user.getIdToken(true);
      log('ID token: ${idToken ?? 'null'}');
      if (idToken == null) {
        log('No ID token available for FCM update');
        return;
      }

      // Send HTTP request
      log('Sending request to $_vercelDomain/api/updateFcmToken');
      log('Request body: ${json.encode({'token': token, 'userId': user.uid})}');
      final response = await http.post(
        Uri.parse('$_vercelDomain/api/updateFcmToken'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'token': token,
          'userId': user.uid,
        }),
      );
      log('HTTP response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        await prefs.setString(_fcmTokenKey, token);
        log('FCM token updated for user ${user.uid}: $token');
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
      FirebaseMessaging.onMessage.listen(_handleFCMMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        log("Notification opened from FCM: title=${message.notification?.title}, data=${message.data}");
        await NotificationService.instance.showNotification(message: message);
        await NotificationService.instance.onClickToNotification(json.encode(message.data));
      });
      if (handler != null) {
        FirebaseMessaging.onBackgroundMessage(handler);
        log("FCM background handler registered successfully");
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
      await NotificationService.instance.showNotification(message: message);
    } catch (e, stackTrace) {
      log("Error handling foreground FCM message: $e", stackTrace: stackTrace);
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