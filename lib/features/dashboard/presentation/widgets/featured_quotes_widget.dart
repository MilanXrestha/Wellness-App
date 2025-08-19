import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import '../../../../core/config/routes/route_name.dart';
import '../../../../common/widgets/worm_indicator.dart';
import 'dart:developer';

/// A widget that displays a carousel of featured quotes with auto-scrolling and navigation.
class FeaturedQuotesWidget extends StatefulWidget {
  /// The list of featured tips (quotes) to display.
  final List<TipModel> featuredTips;

  /// The app's theme data for consistent styling.
  final ThemeData theme;

  /// Indicates whether dark mode is enabled.
  final bool isDarkMode;

  const FeaturedQuotesWidget({
    super.key,
    required this.featuredTips,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  FeaturedQuotesWidgetState createState() => FeaturedQuotesWidgetState();
}

class FeaturedQuotesWidgetState extends State<FeaturedQuotesWidget> {
  // Current index of the displayed quote in the PageView.
  int _currentQuoteIndex = 0;

  // Controller for the PageView to handle manual and auto-scrolling.
  final PageController _pageController = PageController();

  // Timer for auto-scrolling quotes every 10 seconds.
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    // Validate and initialize auto-scrolling if tips are valid.
    if (widget.featuredTips.isNotEmpty && widget.featuredTips.every((tip) => tip.tipsTitle.isNotEmpty)) {
      log('FeaturedQuotesWidget received valid featuredTips: ${widget.featuredTips.map((t) => t.tipsTitle).toList()}');
      _startAutoScroll();
    } else {
      log('Warning: FeaturedQuotesWidget received invalid or empty featuredTips: '
          'count=${widget.featuredTips.length}, '
          'types=${widget.featuredTips.map((t) => t.runtimeType).toList()}, '
          'valid=${widget.featuredTips.every((tip) => tip.tipsTitle.isNotEmpty)}');
    }
  }

  /// Starts the auto-scrolling timer for the quote carousel.
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.featuredTips.isNotEmpty) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted && _pageController.hasClients) {
          setState(() {
            // Move to the next quote, looping back to the start if at the end.
            _currentQuoteIndex = (_currentQuoteIndex + 1) % widget.featuredTips.length;
            _pageController.animateToPage(
              _currentQuoteIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(FeaturedQuotesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset the carousel if the featured tips list changes.
    if (widget.featuredTips != oldWidget.featuredTips || widget.featuredTips.length != oldWidget.featuredTips.length) {
      setState(() {
        _currentQuoteIndex = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      if (widget.featuredTips.isNotEmpty && widget.featuredTips.every((tip) => tip.tipsTitle.isNotEmpty)) {
        _startAutoScroll();
      } else {
        log('Warning: Updated featuredTips invalid or empty: '
            'count=${widget.featuredTips.length}, '
            'types=${widget.featuredTips.map((t) => t.runtimeType).toList()}');
      }
    }
  }

  @override
  void dispose() {
    // Clean up timer and page controller to prevent memory leaks.
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if there are valid quotes to display.
    return widget.featuredTips.isNotEmpty && widget.featuredTips.every((tip) => tip.tipsTitle.isNotEmpty)
        ? Column(
      children: [
        // Quote carousel container.
        SizedBox(
          height: 160.h,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Container(
              decoration: BoxDecoration(
                // Use solid background: darkSurface for dark mode, white for light mode.
                color: widget.isDarkMode ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  // Bottom shadow for depth.
                  BoxShadow(
                    color: widget.isDarkMode ? AppColors.darkSurface.withAlpha(26) : Colors.black.withAlpha(26), // 0.1 opacity
                    blurRadius: 6.r,
                    spreadRadius: 1.r,
                    offset: Offset(0, 2.h),
                  ),
                  // Top shadow for enhanced visual effect.
                  BoxShadow(
                    color: widget.isDarkMode ? AppColors.darkSurface.withAlpha(26) : Colors.black.withAlpha(26), // 0.1 opacity
                    blurRadius: 6.r,
                    spreadRadius: 1.r,
                    offset: Offset(0, -2.h),
                  ),
                ],
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.featuredTips.length,
                onPageChanged: (index) {
                  // Update current index for worm indicator.
                  setState(() => _currentQuoteIndex = index);
                },
                itemBuilder: (context, index) {
                  final tip = widget.featuredTips[index];
                  return InkWell(
                    // Navigate to tip detail screen on tap.
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RoutesName.tipsDetailScreen,
                        arguments: {
                          'tip': tip,
                          'categoryName': 'Featured Quotes',
                          'featuredTips': widget.featuredTips,
                          'allHealthTips': false,
                          'allQuotes': false,
                        },
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Quote text with quotation marks.
                          RichText(
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '“',
                                  style: TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: 18.sp,
                                    color: widget.isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                ),
                                TextSpan(
                                  text: tip.tipsTitle,
                                  style: widget.theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 14.sp,
                                    fontFamily: 'Poppins',
                                    color: widget.isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: '”',
                                  style: TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: 18.sp,
                                    color: widget.isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Author name and optional icon.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (tip.authorIcon != null)
                                Padding(
                                  padding: EdgeInsets.only(right: 8.w),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.lightSurface.withAlpha(102), // 0.4 opacity
                                          blurRadius: 8.r,
                                          spreadRadius: 3.r,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 20.r,
                                      // backgroundImage: NetworkImage(tip.authorIcon!),
                                      backgroundImage: CachedNetworkImageProvider(tip.authorIcon!),
                                      backgroundColor: AppColors.lightSurface.withAlpha(51), // 0.2 opacity
                                    ),
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  tip.tipsAuthor,
                                  style: widget.theme.textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'Poppins',
                                    color: widget.isDarkMode
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    fontSize: 14.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Indicator for the current quote in the carousel.
        WormIndicator(
          currentPage: _currentQuoteIndex,
          pageCount: widget.featuredTips.length,
        ),
      ],
    )
        : Container(
      // Empty state when no valid quotes are available.
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode ? AppColors.darkSurface.withAlpha(26) : Colors.black.withAlpha(15), // 0.1 opacity
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
          // Top shadow for empty state container.
          BoxShadow(
            color: widget.isDarkMode ? AppColors.darkSurface.withAlpha(26) : Colors.black.withAlpha(15), // 0.1 opacity
            blurRadius: 6.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Text(
        'No featured quotes available. Try refreshing or checking your preferences.',
        style: widget.theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'Poppins',
          color: widget.isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          fontSize: 13.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}