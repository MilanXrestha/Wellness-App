import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellness_app/core/resources/colors.dart';

/// Reusable text field widget for authentication screens.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String iconPath;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Widget Function(bool isFocused)? suffixIconBuilder;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.iconPath,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
    this.suffixIconBuilder,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isFocused = _focusNode.hasFocus;

    return Container(
      decoration: isDarkMode
          ? null
          : BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14.sp,
          ),
          floatingLabelStyle: TextStyle(
            color: isDarkMode ? AppColors.primary : AppColors.colorPrimaryLight,
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
              color: AppColors.colorPrimaryLight,
              width: 1.5.w,
            ),
          ),
          enabledBorder: isDarkMode
              ? theme.inputDecorationTheme.enabledBorder
              : OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: AppColors.colorPrimaryLight,
              width: 1.w,
            ),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(12.w),
            child: SvgPicture.asset(
              widget.iconPath,
              width: 21.w,
              height: 21.h,
              colorFilter: ColorFilter.mode(
                isFocused
                    ? (isDarkMode
                    ? AppColors.primary
                    : AppColors.colorPrimaryLight) // focused → green
                    : (isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextHint), // unfocused → gray
                BlendMode.srcIn,
              ),
            ),
          ),
          suffixIcon: widget.suffixIconBuilder?.call(isFocused) ?? widget.suffixIcon,
        ),
        style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'Poppins'),
      ),
    );
  }
}
