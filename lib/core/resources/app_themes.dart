import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

/// Defines the application theme configurations for light and dark modes.
class AppTheme {
  /// ========================
  /// LIGHT THEME CONFIGURATION
  /// ========================
  static ThemeData lightTheme() {
    return ThemeData(
      fontFamily: 'Poppins',

      // ---------- Base Scaffold Colors ----------
      scaffoldBackgroundColor: AppColors.lightBackground,
      // Background for screens
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.lightSecondary,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
        error: AppColors.error,
      ),

      // ---------- Icon Styling ----------
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStateProperty.all(AppColors.lightTextPrimary),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.lightTextPrimary),

      // ---------- AppBar Styling ----------
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          color: AppColors.lightTextPrimary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,

        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white, // White background
          statusBarIconBrightness: Brightness.dark, // Dark icons for light mode
          statusBarBrightness: Brightness.light, // iOS equivalent
        ),
      ),

      // ---------- Bottom Sheet ----------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
      ),

      // ---------- Input Fields ----------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(12.r)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(12.r)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.lightTextPrimary, width: 1.w),
          borderRadius: BorderRadius.all(Radius.circular(12.r)),
        ),
        hintStyle: TextStyle(color: AppColors.lightTextHint),
        labelStyle: TextStyle(color: AppColors.lightTextSecondary),
        floatingLabelStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontFamily: 'Poppins',
          fontSize: 16.sp,
        ),
      ),

      // ---------- Time Picker ----------
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.lightBackground,
        hourMinuteTextColor: AppColors.lightTextPrimary,
        hourMinuteColor: AppColors.lightSurface,
        dayPeriodTextColor: AppColors.lightTextPrimary,
        dialBackgroundColor: AppColors.lightSurface,
        dialHandColor: AppColors.lightTextPrimary,
        dialTextColor: AppColors.lightTextPrimary,
        entryModeIconColor: AppColors.lightTextPrimary,
        helpTextStyle: TextStyle(color: AppColors.lightTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.r)),
        ),
      ),

      // ---------- Typography ----------
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        labelLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp,
          color: AppColors.lightTextSecondary,
        ),
      ),

      // ---------- Elevated Buttons ----------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.lightTextPrimary),
          foregroundColor: WidgetStateProperty.all(AppColors.lightBackground),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
        ),
      ),

      // ---------- Outlined Buttons ----------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            BorderSide(color: AppColors.lightTextPrimary, width: 1.w),
          ),
          foregroundColor: WidgetStateProperty.all(AppColors.lightTextPrimary),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
        ),
      ),

      // ---------- Text Buttons ----------
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.lightTextPrimary),
        ),
      ),

      // ---------- Scrollbars & Misc ----------
      hoverColor: Colors.transparent,
      useMaterial3: true,
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        thickness: WidgetStateProperty.all(5.w),
        thumbColor: WidgetStateProperty.all(AppColors.lightTextPrimary),
        radius: Radius.circular(3.r),
      ),
    );
  }

  /// ========================
  /// DARK THEME CONFIGURATION
  /// ========================
  static ThemeData darkTheme() {
    return ThemeData(
      fontFamily: 'Poppins',

      // ---------- Base Scaffold Colors ----------
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        error: AppColors.error,
      ),

      // ---------- Icon Styling ----------
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStateProperty.all(AppColors.darkTextSecondary),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.darkTextSecondary),

      // ---------- AppBar Styling ----------
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          color: AppColors.darkTextPrimary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),

      // ---------- Bottom Sheet ----------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 3,
      ),

      // ---------- Input Fields ----------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.all(Radius.circular(12.r)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.all(Radius.circular(12.r)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2.w),
          borderRadius: BorderRadius.all(Radius.circular(12.r)),
        ),
        hintStyle: TextStyle(color: AppColors.darkTextSecondary),
        labelStyle: TextStyle(color: AppColors.darkTextSecondary),
        floatingLabelStyle: TextStyle(
          color: AppColors.primary,
          fontFamily: 'Poppins',
          fontSize: 16.sp,
        ),
      ),

      // ---------- Time Picker ----------
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.darkSurface,
        hourMinuteTextColor: AppColors.darkTextPrimary,
        hourMinuteColor: AppColors.darkTextSecondary,
        dayPeriodTextColor: AppColors.darkTextSecondary,
        dialBackgroundColor: AppColors.darkBackground,
        dialHandColor: AppColors.darkTextPrimary,
        dialTextColor: AppColors.darkTextPrimary,
        entryModeIconColor: AppColors.darkTextSecondary,
        helpTextStyle: TextStyle(color: AppColors.darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24.r)),
        ),
      ),

      // ---------- Typography ----------
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 16.sp,
        ),
        headlineMedium: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
        labelLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp,
          color: AppColors.darkTextSecondary,
        ),
      ),

      // ---------- Elevated Buttons ----------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.primary),
          foregroundColor: WidgetStateProperty.all(AppColors.darkTextPrimary),
          elevation: WidgetStateProperty.all(2),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
        ),
      ),

      // ---------- Outlined Buttons ----------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(
            BorderSide(color: AppColors.primary, width: 1.5.w),
          ),
          foregroundColor: WidgetStateProperty.all(AppColors.darkTextPrimary),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
        ),
      ),

      // ---------- Text Buttons ----------
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.darkTextSecondary),
        ),
      ),

      // ---------- Scrollbars & Misc ----------
      hoverColor: Colors.transparent,
      useMaterial3: true,
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        thickness: WidgetStateProperty.all(3.w),
        thumbColor: WidgetStateProperty.all(AppColors.primary),
        radius: Radius.circular(3.r),
      ),
    );
  }
}
