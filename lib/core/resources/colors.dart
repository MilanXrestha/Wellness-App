import 'package:flutter/material.dart';

/// Defines the color palette used across the application for light and dark themes.
class AppColors {
  // =====================
  // Core Colors (Common)
  // =====================
  /// Primary green color representing wellbeing.
  static const Color primary = Color(0xFF4CAF50);

  /// Red color for error states and alerts.
  static const Color error = Color(0xFFD32F2F);

  /// Blue accent color used for non-admin roles and highlights.
  static const Color accentBlue = Color(0xFF2196F3);

  /// Subtle black shadow color for cards and icons.
  static const Color shadow = Color(0x1F000000);

  /// Semi-transparent black used for loading overlays.
  static const Color overlay = Color(0x42000000);


  // =====================
  // Dark Theme Colors
  // =====================
  /// Secondary dark gray used for accents in dark theme.
  static const Color darkSecondary = Color(0xFF262626);

  /// Pure black background for dark theme scaffolds.
  static const Color darkBackground = Color(0xFF000000);

  /// Semi-transparent white for primary text/icons in dark theme.
  static const Color darkTextPrimary = Color(0xB3FFFFFF);

  /// White70 color for secondary text/icons in dark theme.
  static const Color darkTextSecondary = Color(0xB3FFFFFF);

  /// Medium gray color for hint text in dark theme.
  static const Color darkTextHint = Color(0xFF9E9E9E);

  /// Dark gray for surfaces like cards and inputs in dark theme.
  static const Color darkSurface = Color(0xFF1E1E1E);


  // =====================
  // Light Theme Colors
  // =====================
  /// Pure white background for light theme scaffolds.
  static const Color lightBackground = Color(0xFFFFFFFF);

  static const Color colorPrimaryLight = Color(0xFF43A047); // Green 600

  /// Very light gray used for input fields and cards.
  static const Color lightSurface = Color(0xFFF5F5F5);

  /// Dark gray used for secondary accents in light theme.
  static const Color lightSecondary = Color(0xFF333333);

  /// Pure black color for primary text/icons in light theme.
  static const Color lightTextPrimary = Color(0xFF222222);

  /// Medium gray color for secondary text/icons in light theme.
  static const Color lightTextSecondary = Color(0xFF666666);

  /// Light gray color for hint text in light theme.
  static const Color lightTextHint = Color(0xFF9E9E9E);
}
