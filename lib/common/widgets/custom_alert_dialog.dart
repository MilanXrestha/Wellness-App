import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/resources/strings.dart';

/// A utility class for displaying a custom alert dialog with theme support.
class CustomAlertDialog {
  /// Shows a custom alert dialog with a title, message, and confirm/cancel buttons.
  /// Returns true if confirmed, false if canceled or dismissed.
  static Future<bool> show({
    required BuildContext context,
    required String message,
    String title = AppStrings.alertDialogTitle,
    String cancelText = AppStrings.cancel,
    String confirmText = AppStrings.confirm,
    VoidCallback? onConfirm,
  }) async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    // Store context to avoid async gap issues
    final dialogContext = context;

    final result = await showGeneralDialog<bool>(
      context: dialogContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(128),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          backgroundColor: isDarkMode
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: isDarkMode ? 0 : 8,
          // Only apply elevation in light mode
          shadowColor: isDarkMode
              ? Colors
                    .transparent // No shadow in dark mode
              : AppColors.primary.withAlpha(50),
          // subtle shadow in light mode
          child: _buildDialogContent(
            context: context,
            title: title,
            message: message,
            cancelText: cancelText,
            confirmText: confirmText,
            onConfirm: onConfirm,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            isDarkMode: isDarkMode,
            theme: theme,
          ),
        );
      },
    );
    return result ??
        false; // Return false if dialog is dismissed without confirmation
  }

  /// Builds the content of the dialog with title, message, and action buttons.
  static Widget _buildDialogContent({
    required BuildContext context,
    required String title,
    required String message,
    required String cancelText,
    required String confirmText,
    required VoidCallback? onConfirm,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDarkMode,
    required ThemeData theme,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Stack(
        children: [
          // Close Icon
          Positioned(
            top: -15.h,
            right: -15.w,
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: textColor, size: 22.sp),
              splashRadius: 24.r,
              onPressed: () =>
                  Navigator.of(context).pop(false), // Return false on close
            ),
          ),

          // Dialog Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 14.h),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 26.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      // Return false on cancel
                      style: theme.elevatedButtonTheme.style?.copyWith(
                        backgroundColor: WidgetStateProperty.all(
                          isDarkMode
                              ? AppColors.darkTextSecondary.withAlpha(51)
                              : AppColors.lightTextSecondary.withAlpha(51),
                        ),
                        foregroundColor: WidgetStateProperty.all(textColor),
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (onConfirm != null) onConfirm();
                        Navigator.of(
                          context,
                        ).pop(true); // Return true on confirm
                      },
                      style: theme.elevatedButtonTheme.style?.copyWith(
                        backgroundColor: WidgetStateProperty.all(
                          AppColors.primary,
                        ),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
