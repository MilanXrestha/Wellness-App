import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable widget for displaying the app logo.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Theme.of(context).brightness == Brightness.light
          ? 'assets/icons/png/wellness_logo_black.png'
          : 'assets/icons/png/wellness_logo.png',
      height: 80.h,
      fit: BoxFit.contain,
    );
  }
}
