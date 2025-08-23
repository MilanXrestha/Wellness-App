import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
import 'services/data_repository.dart';
import 'db/database_helper.dart';
import '../features/notifications/data/services/notification_service.dart';
import 'providers/theme_provider.dart';

class WellnessApp extends StatefulWidget {
  const WellnessApp({super.key});

  @override
  State<WellnessApp> createState() => _WellnessAppState();
}

class _WellnessAppState extends State<WellnessApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize services in the background
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // First ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        log('Initializing Firebase in WellnessApp');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        log('Firebase initialized successfully');
      }

      // Create service instances
      final FCMServices fcmServices = FCMServices();

      // Initialize all services in parallel with error handling for each
      final initTasks = <Future<void>>[];

      // Add FCM services
      initTasks.add(
        fcmServices.initializeCloudMessaging().catchError((e) {
          log('Error initializing FCM: $e');
          return null; // Continue even if this fails
        }),
      );

      // Add notification services
      initTasks.add(
        NotificationService.instance.initLocalNotifications().catchError((e) {
          log('Error initializing local notifications: $e');
          return null;
        }),
      );

      initTasks.add(
        NotificationService.instance.handleInitialNotification().catchError((
          e,
        ) {
          log('Error handling initial notification: $e');
          return null;
        }),
      );

      initTasks.add(
        NotificationService.instance.syncPendingNotifications().catchError((e) {
          log('Error syncing notifications: $e');
          return null;
        }),
      );

      // Wait for all tasks to complete (even if some fail)
      await Future.wait(initTasks);
      log('Service initialization completed');

      // Set up listeners (this needs to happen after initialization)
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

      // Set up notification handling
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

      // Set up FCM message listening
      fcmServices.listenFCMMessage(
        null,
      ); // The handler is registered in main.dart
    } catch (e) {
      log('Error initializing services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DataRepository>(create: (_) => DataRepository.instance),
        Provider<DatabaseHelper>(create: (_) => DatabaseHelper.instance),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<PremiumStatusProvider>(
          create: (_) => PremiumStatusProvider(),
        ),
        ChangeNotifierProvider<UserPreferenceProvider>(
          create: (_) => UserPreferenceProvider(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationCountProvider()),
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
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en')],
                locale: const Locale('en'),
                // Handle deep links
                onGenerateInitialRoutes: (String initialRoute) {
                  if (initialRoute != RoutesName.splashScreen) {
                    return [
                      RouteConfig.generateRoute(
                        RouteSettings(name: initialRoute),
                      ),
                    ];
                  }
                  return [
                    RouteConfig.generateRoute(
                      const RouteSettings(name: RoutesName.splashScreen),
                    ),
                  ];
                },
              );
            },
          );
        },
      ),
    );
  }
}
