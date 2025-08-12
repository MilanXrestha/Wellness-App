import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/resources/colors.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  final String viewAllText;
  final ThemeData theme;
  final bool isDarkMode;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    required this.onViewAll,
    required this.viewAllText,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Poppins',
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: Text(
            viewAllText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              color: isDarkMode ? AppColors.primary : Colors.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
