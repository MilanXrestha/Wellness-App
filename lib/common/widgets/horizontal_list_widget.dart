import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/resources/colors.dart';

class HorizontalListWidget<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final String emptyMessage;
  final ThemeData theme;
  final bool isDarkMode;
  final int placeholderCount;

  const HorizontalListWidget({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.theme,
    required this.isDarkMode,
    this.placeholderCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isNotEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // important: allows taller cards
          children: items
              .asMap()
              .entries
              .map(
                (entry) => Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: itemBuilder(entry.value),
            ),
          )
              .toList(),
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? AppColors.darkSurface.withOpacity(0.1)
                  : Colors.black.withAlpha(38),
              blurRadius: 4.r,
              spreadRadius: 0.5.r,
              offset: Offset(0, 1.h),
            ),
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 4.r,
                spreadRadius: 0.5.r,
                offset: Offset(0, -1.h),
              ),
          ],
        ),
        child: Text(
          emptyMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            color: isDarkMode
                ? AppColors.darkTextSecondary
                : Colors.grey.shade600,
            fontSize: 13.sp,
          ),
        ),
      );
    }
  }
}
