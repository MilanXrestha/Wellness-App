import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/favorites/data/models/favorite_model.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import 'dart:developer';
import '../widgets/video_player_card.dart';

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
  bool _isLoading = true;

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
    _initializeVideoPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
    });
  }

  void _initializeVideoPlayer() {
    if (widget.tip.videoUrl != null && widget.tip.videoUrl!.isNotEmpty) {
      log(
        'Initializing BetterPlayer with URL: ${widget.tip.videoUrl}',
        name: 'VideoPlayerScreen',
      );

      final configuration = BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.cover,
        aspectRatio: 9 / 16,
        looping: false,
        autoDetectFullscreenDeviceOrientation: true,
        autoDetectFullscreenAspectRatio: true,
        handleLifecycle: true,
        placeholder: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
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
          controlBarColor: Colors.black.withOpacity(0.7),
          progressBarPlayedColor: AppColors.primary,
          progressBarHandleColor: AppColors.primary,
          progressBarBufferedColor: AppColors.primary.withOpacity(0.3),
          progressBarBackgroundColor: Colors.white.withOpacity(0.2),
          loadingColor: AppColors.primary,
          overflowModalColor: Colors.black87,
          overflowModalTextColor: Colors.white,
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
          setState(() {
            _videoError = event.parameters?['error']?.toString() ?? 'Unknown error';
            _isLoading = false;
          });
        } else if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
          setState(() {
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
      setState(() {
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
    favoritesProvider
        .loadFavorites(userId)
        .then((_) {
      if (mounted) {
        setState(() {
          _isFavorite = favoritesProvider.isFavorite(
            widget.tip.tipsId,
            userId,
          );
        });
      }
    })
        .catchError((error) {
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
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();

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
      );
      favoritesProvider.addFavorite(favorite);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 300.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [Colors.grey[900]!, Colors.black]
              : [Colors.grey[300]!, Colors.grey[400]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60.sp,
              color: AppColors.primary,
            ),
            SizedBox(height: 20.h),
            Text(
              'Failed to load video',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              _videoError ?? 'Please check your connection',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16.sp,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30.h),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _videoError = null;
                });
                _initializeVideoPlayer();
              },
              icon: Icon(Icons.refresh_rounded, size: 24.sp),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBlockedScreen() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [AppColors.darkBackground, Colors.black]
                : [AppColors.lightBackground, Colors.grey[100]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 28.sp,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Premium Content',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(30.r),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            size: 80.sp,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          'Premium Content',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'Unlock this exclusive video with a premium membership.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18.sp,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 50.h),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/subscription');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 50.w,
                              vertical: 18.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Upgrade Now',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18.sp,
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
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final canAccessPremium = Provider.of<PremiumStatusProvider>(context).canAccessPremium;
    final isPremiumContent = widget.tip.isPremium;

    if (isPremiumContent && !canAccessPremium) {
      return _buildPremiumBlockedScreen();
    }

    return Scaffold(
      backgroundColor: isDarkMode ? null : AppColors.lightBackground, // Remove background color for dark mode gradient
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 28.sp,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Video Player Section
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  if (_controller != null && _videoError == null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: BetterPlayer(controller: _controller!),
                      ),
                    )
                  else if (_isLoading)
                    Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3.w,
                        ),
                      ),
                    )
                  else
                    _buildErrorWidget(),
                ],
              ),
            ),
            // Content Section
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? null
                      : AppColors.lightBackground, // Remove background for dark mode gradient
                  gradient: isDarkMode
                      ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
                  )
                      : null,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                ),
                padding: EdgeInsets.all(20.w),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Favorite Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.tip.tipsTitle ?? 'Untitled',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 21.sp,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleFavorite,
                            child: Container(
                              padding: EdgeInsets.all(14.r),
                              decoration: BoxDecoration(
                                color: _isFavorite
                                    ? Colors.green.withOpacity(0.1)
                                    : isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: _isFavorite
                                    ? Colors.green
                                    : isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                size: 25.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Category Name Chip
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          widget.categoryName,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (widget.tip.isPremium) ...[
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber[600]!, Colors.amber[800]!],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                size: 16.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 20.h),
                      // Author Section
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            children: [
                              Container(
                                width: 50.w,
                                height: 50.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    (widget.tip.tipsAuthor ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Presented by',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14.sp,
                                        color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    Text(
                                      widget.tip.tipsAuthor ?? 'Unknown Author',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Description Section
                      if (widget.tip.tipsDescription != null && widget.tip.tipsDescription!.isNotEmpty) ...[
                        Text(
                          'Video Insights',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          widget.tip.tipsDescription!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16.sp,
                            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Divider(
                          color: isDarkMode ? AppColors.darkTextSecondary.withOpacity(0.2) : AppColors.lightTextSecondary.withOpacity(0.2),
                          thickness: 1.0,
                          height: 20.h,
                        ),
                      ],
                      // Related Videos Section using VideoPlayerCard
                      if (widget.featuredTips.length > 1) ...[
                        Text(
                          'More from this category',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          height: 150.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: widget.featuredTips.length,
                            itemBuilder: (context, index) {
                              final relatedTip = widget.featuredTips[index];
                              if (relatedTip.tipsId == widget.tip.tipsId) {
                                return const SizedBox.shrink();
                              }
                              return VideoPlayerCard(
                                key: ValueKey(relatedTip.tipsId),
                                tip: relatedTip,
                                categoryName: widget.categoryName,
                                featuredTips: widget.featuredTips,
                              );
                            },
                          ),
                        ),
                      ],
                      SizedBox(height: 40.h),
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
}