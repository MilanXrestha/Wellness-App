import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import '../../../subscription/presentation/providers/premium_status_provider.dart';

class AudioCard extends StatelessWidget {
  final TipModel tip;
  final ThemeData theme;
  final bool isDarkMode;
  final String categoryName;
  final List<TipModel> featuredTips;

  const AudioCard({
    super.key,
    required this.tip,
    required this.theme,
    required this.isDarkMode,
    required this.categoryName,
    required this.featuredTips,
  });

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
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
                  // Crown without green circle background
                  Icon(
                    Icons.workspace_premium,
                    size: 64.r,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Unlock Premium Audio',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Subscribe to access exclusive wellness audio content and more!',
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
                            Navigator.pushNamed(context, RoutesName.subscriptionScreen);
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
    return Consumer<PremiumStatusProvider>(
      builder: (context, premiumStatus, child) {
        final canAccessPremium = premiumStatus.canAccessPremium;
        final isPremiumLocked = tip.isPremium && !canAccessPremium;

        return GestureDetector(
          onTap: () {
            if (isPremiumLocked) {
              _showPremiumDialog(context);
            } else {
              Navigator.pushNamed(
                context,
                RoutesName.mediaPlayerScreen,
                arguments: {
                  'tip': tip,
                  'categoryName': categoryName,
                  'featuredTips': featuredTips,
                },
              );
            }
          },
          child: Container(
            width: 300.w,
            height: 130.h,
            margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [AppColors.darkSurface, AppColors.darkSecondary.withOpacity(0.9)]
                    : [AppColors.lightBackground, AppColors.lightSurface],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? AppColors.shadow : AppColors.shadow.withOpacity(0.3),
                  offset: Offset(0, 4.h),
                  blurRadius: 8.r,
                  spreadRadius: isDarkMode ? 0.5.r : 0.r,
                ),
              ],
              border: Border.all(
                color: isDarkMode ? AppColors.darkTextSecondary.withOpacity(0.3) : AppColors.lightTextSecondary.withOpacity(0.2),
                width: isDarkMode ? 1.5.w : 1.w,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Multiple music note backgrounds
                  Positioned(
                    right: 5.w,
                    bottom: -5.h,
                    child: Opacity(
                      opacity: isDarkMode ? 0.15 : 0.08,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 140.sp,
                        color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withAlpha(178),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10.w,
                    top: 40.h,
                    child: Opacity(
                      opacity: isDarkMode ? 0.15 : 0.08,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 60.sp,
                        color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withAlpha(178),
                      ),
                    ),
                  ),
                  // Main content
                  Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Thumbnail
                        Hero(
                          tag: 'audio-thumbnail-${tip.tipsId}',
                          child: Container(
                            width: 90.w,
                            height: 90.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDarkMode
                                    ? [AppColors.darkSurface, AppColors.darkBackground]
                                    : [AppColors.lightSurface, AppColors.lightBackground],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.1),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: tip.thumbnailUrl != null && tip.thumbnailUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: tip.thumbnailUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    color: AppColors.primary,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.music_note_rounded,
                                  color: AppColors.primary.withOpacity(0.5),
                                  size: 36.sp,
                                ),
                              )
                                  : Icon(
                                Icons.music_note_rounded,
                                color: AppColors.primary.withOpacity(0.5),
                                size: 36.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Text content and play button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tip.tipsTitle,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.h),
                              // Play button
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)],
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 4.r,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: AppColors.lightBackground,
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Play',
                                      style: TextStyle(
                                        color: AppColors.lightBackground,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Duration chip
                  if (tip.mediaDuration != null && tip.mediaDuration!.isNotEmpty)
                    Positioned(
                      bottom: 12.h,
                      right: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.darkSecondary.withOpacity(0.9) : AppColors.lightBackground.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow.withOpacity(0.1),
                              blurRadius: 4.r,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              tip.mediaDuration!,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
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
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              size: 14.sp,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Subtle border highlight
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                            width: 1.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Shimmer loading effect for the cards
class AudioCardShimmer extends StatelessWidget {
  final bool isDarkMode;

  const AudioCardShimmer({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.w,
      height: 130.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [AppColors.darkSurface, AppColors.darkBackground]
              : [AppColors.lightBackground, AppColors.lightSurface],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? AppColors.shadow : AppColors.shadow.withOpacity(0.3),
            blurRadius: 12.r,
            spreadRadius: 1.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // Album art placeholder
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkTextSecondary.withOpacity(0.1) : AppColors.lightTextSecondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 15.h,
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.darkTextSecondary.withOpacity(0.1) : AppColors.lightTextSecondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: 120.w,
                    height: 13.h,
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.darkTextSecondary.withOpacity(0.1) : AppColors.lightTextSecondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}