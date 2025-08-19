import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/favorites/data/models/favorite_model.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import '../widgets/video_player_card.dart';
import 'dart:developer';

class VideoPlayerScreen extends StatefulWidget {
  final TipModel tip;
  final String categoryName;
  final List<TipModel> featuredTips;

  const VideoPlayerScreen({
    super.key,
    required this.tip,
    required this.categoryName,
    required this.featuredTips,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  BetterPlayerController? _controller;
  bool _isFavorite = false;
  String? _videoError;
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _favoriteScaleAnimation;
  bool _isLoading = true;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _initializeVideoPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _initializeVideoPlayer() {
    if (widget.tip.videoUrl != null && widget.tip.videoUrl!.isNotEmpty) {
      log(
        'Initializing BetterPlayer with URL: ${widget.tip.videoUrl}',
        name: 'VideoPlayerScreen',
      );

      final configuration = BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.cover, // Changed to BoxFit.cover to cover entire height
        looping: false,
        autoDetectFullscreenDeviceOrientation: true,
        autoDetectFullscreenAspectRatio: true,
        handleLifecycle: true,
        placeholder: Container(
          color: AppColors.darkBackground,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3.w,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          log('BetterPlayer error: $errorMessage', name: 'VideoPlayerScreen');
          return _buildErrorWidget();
        },
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableSkips: true,
          enableFullscreen: true,
          enablePip: true,
          enablePlaybackSpeed: true,
          enableQualities: true,
          enableSubtitles: false,
          enableAudioTracks: false,
          playIcon: Icons.play_arrow_rounded,
          pauseIcon: Icons.pause_rounded,
          fullscreenEnableIcon: Icons.fullscreen_rounded,
          fullscreenDisableIcon: Icons.fullscreen_exit_rounded,
          pipMenuIcon: Icons.picture_in_picture_rounded,
          skipBackIcon: Icons.replay_10_rounded,
          skipForwardIcon: Icons.forward_10_rounded,
          controlBarColor: AppColors.overlay,
          progressBarPlayedColor: AppColors.primary,
          progressBarHandleColor: AppColors.primary,
          progressBarBufferedColor: AppColors.primary.withOpacity(0.3),
          progressBarBackgroundColor: AppColors.lightBackground.withOpacity(0.2),
          loadingColor: AppColors.primary,
          overflowModalColor: AppColors.darkSurface,
          overflowModalTextColor: AppColors.lightBackground,
          overflowMenuIconsColor: AppColors.primary,
        ),
      );

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.tip.videoUrl!,
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
          maxCacheSize: 100 * 1024 * 1024,
          maxCacheFileSize: 50 * 1024 * 1024,
        ),
      );

