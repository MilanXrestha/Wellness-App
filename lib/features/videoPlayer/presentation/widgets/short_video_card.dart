import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/videoPlayer/presentation/providers/shorts_provider.dart';

import '../../../main/presentation/screens/tab_switch_notification.dart';

class ShortVideoCard extends StatelessWidget {
  final TipModel tip;
  final String categoryName;
  final List<TipModel> relatedTips;

  const ShortVideoCard({
    super.key,
    required this.tip,
    required this.categoryName,
    required this.relatedTips,
  });

  void _showPremiumDialog(BuildContext context) {
    // Premium dialog implementation remains unchanged
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [AppColors.darkSurface, AppColors.darkBackground]
                      : [AppColors.lightBackground, AppColors.lightSurface],
                ),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 20.r,
                    offset: Offset(0, 10.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 64.r,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Unlock Premium Short',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Subscribe to access exclusive short videos and more!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Not Now',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushNamed(
                              context,
                              RoutesName.subscriptionScreen,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Subscribe Now',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightBackground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
    ).canAccessPremium;
    final shortsProvider = Provider.of<ShortsProvider>(context, listen: false);

    return GestureDetector(
      onTap: () {
        if (tip.isPremium && !canAccessPremium) {
          _showPremiumDialog(context);
        } else {
          // Start with an empty list of shorts to add
          final Set<String> alreadyAddedIds = {};
          final List<TipModel> shortsToAdd = [];

          // First add the current tip if it's not already in the provider's list
          if (!shortsProvider.shorts.any((s) => s.tipsId == tip.tipsId)) {
            shortsToAdd.add(tip);
            alreadyAddedIds.add(tip.tipsId);
          }

          // Then filter and add related shorts
          if (relatedTips.isNotEmpty) {
            for (final relatedTip in relatedTips) {
              // Only add if:
              // 1. It's a short video
              // 2. It's not the current tip
              // 3. It's not already in our list to add
              // 4. It's not already in the provider's list
              if (relatedTip.isShort &&
                  relatedTip.tipsId != tip.tipsId &&
                  !alreadyAddedIds.contains(relatedTip.tipsId) &&
                  !shortsProvider.shorts.any(
                    (s) => s.tipsId == relatedTip.tipsId,
                  )) {
                shortsToAdd.add(relatedTip);
                alreadyAddedIds.add(relatedTip.tipsId);
              }
            }
          }

          // Only add shorts if we have any new ones
          if (shortsToAdd.isNotEmpty) {
            shortsProvider.addShorts(shortsToAdd);
          }

          // Get back to main screen if needed
          Navigator.of(context).popUntil((route) => route.isFirst);

          // Set the selected short
          shortsProvider.selectShortById(tip.tipsId);

          // Send notification to switch tabs
          TabSwitchNotification(
            tabIndex: 2,
            tipId: tip.tipsId,
          ).dispatch(context);
        }
      },
      child: Container(
        width: 150.w,
        margin: EdgeInsets.only(right: 10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rest of the UI code remains unchanged
            Stack(
              children: [
                Container(
                  height: 200.h,
                  width: 150.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.lightBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: tip.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: tip.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                color: AppColors.primary,
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.videocam_rounded,
                                size: 30.sp,
                                color: isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.videocam_rounded,
                              size: 30.sp,
                              color: isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                  ),
                ),
                // Short label
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'SHORTS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
                // Duration chip
                if (tip.mediaDuration != null)
                  Positioned(
                    bottom: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        tip.mediaDuration!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // View count
                Positioned(
                  bottom: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 10.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _formatViewCount(tip.viewCount),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Premium indicator
                if (tip.isPremium)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        size: 12.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            // Title
            // Text(
            //   tip.tipsTitle ?? 'Untitled',
            //   style: theme.textTheme.bodyLarge?.copyWith(
            //     fontFamily: 'Poppins',
            //     fontSize: 14.sp,
            //     fontWeight: FontWeight.w600,
            //     color: isDarkMode
            //         ? AppColors.darkTextPrimary
            //         : AppColors.lightTextPrimary,
            //   ),
            //   maxLines: 2,
            //   overflow: TextOverflow.ellipsis,
            // ),
          ],
        ),
      ),
    );
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
