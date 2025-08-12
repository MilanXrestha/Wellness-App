import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/resources/colors.dart';

/// A worm-style page indicator used in onboarding screens.
///
/// Highlights the current page with an elongated active dot,
/// while inactive dots remain smaller.
class WormIndicator extends StatelessWidget {
  /// Index of the currently active page.
  final int currentPage;

  /// Total number of pages to display.
  final int pageCount;

  const WormIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final double inactiveSize = 10.w;
    final double activeWidth = 34.w;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          height: inactiveSize,
          width: currentPage == index ? activeWidth : inactiveSize,
          decoration: BoxDecoration(
            color: currentPage == index
                ? (isDarkMode
                      ? AppColors.primary
                      : AppColors.lightTextPrimary) // Active dot color
                : (isDarkMode
                      ? Color.alphaBlend(
                          theme.colorScheme.onSurface.withAlpha(76),
                          theme.colorScheme.surface,
                        )
                      : AppColors.lightTextSecondary), // Inactive dot color
            borderRadius: BorderRadius.circular(inactiveSize  / 2),
          ),
        );
      }),
    );
  }
}