      _controller = BetterPlayerController(
        configuration,
        betterPlayerDataSource: dataSource,
      )..addEventsListener((event) {
        if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
          log(
            'BetterPlayer exception: ${event.parameters}',
            name: 'VideoPlayerScreen',
          );
          _safeSetState(() {
            _videoError = event.parameters?['error']?.toString() ?? 'Unknown error';
            _isLoading = false;
          });
        } else if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
          _safeSetState(() {
            _videoError = null;
            _isLoading = false;
          });
          _animationController.forward();
        }
      });
    } else {
      log(
        'Invalid or missing video URL for tip: ${widget.tip.tipsId}',
        name: 'VideoPlayerScreen',
      );
      _safeSetState(() {
        _videoError = 'No video URL provided';
        _isLoading = false;
      });
    }
  }

  void _initializeUser() {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    if (userId.isEmpty) {
      log(
        'No user ID found, skipping favorite initialization',
        name: 'VideoPlayerScreen',
      );
      return;
    }
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    favoritesProvider.loadFavorites(userId).then((_) {
      if (mounted) {
        _safeSetState(() {
          _isFavorite = favoritesProvider.isFavorite(
            widget.tip.tipsId,
            userId,
          );
        });
      }
    }).catchError((error) {
      log(
        'Error loading favorites for tip ${widget.tip.tipsId}: $error',
        name: 'VideoPlayerScreen',
      );
    });
  }

  void _toggleFavorite() {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    if (userId.isEmpty) {
      log(
        'No user ID found, cannot toggle favorite',
        name: 'VideoPlayerScreen',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to add favorites'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    _animationController.forward(from: 0.0);

    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    if (_isFavorite) {
      final favorite = favoritesProvider.favorites.firstWhere(
            (f) => f.tipId == widget.tip.tipsId && f.userId == userId,
        orElse: () => FavoriteModel(id: '', tipId: widget.tip.tipsId, userId: userId),
      );
      favoritesProvider.deleteFavorite(favorite.id);
    } else {
      final favorite = FavoriteModel(
        id: '${userId}_${widget.tip.tipsId}',
        tipId: widget.tip.tipsId,
        userId: userId,
        createdAt: DateTime.now(),
      );
      favoritesProvider.addFavorite(favorite);
    }
    _safeSetState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 300.h,
      color: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to load video',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _videoError ?? 'Please check your connection',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                _safeSetState(() {
                  _isLoading = true;
                  _videoError = null;
                });
                _initializeVideoPlayer();
              },
              icon: Icon(Icons.refresh_rounded, size: 20.sp),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.lightBackground,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBlockedScreen() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  size: 28.sp,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.categoryName,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 64.sp,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        'Premium Content',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Unlock this exclusive video with a premium membership.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16.sp,
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40.h),
                      ElevatedButton(
                        onPressed: () {
                          log(
                            'Navigating to subscription screen',
                            name: 'VideoPlayerScreen',
                          );
                          Navigator.pushNamed(
                            context,
                            RoutesName.subscriptionScreen,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.lightBackground,
                          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Upgrade Now',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    log('Disposing VideoPlayerScreen', name: 'VideoPlayerScreen');
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context).canAccessPremium;
    final isPremiumContent = widget.tip.isPremium;

    if (isPremiumContent && !canAccessPremium) {
      return _buildPremiumBlockedScreen();
    }

    // Filter related videos by tipType == "video" and matching categoryId
    final relatedVideos = widget.featuredTips
        .asMap()
        .entries
        .where(
          (entry) =>
      entry.value.tipsId != widget.tip.tipsId &&
          entry.value.tipsType == 'video' &&
          entry.value.categoryId == widget.tip.categoryId,
    )
        .map((entry) => {'index': entry.key, 'tip': entry.value})
        .toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // App Bar
            AppBar(
              backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  size: 28.sp,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.categoryName,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
            // Video Player Section
            Expanded(
              flex: 2,
              child: Container(
                color: AppColors.darkBackground,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_controller != null && _videoError == null)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: BetterPlayer(
                          controller: _controller!,
                        ),
                      )
                    else if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3.w,
                        ),
                      )
                    else
                      _buildErrorWidget(),
                  ],
                ),
              ),
            ),
            // Content Section
            Expanded(
              flex: 3,
              child: Container(
                color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.h),
                        // Title and Favorite Button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.tip.tipsTitle ?? 'Untitled',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            ScaleTransition(
                              scale: _favoriteScaleAnimation,
                              child: GestureDetector(
                                onTap: _toggleFavorite,
                                child: Container(
                                  padding: EdgeInsets.all(10.r),
                                  decoration: BoxDecoration(
                                    color: _isFavorite
                                        ? AppColors.primary.withOpacity(0.1)
                                        : isDarkMode
                                        ? AppColors.darkSurface.withOpacity(0.2)
                                        : AppColors.lightSurface.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: _isFavorite
                                        ? AppColors.primary
                                        : isDarkMode
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Category and Premium Chips
                        Wrap(
                          spacing: 8.w,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Text(
                                widget.categoryName,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (widget.tip.isPremium)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary, AppColors.colorPrimaryLight],
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.workspace_premium,
                                      size: 14.sp,
                                      color: AppColors.lightBackground,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Premium',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.lightBackground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // Author Section
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.darkSurface.withOpacity(0.9)
                                : AppColors.lightSurface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isDarkMode
                                  ? AppColors.darkTextSecondary.withOpacity(0.2)
                                  : AppColors.lightTextSecondary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    (widget.tip.tipsAuthor ?? 'U').toUpperCase()[0],
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Presented by',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12.sp,
                                        color: isDarkMode
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    Text(
                                      widget.tip.tipsAuthor ?? 'Unknown Author',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Description Section
                        if (widget.tip.tipsDescription != null && widget.tip.tipsDescription!.isNotEmpty) ...[
                          Text(
                            'Description',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          AnimatedCrossFade(
                            firstChild: Text(
                              widget.tip.tipsDescription!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(
                              widget.tip.tipsDescription!,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                                color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                height: 1.5,
                              ),
                            ),
                            crossFadeState: _isDescriptionExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          if (widget.tip.tipsDescription!.length > 100)
                            GestureDetector(
                              onTap: () {
                                _safeSetState(() {
                                  _isDescriptionExpanded = !_isDescriptionExpanded;
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                child: Text(
                                  _isDescriptionExpanded ? 'Show less' : 'Show more',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: 16.h),
                          Divider(
                            color: isDarkMode
                                ? AppColors.darkTextSecondary.withOpacity(0.2)
                                : AppColors.lightTextSecondary.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ],
                        // Related Videos Section
                        if (relatedVideos.isNotEmpty) ...[
                          SizedBox(height: 16.h),
                          Text(
                            'More from ${widget.categoryName}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            height: 160.h,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: relatedVideos.length,
                              itemBuilder: (context, index) {
                                final relatedTip = relatedVideos[index]['tip'] as TipModel;
                                return Padding(
                                  padding: EdgeInsets.only(right: 12.w),
                                  child: VideoPlayerCard(
                                    key: ValueKey(relatedTip.tipsId),
                                    tip: relatedTip,
                                    categoryName: widget.categoryName,
                                    featuredTips: widget.featuredTips,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}