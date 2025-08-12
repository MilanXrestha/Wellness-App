import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/resources/colors.dart';

/// A customizable bottom sheet for displaying success or error messages.
class CustomBottomSheet {
  /// Shows a bottom sheet with a success or error message and an OK button.
  static void show({
    required BuildContext context,
    required String message,
    required bool isSuccess,
    VoidCallback? onOkPressed,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !isSuccess,
      backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (bottomSheetContext) => _BottomSheetContent(
        message: message,
        isSuccess: isSuccess,
        isDarkMode: isDarkMode,
        theme: theme,
        onOkPressed: () {
          Navigator.of(bottomSheetContext).pop();
          onOkPressed?.call();
        },
      ),
    );
  }
}

/// Internal widget to build the bottom sheet content.
class _BottomSheetContent extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final bool isDarkMode;
  final ThemeData theme;
  final VoidCallback onOkPressed;

  const _BottomSheetContent({
    required this.message,
    required this.isSuccess,
    required this.isDarkMode,
    required this.theme,
    required this.onOkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24.w,
        right: 24.w,
        top: 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildIcon(),
          _buildTitle(),
          _buildMessage(),
          _buildButton(),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  /// Builds the drag handle at the top of the bottom sheet.
  Widget _buildHandle() {
    return Container(
      width: 40.w,
      height: 4.h,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: theme.dividerColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
    );
  }

  /// Builds the success or error icon.
  Widget _buildIcon() {
    return Icon(
      isSuccess ? Icons.check_circle_outline : Icons.error_outline,
      size: 48.sp,
      color: isSuccess ? AppColors.primary : AppColors.error,
    );
  }

  /// Builds the title (Success or Error).
  Widget _buildTitle() {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 12.h),
      child: Text(
        isSuccess ? 'Success' : 'Error',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontFamily: 'Poppins',
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: isSuccess ? AppColors.primary : AppColors.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds the message text.
  Widget _buildMessage() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'Poppins',
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Builds the OK button.
  Widget _buildButton() {
    return ElevatedButton(
      onPressed: onOkPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSuccess ? AppColors.primary : AppColors.error,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 48.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Text(
        'OK',
        style: theme.textTheme.labelLarge?.copyWith(
          fontFamily: 'Poppins',
          fontSize: 16.sp,
          color: Colors.white,
        ),
      ),
    );
  }
}