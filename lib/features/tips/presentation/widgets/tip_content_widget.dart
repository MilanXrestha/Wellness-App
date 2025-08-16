import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/tips_model.dart';
import '../../../../core/resources/colors.dart';

class TipContentWidget extends StatelessWidget {
  final TipModel tip;
  final bool isDarkMode;
  final bool isFullScreen;
  final double quoteVerticalOffset; // Vertical offset for quote text
  final double authorVerticalOffset; // Vertical offset for author section

  const TipContentWidget({
    super.key,
    required this.tip,
    required this.isDarkMode,
    required this.isFullScreen,
    this.quoteVerticalOffset = -20.0, // Adjusted to move quote text up
    this.authorVerticalOffset = 25.0, // Matches existing spacing
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: EdgeInsets.only(
        top: tip.tipsType == 'quote' ? 60.h : (isFullScreen ? 16.w : 24.w), // Extra top padding for quotes to avoid overlap with 3/4 and volume icon
        left: isFullScreen ? 16.w : 24.w,
        right: isFullScreen ? 16.w : 24.w,
        bottom: isFullScreen ? 16.w : 24.w,
      ),
      child: Column(
        mainAxisAlignment:
        tip.tipsType == 'quote' ? MainAxisAlignment.center : MainAxisAlignment.start,
        crossAxisAlignment:
        tip.tipsType == 'quote' ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (tip.tipsType != 'quote') ...[
            if (tip.authorIcon != null || tip.tipsAuthor.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (tip.authorIcon != null)
                    Center(
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: tip.authorIcon!,
                          width: 250.r,
                          height: 250.r,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => SizedBox.shrink(),
                        ),
                      ),
                    ),
                  if (tip.tipsAuthor.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      tip.tipsAuthor,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            SizedBox(height: 16.h),
            Text(
              tip.tipsTitle,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Flexible(
              child: Text(
                tip.tipsDescription,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (tip.tipsType == 'quote') ...[
            Transform.translate(
              offset: Offset(0, quoteVerticalOffset.h), // Adjustable vertical position for quote
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Text(
                        '“',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: tip.tipsTitle,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        height: 1.2,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Text(
                        '”',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (tip.authorIcon != null || tip.tipsAuthor.isNotEmpty)
              Transform.translate(
                offset: Offset(0, authorVerticalOffset.h), // Adjustable vertical position for author
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tip.authorIcon != null)
                          Transform.translate(
                            offset: Offset(10.w, 0),
                            child: Container(
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
                                        ? Colors.grey.shade400.withOpacity(0.3)
                                        : Colors.grey.shade300.withOpacity(0.4),
                                    blurRadius: 8.r,
                                    spreadRadius: 2.r,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 24.r,
                                backgroundImage: NetworkImage(tip.authorIcon!),
                                backgroundColor:
                                isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                              ),
                            ),
                          ),
                        if (tip.authorIcon != null) SizedBox(width: 22.w),
                        Flexible(
                          child: Text(
                            tip.tipsAuthor,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );

    // Center the entire content for quotes
    return tip.tipsType == 'quote' ? Center(child: content) : content;
  }
}