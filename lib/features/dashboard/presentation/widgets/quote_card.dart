import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                'Premium Quote',
                style: widget.theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          content: Text(
            'Subscribe now and unlock wisdom like this one!',
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
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 5.r,
                spreadRadius: 0.5.r,
                offset: Offset(0, 1.h),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 5.r,
                spreadRadius: 0.5.r,
                offset: Offset(1.w, 0),
              ),
            ],
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
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
                    borderRadius: BorderRadius.circular(16.r),
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
                        child: _buildContent(context),
                      ),
                      if (widget.tip.isPremium && !canAccessPremium)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
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
                              'Unlock this premium quote to inspire your day!',
                              style: widget.theme.textTheme.labelLarge
                                  ?.copyWith(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
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

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                  text: '”',
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
          ),
          SizedBox(height: 12.h),
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
                          color: AppColors.lightSurface.withOpacity(0.4),
                          blurRadius: 8.r,
                          spreadRadius: 3.r,
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
                          color: widget.isDarkMode
                              ? AppColors.darkSurface.withOpacity(0.5)
                              : Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2.w),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 40.r,
                          height: 40.r,
                          color: widget.isDarkMode
                              ? AppColors.darkSurface.withOpacity(0.5)
                              : Colors.grey[300],
                          child: Icon(
                            Icons.broken_image,
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
    );
  }
}
