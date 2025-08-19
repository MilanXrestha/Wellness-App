import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';

import '../../../subscription/presentation/providers/premium_status_provider.dart';

class QuoteCard extends StatefulWidget {
  final TipModel tip;
  final ThemeData theme;
  final bool isDarkMode;
  final String categoryName;
  final List<TipModel> featuredTips;

  const QuoteCard({
    super.key,
    required this.tip,
    required this.theme,
    required this.isDarkMode,
    required this.categoryName,
    required this.featuredTips,
  });

  @override
  QuoteCardState createState() => QuoteCardState();
}

class QuoteCardState extends State<QuoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -0.05), weight: 25),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.05, end: 0.05),
        weight: 50,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 0.05, end: 0), weight: 25),
    ]).animate(_shakeController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
    ).canAccessPremium;
    if (widget.tip.isPremium && !canAccessPremium) {
      _shakeController.repeat();
    } else {
      _shakeController.stop();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

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
                  colors: widget.isDarkMode
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
                    'Unlock Premium Quote',
                    style: widget.theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Subscribe now and unlock wisdom like this one!',
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      color: widget.isDarkMode
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
                            'Subscribe',
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
        final isPremiumLocked = widget.tip.isPremium && !canAccessPremium;

        return GestureDetector(
          onTap: () {
            if (isPremiumLocked) {
              _showPremiumDialog(context);
            } else {
              Navigator.pushNamed(
                context,
                RoutesName.tipsDetailScreen,
                arguments: {
                  'tip': widget.tip,
                  'categoryName': widget.categoryName,
                  'featuredTips': widget.featuredTips,
                  'allHealthTips': false,
                  'allQuotes': false,
                },
              );
            }
          },
          child: Container(
            width: 290.w,
            height: 150.h,
            margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isDarkMode
                    ? [AppColors.darkSurface, AppColors.darkSecondary.withOpacity(0.9)]
                    : [AppColors.lightBackground, AppColors.lightSurface],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isDarkMode ? AppColors.shadow : AppColors.shadow.withOpacity(0.3),
                  offset: Offset(0, 2.h),
                  blurRadius: 6.r,
                  spreadRadius: widget.isDarkMode ? 0.5.r : 0.r,
                ),
              ],
              border: Border.all(
                color: widget.isDarkMode
                    ? AppColors.darkTextSecondary.withOpacity(0.3)
                    : AppColors.lightTextSecondary.withOpacity(0.2),
                width: widget.isDarkMode ? 1.5.w : 1.w,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Top-left quote mark background (opening quotes)
                  Positioned(
                    left: -10.w,
                    top: -15.h,
                    child: Opacity(
                      opacity: widget.isDarkMode ? 0.15 : 0.08,
                      child: Transform(
                        transform: Matrix4.rotationY(3.14159), // Flipped horizontally (PI radians)
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.format_quote,
                          size: 100.sp,
                          color: widget.isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withAlpha(178),
                        ),
                      ),
                    ),
                  ),

                  // Bottom-right quote mark background (closing quotes)
                  Positioned(
                    right: -10.w,
                    bottom: -10.h,
                    child: Opacity(
                      opacity: widget.isDarkMode ? 0.15 : 0.08,
                      child: Transform(
                        transform: Matrix4.rotationY(0), // Flipped horizontally (PI radians)
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.format_quote,
                          size: 100.sp,
                          color: widget.isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withAlpha(178),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Quote text
                        Flexible(
                          child: _buildQuoteText(),
                        ),
                        SizedBox(height: 12.h),

                        // Author info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.tip.authorIcon != null)
                              Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.1),
                                        blurRadius: 8.r,
                                        offset: Offset(0, 2.h),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20.r),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.tip.authorIcon!,
                                      width: 40.r,
                                      height: 40.r,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 40.r,
                                        height: 40.r,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: widget.isDarkMode
                                              ? AppColors.darkSurface.withOpacity(0.5)
                                              : Colors.grey[300],
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.w,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        width: 40.r,
                                        height: 40.r,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: widget.isDarkMode
                                              ? AppColors.darkSurface.withOpacity(0.5)
                                              : Colors.grey[300],
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: widget.isDarkMode
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                          size: 24.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Flexible(
                              child: Text(
                                widget.tip.tipsAuthor,
                                style: widget.theme.textTheme.bodyMedium?.copyWith(
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

                  // Premium locked overlay
                  if (isPremiumLocked)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                          child: Container(
                            color: widget.isDarkMode
                                ? AppColors.darkSurface.withOpacity(0.4)
                                : AppColors.lightBackground.withOpacity(0.4),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _shakeController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _shakeAnimation.value,
                                        child: Icon(
                                          FontAwesomeIcons.crown,
                                          size: 40.sp,
                                            color: const Color(0xFFFFD700),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Tap to Unlock',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: widget.isDarkMode
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Premium indicator
                  if (widget.tip.isPremium)
                    Positioned(
                      top: 6.h,
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
                          mainAxisSize: MainAxisSize.min,
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
                            color: AppColors.darkSecondary.withOpacity(0.1),
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

  Widget _buildQuoteText() {
    return RichText(
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: '"',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 18.sp,
              color: widget.isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: widget.tip.tipsTitle,
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
            text: '"',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 18.sp,
              color: widget.isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}