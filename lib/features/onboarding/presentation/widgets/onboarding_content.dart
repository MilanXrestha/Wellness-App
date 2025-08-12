import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/resources/colors.dart';
import '../../data/models/onboarding_model.dart';

/// A stateless widget that displays the content for an onboarding screen.
///
/// It shows a Lottie animation, a title, and a description, styled according
/// to the current theme (light or dark).
class OnboardingContent extends StatelessWidget {
  /// The data model containing the content for this onboarding page.
  final OnboardingModel model;

  /// Creates an instance of [OnboardingContent] with the required onboarding [model].
  const OnboardingContent({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w), // Horizontal padding for layout consistency
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center contents vertically
        children: [
          // Animated onboarding illustration using Lottie
          Lottie.asset(
            model.lottieAsset,
            height: 300.h,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 10.h), // Spacing between animation and title

          // Onboarding title text, styled bold and with color adapting to theme
          Text(
            model.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h), // Spacing between title and description

          // Onboarding description text, styled with secondary color based on theme
          Text(
            model.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}