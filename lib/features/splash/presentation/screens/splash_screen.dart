import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';
import '../../domain/app_initializer.dart';

/// Visual splash screen that displays branding without animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;

  // Minimum display time to prevent flashing (milliseconds)
  final int _minimumDisplayTime = 1500;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Start navigation logic in parallel
    _prepareNavigation();
  }

  Future<void> _prepareNavigation() async {
    try {
      // Determine where to navigate
      final route = await AppInitializer.instance.determineInitialRoute();

      // Calculate elapsed time and ensure minimum display
      final elapsedMs = DateTime.now().difference(_startTime).inMilliseconds;
      final remainingMs = _minimumDisplayTime - elapsedMs;

      if (remainingMs > 0) {
        // Wait for minimum display time
        await Future.delayed(Duration(milliseconds: remainingMs));
      }

      if (!mounted) return;

      // Navigate to the determined route
      setState(() => _isNavigating = true);
      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      log('Error in navigation preparation: $e');
    }
  }

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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 80.h),

                // Logo
                Image.asset(
                  'assets/icons/png/wellness_logo.png',
                  height: 120.h,
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
                    shadows: isDarkMode
                        ? [
                      Shadow(
                        offset: const Offset(1, 2),
                        blurRadius: 6,
                        color: Colors.black.withAlpha(38),
                      ),
                    ]
                        : [],
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
                        : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 50.h),

                SizedBox(height: 120.h),

                // App version info
                Text(
                  AppStrings.appVersion,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15.sp,
                    color: isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextPrimary,
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
                            : AppColors.lightTextPrimary,
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
    );
  }
}