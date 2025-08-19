import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/core/resources/colors.dart';

import '../../../../generated/app_localizations.dart';

/// Reusable buttons for authentication screens.
class AuthButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onEmailPressed;
  final VoidCallback? onGooglePressed;
  final String emailButtonText;
  final String googleButtonText;

  const AuthButtons({
    super.key,
    required this.isLoading,
    this.onEmailPressed,
    this.onGooglePressed,
    required this.emailButtonText,
    required this.googleButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        ElevatedButton(
          onPressed: isLoading ? null : onEmailPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode
                ? AppColors.primary
                : AppColors.colorPrimaryLight,
            foregroundColor: isDarkMode
                ? AppColors.darkTextPrimary
                : AppColors.lightBackground,
            minimumSize: Size(double.infinity, 50.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: isDarkMode ? 2 : 0,
          ),
          child: Text(
            emailButtonText,
            style: theme.textTheme.labelLarge?.copyWith(
              fontFamily: 'Poppins',
              color: isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightBackground,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.colorScheme.onSurfaceVariant,
                thickness: 1.w,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                AppLocalizations.of(context)!.or,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.onSurfaceVariant,
                thickness: 1.w,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        OutlinedButton(
          onPressed: isLoading ? null : onGooglePressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDarkMode
                  ? AppColors.primary
                  : AppColors.colorPrimaryLight,
              width: 1.5.w,
            ),
            minimumSize: Size(double.infinity, 50.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 14.h),
            foregroundColor: isDarkMode
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: SvgPicture.asset(
                  'assets/icons/svg/ic_google.svg',
                  width: 24.w,
                  height: 24.h,
                  colorFilter: ColorFilter.mode(
                    isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Text(
                googleButtonText,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFamily: 'Poppins',
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
