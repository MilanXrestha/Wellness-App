import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';

class ImageCard extends StatefulWidget {
  final TipModel tip;
  final String categoryName;
  final List<TipModel> featuredTips;

  const ImageCard({
    super.key,
    required this.tip,
    required this.categoryName,
    required this.featuredTips,
  });

  @override
  _ImageCardState createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  static final CustomCacheManager _customCacheManager = CustomCacheManager();

  @override
  void initState() {
    super.initState();
    // Pre-cache images for featuredTips
    _precacheImages();
  }

  void _precacheImages() {
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;
    for (var tip in widget.featuredTips) {
      if (tip.imageUrl != null && tip.imageUrl!.isNotEmpty && (!tip.isPremium || canAccessPremium)) {
        _customCacheManager.getSingleFile(tip.imageUrl!).catchError((e) {
          debugPrint('Error precaching image ${tip.imageUrl}: $e');
        });
      }
    }
  }

  void _showPremiumDialog(BuildContext context) {
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
                    'Unlock Premium Image',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Subscribe to access exclusive wellness image content and more!',
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context).canAccessPremium;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return GestureDetector(
      onTap: () {
        if (widget.tip.isPremium && !canAccessPremium) {
          _showPremiumDialog(context);
        } else {
          final index = widget.featuredTips.indexOf(widget.tip);
          Navigator.pushNamed(
            context,
            RoutesName.imageViewerScreen,
            arguments: {
              'tip': widget.tip,
              'imageTips': widget.featuredTips,
              'initialIndex': index,
            },
          );
        }
      },
      child: Container(
        width: 150.w,
        height: 210.h,
        margin: EdgeInsets.only(right: 11.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              // Image container with CachedNetworkImage
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: isDarkMode ? AppColors.darkSurface : AppColors.lightBackground,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: widget.tip.imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: widget.tip.imageUrl!,
                    fit: BoxFit.cover,
                    cacheManager: _customCacheManager,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        color: AppColors.primary,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50.sp,
                        color: isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    fadeInDuration: const Duration(milliseconds: 300),
                    fadeOutDuration: const Duration(milliseconds: 300),
                  )
                      : Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50.sp,
                      color: isDarkMode
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),
              // Premium indicator
              if (widget.tip.isPremium)
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6.r,
                          offset: Offset(0, 3.h),
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
                            fontSize: 11.sp,
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
                      borderRadius: BorderRadius.circular(16.r),
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
  }
}

class CustomCacheManager extends CacheManager {
  static const key = 'customImageCache';
  static final CustomCacheManager _instance = CustomCacheManager._();

  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._()
      : super(Config(
    key,
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200,
    fileService: HttpFileService(),
  ));
}