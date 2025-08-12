import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      TweenSequenceItem(tween: Tween<double>(begin: -0.05, end: 0.05), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.05, end: 0), weight: 25),
    ]).animate(_shakeController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context).canAccessPremium;
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/svg/ic_crown.svg',
                width: 24.r,
                height: 24.r,
                semanticsLabel: 'Premium content',
              ),
              SizedBox(width: 8.w),
              Text(
                'Premium Tip',
                style: widget.theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          content: Text(
            'Subscribe now and unlock powerful tips like this one!',
            style: widget.theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16.sp,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: widget.theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, RoutesName.subscriptionScreen);
              },
              style: widget.theme.elevatedButtonTheme.style?.copyWith(
                padding: MaterialStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                textStyle: MaterialStateProperty.all(
                  widget.theme.textTheme.labelLarge?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: const Text('Subscribe'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumStatusProvider>(
      builder: (context, premiumStatus, child) {
        final canAccessPremium = premiumStatus.canAccessPremium;
        return Container(
          width: 280.w,
          height: 160.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: widget.isDarkMode ? AppColors.darkSurface.withOpacity(0.1) : Colors.black.withAlpha(6),
                blurRadius: 5.r,
                spreadRadius: 0.5.r,
                offset: Offset(0, 1.h),
              ),
              BoxShadow(
                color: widget.isDarkMode ? AppColors.darkSurface.withOpacity(0.1) : Colors.black.withAlpha(6),
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
                color: widget.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
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
                                      color: AppColors.primary.withOpacity(0.1),
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
                                          widget.isDarkMode ? AppColors.primary : Colors.black,
                                          BlendMode.srcIn,
                                        ),
                                        semanticsLabel: 'Inspiration icon',
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        widget.tip.tipsTitle,
                                        style: widget.theme.textTheme.bodyMedium?.copyWith(
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
                                  style: widget.theme.textTheme.bodySmall?.copyWith(
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
                      if (widget.tip.isPremium && !canAccessPremium)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            child: Container(
                              color: widget.isDarkMode
                                  ? AppColors.darkSurface.withOpacity(0.7)
                                  : AppColors.lightBackground.withOpacity(0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.tip.isPremium && !canAccessPremium)
                  Positioned.fill(
                    child: InkWell(
                      onTap: () {
                        _showPremiumDialog(context);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _shakeAnimation.value,
                                child: SvgPicture.asset(
                                  'assets/icons/svg/ic_crown.svg',
                                  width: 40.r,
                                  height: 40.r,
                                  semanticsLabel: 'Premium content',
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'Access premium wisdom. Subscribe to unlock this tip!',
                              style: widget.theme.textTheme.labelLarge?.copyWith(
                                color: widget.isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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