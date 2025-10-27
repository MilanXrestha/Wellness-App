import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/resources/colors.dart';
import '../../data/models/tips_model.dart' show TipModel;

class TipContentWidget extends StatelessWidget {
  final TipModel tip;
  final bool isDarkMode;
  final bool isFullScreen;

  const TipContentWidget({
    super.key,
    required this.tip,
    required this.isDarkMode,
    required this.isFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuote = tip.tipsType == 'quote';
    final authorIconSize = isFullScreen
        ? (isQuote ? 40.r : 250.r)
        : (isQuote ? 32.r : 200.r);

    // For quotes, move title closer to top quote icon
    final quoteTitleTopOffset = -32.h; // adjust to move text further up

    return ClipRRect(
      borderRadius: BorderRadius.circular(22.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDarkMode ? 1.0 : 2.0, // lighter blur for dark mode
          sigmaY: isDarkMode ? 1.0 : 2.0,
        ),
        child: Container(
          padding: EdgeInsets.only(
            top: isQuote ? 48.h : (isFullScreen ? 24.w : 16.w),
            left: isFullScreen ? 24.w : 16.w,
            right: isFullScreen ? 24.w : 16.w,
            bottom: isFullScreen ? 24.w : 16.w,
          ),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.25),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative quote marks for quotes
              if (isQuote) ...[
                Positioned(
                  bottom: 100.h,
                  right: -15.w,
                  child: Icon(
                    Icons.format_quote,
                    size: 100.sp,
                    color: isDarkMode
                        ? AppColors.primary.withOpacity(0.6)
                        : AppColors.overlay.withOpacity(0.6),
                  ),
                ),
                Positioned(
                  top: 20.h,
                  left: -15.w,
                  child: Transform.rotate(
                    angle: 3.14,
                    child: Icon(
                      Icons.format_quote,
                      size: 100.sp,
                      color: isDarkMode
                          ? AppColors.primary.withOpacity(0.6)
                          : AppColors.overlay.withOpacity(0.6),
                    ),
                  ),
                ),
              ],

              // Main content
              Column(
                mainAxisAlignment:
                isQuote ? MainAxisAlignment.center : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isQuote &&
                      (tip.authorIcon != null || tip.tipsAuthor.isNotEmpty)) ...[
                    Padding(
                      padding: EdgeInsets.only(top: 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (tip.authorIcon != null)
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.15),
                                      blurRadius: 12.r,
                                      spreadRadius: 2.r,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: tip.authorIcon!,
                                    width: authorIconSize,
                                    height: authorIconSize,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: authorIconSize,
                                      height: authorIconSize,
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[300],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.w,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          width: authorIconSize,
                                          height: authorIconSize,
                                          color: isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.grey[300],
                                          child: Icon(
                                            Icons.broken_image,
                                            color: isDarkMode
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                            size: authorIconSize / 2,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          if (tip.tipsAuthor.isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            Text(
                              tip.tipsAuthor,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (isQuote)
                    Transform.translate(
                      offset: Offset(0, quoteTitleTopOffset),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: tip.tipsTitle,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isFullScreen ? 26.sp : 24.sp,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                height: 1.3,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        tip.tipsTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: isFullScreen ? 28.sp : 26.sp,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (!isQuote) ...[
                    SizedBox(height: 12.h),
                    Flexible(
                      child: Text(
                        tip.tipsDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: isFullScreen ? 20.sp : 18.sp,
                          color: isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontFamily: 'Poppins',
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),

              // Author section for quotes (fixed at bottom)
              if (isQuote) ...[
                Positioned(
                  bottom: 30.h,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tip.authorIcon != null)
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                  width: 1.5.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.grey.shade300.withOpacity(0.4),
                                    blurRadius: 8.r,
                                    spreadRadius: 2.r,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: tip.authorIcon!,
                                  width: authorIconSize,
                                  height: authorIconSize,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: authorIconSize,
                                    height: authorIconSize,
                                    color: isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                    child: Center(
                                      child: CircularProgressIndicator(strokeWidth: 2.w),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: authorIconSize,
                                    height: authorIconSize,
                                    color: isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[300],
                                    child: Icon(
                                      Icons.broken_image,
                                      color: isDarkMode
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                      size: authorIconSize / 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (tip.authorIcon != null) SizedBox(width: 12.w),
                          Flexible(
                            child: Text(
                              tip.tipsAuthor.isNotEmpty
                                  ? tip.tipsAuthor
                                  : 'Unknown Author',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: isFullScreen ? 18.sp : 16.sp,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 100.w,
                        height: 2.h,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.darkTextPrimary.withOpacity(0.5)
                              : AppColors.lightTextPrimary.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(1.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],


              // Decorative corners for non-quotes
              if (!isQuote) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 35.r,
                    height: 35.r,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDarkMode
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.25),
                          width: 2.w,
                        ),
                        left: BorderSide(
                          color: isDarkMode
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.25),
                          width: 2.w,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 35.r,
                    height: 35.r,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDarkMode
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.25),
                          width: 2.w,
                        ),
                        right: BorderSide(
                          color: isDarkMode
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.25),
                          width: 2.w,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}