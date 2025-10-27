import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/config/firebase/firebase_options.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/config/routes/route_generator.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import '../features/dashboard/presentation/providers/notification_count_provider.dart';
import '../features/notifications/data/services/fcm_service.dart';
import '../features/preferences/presentation/provider/user_preference_provider.dart';
import '../features/profile/providers/user_provider.dart';
import '../features/tips/presentation/providers/settings_provider.dart';
import '../features/videoPlayer/data/services/video_service.dart';
import '../features/videoPlayer/domain/useCases/video_usecase.dart';
import '../features/videoPlayer/presentation/providers/shorts_provider.dart';
import 'services/data_repository.dart';
import 'db/database_helper.dart';
import '../features/notifications/data/services/notification_service.dart';
import 'providers/theme_provider.dart';

class WellnessApp extends StatefulWidget {
  const WellnessApp({super.key});

  @override
  State<WellnessApp> createState() => _WellnessAppState();
}

class _WellnessAppState extends State<WellnessApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late Future<void> _initFuture;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Set the navigator key in the notification service
    NotificationService.instance.setNavigatorKey(_navigatorKey);

    _initFuture = _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for notifications when app is resumed
      _checkForNotifications();
    }
  }

  Future<void> _checkForNotifications() async {
    try {
      final NotificationAppLaunchDetails? launchDetails =
          await NotificationService.instance.flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();

      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        log(
          'App resumed by notification: ${launchDetails.notificationResponse?.payload}',
        );
        await NotificationService.instance.onClickToNotification(
          launchDetails.notificationResponse!.payload!,
        );
      }
    } catch (e) {
      log('Error checking for notifications on resume: $e');
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize Firebase only if not already
      if (Firebase.apps.isEmpty) {
        log('Initializing Firebase in WellnessApp');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        log('Firebase initialized successfully');
      }

      // Initialize local notifications (works offline)
      await NotificationService.instance.initLocalNotifications();

      // Try FCM + online services, but don't block app if offline
      final fcmServices = FCMServices();
      try {
        await fcmServices.initializeCloudMessaging();
        await fcmServices.updateFcmTokenDirectly();

        // Listen to auth state for FCM
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

        // Foreground message handler
        FirebaseMessaging.onMessageOpenedApp.listen((
          RemoteMessage message,
        ) async {
          final data = Map<String, dynamic>.from(message.data);
          if (!data.containsKey('contentType') && data.containsKey('type')) {
            data['contentType'] = data['type'];
          }
          await NotificationService.instance.showNotification(message: message);
          await NotificationService.instance.onClickToNotification(
            json.encode(data),
          );
        });

        fcmServices.listenFCMMessage(null);
      } catch (e) {
        log("FCM init skipped (probably offline): $e");
        _isOffline = true;
      }

      // Handle pending local notifications
      await NotificationService.instance.handleInitialNotification();
      await NotificationService.instance.syncPendingNotifications();
    } catch (e) {
      log('Error initializing services: $e');
      _isOffline = true;
      // Don't throw → allow app to load in offline mode
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        // Create services (VideoService will handle Firebase unavailability)
        final videoService = VideoService();
        final authService = AuthService();

        // Log the state for debugging
        if (_isOffline) {
          log('App starting in offline mode');
        }
        if (snapshot.hasError) {
          log('App starting with initialization error: ${snapshot.error}');
        }

        // Always load UI, even if Firebase init fails or is still initializing
        return MultiProvider(
          providers: [
            Provider<AuthService>(create: (_) => authService),
            Provider<DataRepository>(create: (_) => DataRepository.instance),
            Provider<DatabaseHelper>(create: (_) => DatabaseHelper.instance),

            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider<FavoritesProvider>(
              create: (_) => FavoritesProvider(),
            ),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
            ChangeNotifierProvider<PremiumStatusProvider>(
              create: (_) => PremiumStatusProvider(),
            ),
            ChangeNotifierProvider<UserPreferenceProvider>(
              create: (_) => UserPreferenceProvider(),
            ),
            ChangeNotifierProvider(create: (_) => NotificationCountProvider()),
            ChangeNotifierProvider(
              create: (_) => ShortsProvider(
                getVideosUseCase: GetVideosUseCase(videoService),
                incrementViewCountUseCase: IncrementViewCountUseCase(
                  videoService,
                ),
                toggleLikeUseCase: ToggleLikeUseCase(videoService),
                isVideoLikedUseCase: IsVideoLikedUseCase(videoService),
                authService: authService,
              ),
            ),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ScreenUtilInit(
                designSize: const Size(360, 690),
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, child) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'Wellness App',
                    theme: themeProvider.getTheme(),
                    initialRoute: RoutesName.splashScreen,
                    onGenerateRoute: RouteConfig.generateRoute,
                    navigatorKey: _navigatorKey,
                    // This is important!
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [Locale('en')],
                    locale: const Locale('en'),
                    onGenerateInitialRoutes: (String initialRoute) {
                      return [
                        RouteConfig.generateRoute(
                          RouteSettings(name: initialRoute),
                        ),
                      ];
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
