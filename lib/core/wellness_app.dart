import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/config/routes/route_generator.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import '../features/preferences/presentation/provider/user_preference_provider.dart';
import '../features/profile/providers/user_provider.dart';
import 'services/data_repository.dart';
import 'db/database_helper.dart';
import '../features/notifications/data/services/notification_service.dart';
import 'providers/theme_provider.dart';

class WellnessApp extends StatelessWidget {
  const WellnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure NotificationService is initialized
    NotificationService.instance.initLocalNotifications();

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DataRepository>(create: (_) => DataRepository.instance),
        Provider<DatabaseHelper>(create: (_) => DatabaseHelper.instance),
        ChangeNotifierProvider<FavoritesProvider>(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<PremiumStatusProvider>(create: (_) => PremiumStatusProvider()),
        ChangeNotifierProvider<UserPreferenceProvider>(create: (_) => UserPreferenceProvider()),
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
                navigatorKey: NotificationService.instance.navigatorKey,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                ],
                locale: const Locale('en'),
              );
            },
          );
        },
      ),
    );
  }
}