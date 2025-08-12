import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer widget for the dashboard screen, mimicking the layout during data loading.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildShimmerItem(
                          width: 48,
                          height: 48,
                          isCircular: true,
                          isDarkMode: isDarkMode,
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerItem(
                              width: 120,
                              height: 22,
                              isDarkMode: isDarkMode,
                            ),
                            SizedBox(height: 4.h),
                            _buildShimmerItem(
                              width: 80,
                              height: 14,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildShimmerItem(
                          width: 44,
                          height: 44,
                          isCircular: true,
                          isDarkMode: isDarkMode,
                        ),
                        Positioned(
                          right: -4.w,
                          top: -4.h,
                          child: _buildShimmerItem(
                            width: 20,
                            height: 20,
                            isCircular: true,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Featured quotes section
                SizedBox(height: 20.h),
                _buildSectionHeader(isDarkMode: isDarkMode),
                SizedBox(height: 12.h),
                _buildShimmerItem(
                  width: double.infinity,
                  height: 160,
                  isDarkMode: isDarkMode,
                ),
                // Categories section
                SizedBox(height: 20.h),
                _buildSectionHeader(isDarkMode: isDarkMode),
                SizedBox(height: 12.h),
                _buildHorizontalList(
                  placeholderCount: 5,
                  width: 120,
                  height: 130,
                  isDarkMode: isDarkMode,
                ),
                // Reminder card
                SizedBox(height: 20.h),
                _buildShimmerItem(
                  width: double.infinity,
                  height: 120,
                  isDarkMode: isDarkMode,
                ),
                // Category tips sections
                for (int i = 0; i < 5; i++) ...[
                  SizedBox(height: 20.h),
                  _buildSectionHeader(isDarkMode: isDarkMode),
                  SizedBox(height: 12.h),
                  _buildHorizontalList(
                    placeholderCount: 3,
                    width: 260,
                    height: 150,
                    isDarkMode: isDarkMode,
                  ),
                ],
                SizedBox(height: 80.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a shimmer placeholder item.
  Widget _buildShimmerItem({
    required double width,
    required double height,
    required bool isDarkMode,
    bool isCircular = false,
  }) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[400]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      child: Container(
        width: width.w,
        height: height.h,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: isCircular ? null : BorderRadius.circular(12.r),
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }

  /// Builds a shimmer section header.
  Widget _buildSectionHeader({required bool isDarkMode}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildShimmerItem(width: 150, height: 18, isDarkMode: isDarkMode),
        _buildShimmerItem(width: 60, height: 14, isDarkMode: isDarkMode),
      ],
    );
  }

  /// Builds a horizontal list of shimmer placeholders.
  Widget _buildHorizontalList({
    required int placeholderCount,
    required double width,
    required double height,
    required bool isDarkMode,
  }) {
    return SizedBox(
      height: height.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            placeholderCount,
            (_) => Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: _buildShimmerItem(
                width: width,
                height: height,
                isDarkMode: isDarkMode,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
