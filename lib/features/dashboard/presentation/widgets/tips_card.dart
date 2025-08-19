import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';

import '../../../subscription/presentation/providers/premium_status_provider.dart';

class TipCard extends StatefulWidget {
  final TipModel tip;
  final ThemeData theme;
  final bool isDarkMode;
  final String categoryName;
  final List<TipModel> featuredTips;

  const TipCard({
    super.key,
    required this.tip,
    required this.theme,
    required this.isDarkMode,
    required this.categoryName,
    required this.featuredTips,
  });

  @override
  TipCardState createState() => TipCardState();
}

class TipCardState extends State<TipCard> with SingleTickerProviderStateMixin {
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
                    'Unlock Premium Tip',
                    style: widget.theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Subscribe now and unlock powerful tips like this one!',
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

        return Container(
          width: 295.w,
          height: 150.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: widget.isDarkMode
                    ? AppColors.darkSurface.withOpacity(0.1)
                    : Colors.black.withAlpha(6),
                blurRadius: 5.r,
                spreadRadius: 0.5.r,
                offset: Offset(0, 1.h),
              ),
              BoxShadow(
                color: widget.isDarkMode
                    ? AppColors.darkSurface.withOpacity(0.1)
                    : Colors.black.withAlpha(6),
                blurRadius: 5.r,
                spreadRadius: 0.5.r,
                offset: Offset(1.w, 0),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: widget.isDarkMode
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
                width: 1.w,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? null : Colors.white,
                    gradient: widget.isDarkMode
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.darkSurface,
                              AppColors.darkSurface.withOpacity(0.7),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Stack(
                    children: [
                      InkWell(
                        onTap: () {
                          if (widget.tip.isPremium && !canAccessPremium) {
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
                        child: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.only(bottom: 6.h),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.darkSecondary
                                          .withOpacity(0.1),
                                      width: 1.w,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 8.w),
                                      child: SvgPicture.asset(
                                        'assets/icons/svg/ic_inspiration.svg',
                                        width: 24.r,
                                        height: 24.r,
                                        colorFilter: ColorFilter.mode(
                                          widget.isDarkMode
                                              ? AppColors.primary
                                              : Colors.black,
                                          BlendMode.srcIn,
                                        ),
                                        semanticsLabel: 'Inspiration icon',
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        widget.tip.tipsTitle,
                                        style: widget.theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontSize: 14.sp,
                                              fontFamily: 'Poppins',
                                              color: widget.isDarkMode
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Flexible(
                                child: Text(
                                  widget.tip.tipsDescription,
                                  style: widget.theme.textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 14.sp,
                                        fontFamily: 'Poppins',
                                        color: widget.isDarkMode
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                  maxLines: 10,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Premium locked overlay
                if (isPremiumLocked)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        _showPremiumDialog(context);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
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
                                          Icons.workspace_premium,
                                          size: 40.sp,
                                          color: const Color(0xFFFFD700),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Tap for mindful inspiration',
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
                  ),

                // Premium indicator badge
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
              ],
            ),
          ),
        );
      },
    );
  }
}
