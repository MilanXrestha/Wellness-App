import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/generated/app_localizations.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';

class PlaylistBottomSheet extends StatelessWidget {
  final List<TipModel> featuredTips;
  final String categoryName;
  final ValueNotifier<int> currentTrackIndex;
  final Function(int) onTrackSelected;

  const PlaylistBottomSheet({
    super.key,
    required this.featuredTips,
    required this.categoryName,
    required this.currentTrackIndex,
    required this.onTrackSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20.r,
                offset: Offset(0, -5.h),
              ),
            ],
          ),
          child: Column(
            children: [
            // Drag handle
            Container(
            width: 48.w,
            height: 5.h,
            margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkTextSecondary.withOpacity(0.3)
                  : AppColors.lightTextSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.5.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.queue_music_rounded,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName, // Changed to categoryName
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'Poppins',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${featuredTips.length} ${AppLocalizations.of(context)!.tracks}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20.sp,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Divider
          Container(
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
          SizedBox(height: 8.h),
          // Scrollable list of tracks
          Expanded(
            child: featuredTips.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off_rounded,
                    size: 64.sp,
                    color: isDarkMode
                        ? AppColors.darkTextSecondary.withOpacity(0.3)
                        : AppColors.lightTextSecondary.withOpacity(0.3),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    AppLocalizations.of(context)!.noDataAvailable,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Poppins',
                      fontSize: 16.sp,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
                : Consumer<PremiumStatusProvider>(
              builder: (context, premiumStatus, child) {
                final canAccessPremium = premiumStatus.canAccessPremium;
                return ValueListenableBuilder<int>(
                  valueListenable: currentTrackIndex,
                  builder: (context, currentIndex, child) {
                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        left: 20.w,
                        right: 20.w,
                        top: 8.h,
                        bottom: 20.h,
                      ),
                      itemCount: featuredTips.length,
                      itemBuilder: (context, index) {
                        final tip = featuredTips[index];
                        final isCurrentTrack = index == currentIndex;
                        final isPremiumLocked = tip.isPremium && !canAccessPremium;

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onTrackSelected(index),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: isCurrentTrack
                                      ? AppColors.primary.withOpacity(0.1)
                                      : isDarkMode
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: isCurrentTrack
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 2.w,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail image with playing indicator
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 48.w,
                                          height: 48.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: isCurrentTrack
                                                ? Border.all(
                                              color: AppColors.primary,
                                              width: 2.w,
                                            )
                                                : null,
                                          ),
                                          child: ClipOval(
                                            child: tip.thumbnailUrl != null
                                                ? Image.network(
                                              tip.thumbnailUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      .withOpacity(0.1)
                                                      : Colors.black
                                                      .withOpacity(0.05),
                                                  child: Icon(
                                                    Icons.music_note_rounded,
                                                    color: isDarkMode
                                                        ? AppColors
                                                        .darkTextSecondary
                                                        : AppColors
                                                        .lightTextSecondary,
                                                    size: 24.sp,
                                                  ),
                                                );
                                              },
                                            )
                                                : Container(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  .withOpacity(0.1)
                                                  : Colors.black
                                                  .withOpacity(0.05),
                                              child: Icon(
                                                Icons.music_note_rounded,
                                                color: isDarkMode
                                                    ? AppColors
                                                    .darkTextSecondary
                                                    : AppColors
                                                    .lightTextSecondary,
                                                size: 24.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isCurrentTrack && !isPremiumLocked)
                                          Container(
                                            width: 48.w,
                                            height: 48.w,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black.withOpacity(0.6),
                                            ),
                                            child: Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 28.sp,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: 12.w),
                                    // Track info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tip.tipsTitle ?? 'Untitled',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontFamily: 'Poppins',
                                              fontSize: 16.sp,
                                              fontWeight: isCurrentTrack
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isCurrentTrack
                                                  ? AppColors.primary
                                                  : isDarkMode
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors
                                                  .lightTextPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            tip.tipsAuthor ?? 'Unknown Author',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontFamily: 'Poppins',
                                              fontSize: 14.sp,
                                              color: isDarkMode
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Duration or status
                                    if (isPremiumLocked || isCurrentTrack)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: isPremiumLocked
                                              ? LinearGradient(
                                            colors: [
                                              Colors.yellow.shade700,
                                              Colors.amber.shade500,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                              : LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primary
                                                  .withOpacity(0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(20.r),
                                        ),
                                        child: Text(
                                          isPremiumLocked
                                              ? AppLocalizations.of(context)!
                                              .premium
                                              : 'NOW PLAYING',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )),
            ],
          ),
        );
      },
    );
  }
}