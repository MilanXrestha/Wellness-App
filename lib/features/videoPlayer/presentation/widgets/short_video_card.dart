import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/videoPlayer/presentation/providers/shorts_provider.dart';
import 'dart:developer';

import '../../../main/presentation/screens/tab_switch_notification.dart';
import '../../domain/useCases/video_router.dart';

class ShortVideoCard extends StatefulWidget {
  final TipModel tip;
  final String categoryName;
  final List<TipModel> relatedTips;

  const ShortVideoCard({
    super.key,
    required this.tip,
    required this.categoryName,
    required this.relatedTips,
  });

  @override
  State<ShortVideoCard> createState() => _ShortVideoCardState();
}

class _ShortVideoCardState extends State<ShortVideoCard> {
  String? _thumbnailPath;
  bool _isLoadingThumbnail = false;

  // Thumbnail cache manager
  static final CacheManager _thumbnailCacheManager = CacheManager(
    Config(
      'videoThumbnailCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'thumbnailCache'),
      fileService: HttpFileService(),
    ),
  );

  @override
  void initState() {
    super.initState();
    _generateThumbnailIfNeeded();
  }

  Future<void> _generateThumbnailIfNeeded() async {
    if (widget.tip.thumbnailUrl != null &&
        widget.tip.thumbnailUrl!.isNotEmpty) {
      // Use existing thumbnail if available
      return;
    }

    if (widget.tip.videoUrl == null || widget.tip.videoUrl!.isEmpty) {
      // No video URL to generate thumbnail from
      return;
    }

    setState(() {
      _isLoadingThumbnail = true;
    });

    try {
      // Check if we have this thumbnail cached
      final cacheKey = 'thumbnail_${widget.tip.tipsId}';

      // Try to get from cache first
      final cachedFile = await _thumbnailCacheManager.getFileFromCache(
        cacheKey,
      );
      if (cachedFile != null) {
        if (mounted) {
          setState(() {
            _thumbnailPath = cachedFile.file.path;
            _isLoadingThumbnail = false;
          });
        }
        log(
          'Using cached thumbnail for ${widget.tip.tipsId}',
          name: 'ShortVideoCard',
        );
        return;
      }

      log(
        'Generating thumbnail for ${widget.tip.tipsId}',
        name: 'ShortVideoCard',
      );

      // Generate new thumbnail
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.tip.videoUrl!,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        quality: 75,
      );

      if (thumbnailPath != null) {
        // Cache the generated thumbnail
        await _thumbnailCacheManager.putFile(
          cacheKey,
          File(thumbnailPath).readAsBytesSync(),
          key: cacheKey,
        );

        log(
          'Cached new thumbnail for ${widget.tip.tipsId}',
          name: 'ShortVideoCard',
        );
      }

      if (mounted) {
        setState(() {
          _thumbnailPath = thumbnailPath;
          _isLoadingThumbnail = false;
        });
      }
    } catch (e) {
      log('Error generating thumbnail: $e', name: 'ShortVideoCard');
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }
    }
  }

  void _showPremiumDialog(BuildContext context) {
    // Premium dialog implementation remains unchanged
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
                    'Unlock Premium Short',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Subscribe to access exclusive short videos and more!',
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
    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
    ).canAccessPremium;
    final shortsProvider = Provider.of<ShortsProvider>(context, listen: false);

    return GestureDetector(
      onTap: () {
        if (widget.tip.isPremium && !canAccessPremium) {
          _showPremiumDialog(context);
        } else {
          final shortsProvider = Provider.of<ShortsProvider>(
            context,
            listen: false,
          );

          // COMPLETELY REBUILT VIDEO LIST WITH SELECTED VIDEO FIRST
          List<TipModel> newShortsList = [];

          // 1. Add the clicked video first
          newShortsList.add(widget.tip);
          log('Added selected video ${widget.tip.tipsId} at position 0', name: 'ShortVideoCard');

          // 2. Add related videos next (except the one we already added)
          if (widget.relatedTips.isNotEmpty) {
            final relatedShortsToAdd = widget.relatedTips
                .where((tip) => tip.isShort && tip.tipsId != widget.tip.tipsId)
                .toList();

            if (relatedShortsToAdd.isNotEmpty) {
              newShortsList.addAll(relatedShortsToAdd);
              log('Added ${relatedShortsToAdd.length} related videos', name: 'ShortVideoCard');
            }
          }

          // 3. Add all other existing shorts (except those we already added)
          final existingShorts = shortsProvider.shorts.where((s) =>
          s.tipsId != widget.tip.tipsId &&
              !newShortsList.any((added) => added.tipsId == s.tipsId)
          ).toList();

          if (existingShorts.isNotEmpty) {
            newShortsList.addAll(existingShorts);
            log('Added ${existingShorts.length} existing shorts', name: 'ShortVideoCard');
          }

          // Replace the entire shorts list
          shortsProvider.shorts.clear();
          shortsProvider.shorts.addAll(newShortsList);

          // Reset index to 0 and notify
          shortsProvider.changeCurrentIndex(0);
          shortsProvider.notifyListeners();

          log('Rebuilt shorts list with selected video first, total: ${newShortsList.length}',
              name: 'ShortVideoCard');

          // Check if we're in a nested route by checking if we can pop and if we're not on the root route
          final canPopToRoot = Navigator.of(context).canPop();
          final currentRoute = ModalRoute.of(context)?.settings.name;

          if (canPopToRoot && currentRoute != '/' && currentRoute != '/dashboard') {
            // We're in a nested route like category detail - use direct navigation
            log('Using direct navigation for shorts from nested route: $currentRoute',
                name: 'ShortVideoCard');

            // Use VideoRouter for direct navigation
            VideoRouter.navigateToVideoPlayer(
                context,
                widget.tip,
                widget.categoryName,
                widget.relatedTips,
                isFromCardClick: true
            );
          } else {
            // We're at the dashboard - use tab switching approach
            log('Using tab switching for shorts from dashboard', name: 'ShortVideoCard');

            // Important: Get back to main screen first
            Navigator.of(context).popUntil((route) => route.isFirst);

            // Send notification to switch tabs
            TabSwitchNotification(
              tabIndex: 2,
              tipId: widget.tip.tipsId,
            ).dispatch(context);
          }
        }
      },



      child: Container(
        width: 150.w,
        margin: EdgeInsets.only(right: 10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 200.h,
                  width: 150.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : AppColors.lightBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: _buildThumbnail(isDarkMode),
                  ),
                ),
                // Rest of the widget code remains unchanged
                // Short label
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'SHORTS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
                // Duration chip
                if (widget.tip.mediaDuration != null)
                  Positioned(
                    bottom: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        widget.tip.mediaDuration!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // View count
                Positioned(
                  bottom: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 10.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _formatViewCount(widget.tip.viewCount),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Premium indicator
                if (widget.tip.isPremium)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        size: 12.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  // Rest of the methods remain unchanged
  Widget _buildThumbnail(bool isDarkMode) {
    // If we have a local generated thumbnail
    if (_thumbnailPath != null) {
      return Image.file(
        File(_thumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          log(
            'Error displaying generated thumbnail: $error',
            name: 'ShortVideoCard',
          );
          return _buildFallbackThumbnail(isDarkMode);
        },
      );
    }

    // If we have a remote thumbnail URL
    if (widget.tip.thumbnailUrl != null &&
        widget.tip.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.tip.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingIndicator(),
        errorWidget: (context, url, error) {
          log(
            'Error loading network thumbnail: $error',
            name: 'ShortVideoCard',
          );
          return _buildFallbackThumbnail(isDarkMode);
        },
      );
    }

    // If we're still loading the thumbnail
    if (_isLoadingThumbnail) {
      return _buildLoadingIndicator();
    }

    // Fallback if no thumbnail is available
    return _buildFallbackThumbnail(isDarkMode);
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.w,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildFallbackThumbnail(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.videocam_rounded,
          size: 30.sp,
          color: isDarkMode
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  @override
  void dispose() {
    // Nothing to dispose specifically for this widget
    super.dispose();
  }
}