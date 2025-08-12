import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import '../../../../core/constants/config.dart';

/// Splash screen widget that checks first launch and navigates to the appropriate screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controls the fade-in animation
  late Animation<double> _fadeIn; // The fade-in animation itself
  String _nextRoute = RoutesName.loginScreen; // Destination route after splash
  final AuthService _authService = AuthService(); // Instance of AuthService

  @override
  void initState() {
    super.initState();

    // Set up a 1-second fade-in animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Use a curved fade-in for smooth visual entrance
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward(); // Start the animation

    // Begin screen resolution and navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndNavigate();
    });
  }

  /// Decides which screen to go to after splash
  Future<void> _initializeAndNavigate() async {
    log('Starting _initializeAndNavigate');
    try {
      // Check SharedPreferences immediately for onboarding status
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
      if (!hasCompletedOnboarding && mounted) {
        log('Fast-tracking to onboardScreen');
        _nextRoute = RoutesName.onboardScreen;
        Navigator.pushReplacementNamed(context, _nextRoute);
        return;
      }

      final delayFuture = Future.delayed(
        Duration(milliseconds: AppConfig.splashDuration),
      );
      final routeFuture = _resolveDestinationRoute();
      log('Waiting for delay and route resolution');
      final results = await Future.wait([delayFuture, routeFuture]);

      if (!mounted) {
        log('Widget not mounted after Future.wait, aborting navigation');
        return;
      }

      _nextRoute = results[1] as String;
      log('Navigating to route: $_nextRoute');
      Navigator.pushReplacementNamed(context, _nextRoute);
    } catch (e) {
      log('Error in _initializeAndNavigate: $e');
      if (!mounted) {
        log('Widget not mounted in catch block, aborting navigation');
        return;
      }
      log('Navigating to loginScreen due to error');
      Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
    }
  }

  /// Determines where to go after splash based on auth and user status
  Future<String> _resolveDestinationRoute() async {
    log('Starting _resolveDestinationRoute');
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      log('SharedPreferences initialized successfully');
    } catch (e) {
      log('Failed to initialize SharedPreferences: $e');
      // Retry once
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        prefs = await SharedPreferences.getInstance();
        log('SharedPreferences initialized on retry');
      } catch (e) {
        log('Failed to initialize SharedPreferences on retry: $e');
        // Default to onboarding screen on failure
        return RoutesName.onboardScreen;
      }
    }

    final onboardingCompletedRaw = prefs.getBool('onboarding_completed');
    final hasCompletedOnboarding = onboardingCompletedRaw ?? false;
    log('onboarding_completed raw: $onboardingCompletedRaw, hasCompletedOnboarding: $hasCompletedOnboarding');

    if (!hasCompletedOnboarding) {
      log('Returning onboardScreen');
      return RoutesName.onboardScreen;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    log('Current user: ${currentUser?.uid ?? "null"}');
    if (currentUser == null) {
      log('Returning loginScreen (no user)');
      return RoutesName.loginScreen;
    }

    final lastLoginTimestamp = prefs.getInt('last_login_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const sessionThreshold = 7 * 24 * 60 * 60 * 1000;
    log('Last login: $lastLoginTimestamp, Now: $now, Session expired: ${now - lastLoginTimestamp > sessionThreshold}');
    if (now - lastLoginTimestamp > sessionThreshold) {
      await FirebaseAuth.instance.signOut();
      log('Returning loginScreen (session expired)');
      return RoutesName.loginScreen;
    }

    final cachedRole = prefs.getString('userRole');
    final cachedPreferenceCompleted = prefs.getBool('preferenceCompleted');
    log('Cached role: $cachedRole, Preference completed: $cachedPreferenceCompleted');
    if (cachedRole != null && cachedPreferenceCompleted != null) {
      if (cachedRole == 'admin') {
        log('Returning adminDashboardScreen');
        return RoutesName.adminDashboardScreen;
      }
      log('Returning ${cachedPreferenceCompleted ? "mainScreen" : "userPrefsScreen"}');
      return cachedPreferenceCompleted
          ? RoutesName.mainScreen
          : RoutesName.userPrefsScreen;
    }

    try {
      log('Fetching route from AuthService');
      final route = await _authService.getUserNavigationRoute(currentUser.uid).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          log('AuthService timed out, returning loginScreen');
          return RoutesName.loginScreen;
        },
      );
      log('AuthService returned route: $route');
      return route;
    } catch (e) {
      log('Error in AuthService: $e, returning loginScreen');
      return RoutesName.loginScreen;
    }
  }

  /// Builds the splash screen UI with branding and animation.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? null : AppColors.lightBackground,
          gradient: isDarkMode
              ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.scaffoldBackgroundColor,
            ],
          )
              : null,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 80.h),

                  //  logo
                  isDarkMode
                      ? Image.asset(
                    'assets/icons/png/wellness_logo.png',
                    height: 120.h,
                    fit: BoxFit.contain,
                  )
                      : Image.asset(
                    'assets/icons/png/wellness_logo.png',
                    height: 120.h,  // Reduced size for light mode
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: 5.h),

                  // App title
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 36.sp,
                      letterSpacing: 1.2,
                      color: isDarkMode
                          ? AppColors.primary
                          : AppColors.lightTextPrimary,
                      shadows: isDarkMode ? [
                        Shadow(
                          offset: const Offset(1, 2),
                          blurRadius: 6,
                          color: Colors.black.withAlpha(38),
                        ),
                      ] : [],  // Remove shadow in light mode
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 3.h),

                  // App subtitle
                  Text(
                    AppStrings.appSubtitle,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextPrimary,  // Darker in light mode (use primary text color)
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 36.h),

                  // Circular progress indicator
                  CircularProgressIndicator(
                    strokeWidth: 4.w,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode
                          ? AppColors.primary
                          : AppColors.lightTextPrimary,
                    ),
                  ),


                  SizedBox(height: 150.h),

                  // App version info
                  Text(
                    AppStrings.appVersion,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15.sp,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextPrimary,  // Darker in light mode
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(),

                  // Copyright footer
                  Column(
                    children: [
                      Text(
                        AppStrings.copyright,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Nunito',
                          fontSize: 14.sp,
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextPrimary,  // Darker in light mode
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up animation controller
    super.dispose();
  }
}