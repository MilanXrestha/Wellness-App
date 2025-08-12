import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/core/resources/colors.dart';

/// Reusable text field widget for authentication screens.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String iconPath;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.iconPath,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: isDarkMode
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14.sp,
          ),
          floatingLabelStyle: TextStyle(
            color: isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
            fontFamily: 'Poppins',
            fontSize: 16.sp,
          ),
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor,
          border: isDarkMode
              ? theme.inputDecorationTheme.border
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppColors.lightTextSecondary,
                    width: 1.w,
                  ),
                ),
          focusedBorder: isDarkMode
              ? theme.inputDecorationTheme.focusedBorder
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppColors.lightTextPrimary,
                    width: 1.5.w,
                  ),
                ),
          enabledBorder: isDarkMode
              ? theme.inputDecorationTheme.enabledBorder
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppColors.lightTextSecondary,
                    width: 1.w,
                  ),
                ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(12.w),
            child: SvgPicture.asset(
              iconPath,
              width: 21.w,
              height: 21.h,
              colorFilter: ColorFilter.mode(
                isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.lightSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
          suffixIcon: suffixIcon,
        ),
        style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Poppins'),
      ),
    );
  }
}
