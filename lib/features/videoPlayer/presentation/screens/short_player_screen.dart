import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as Math;

import '../../data/models/comments_model.dart';
import '../providers/shorts_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../favorites/data/models/favorite_model.dart';

class ShortsPlayerScreen extends StatefulWidget {
  final String categoryName;
  final TipModel? initialTip;
  final List<TipModel>? relatedTips;
  final bool tabActive;
  final ValueChanged<bool>? onFullScreenChanged;

  const ShortsPlayerScreen({
    super.key,
    required this.categoryName,
    this.initialTip,
    this.relatedTips,
    required this.tabActive,
    this.onFullScreenChanged,
  });

  @override
  State<ShortsPlayerScreen> createState() => ShortsPlayerScreenState();
}

class ShortsPlayerScreenState extends State<ShortsPlayerScreen> {
  late PageController _pageController;
  bool _isCommentsVisible = false;
  bool _showUI = true;
  bool _isMuted = false;
  bool _showVolumeIcon = false;
  IconData _volumeIcon = Icons.volume_up;
  final AuthService _authService = AuthService();
  bool _isFullscreen = false;
  bool _isPageChanging = false;

  // Custom cache manager for videos
  final CacheManager customCacheManager = CacheManager(
    Config(
      'shortsCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'shortsCache'),
      fileService: HttpFileService(),
    ),
  );

  // Keep track of cached video files
  final Map<String, File?> _cachedVideoFiles = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    if (widget.tabActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final shortsProvider = Provider.of<ShortsProvider>(
          context,
          listen: false,
        );
        if (shortsProvider.shorts.isEmpty) {
          shortsProvider.loadShorts().then((_) {
            if (widget.initialTip != null) {
              _setInitialPage(shortsProvider);
            }
            _preloadVideos(shortsProvider.shorts);
          });
        } else {
          if (widget.initialTip != null) {
            _setInitialPage(shortsProvider);
          }
          _preloadVideos(shortsProvider.shorts);
        }
      });
    }
  }

  // Enhanced preloading - preload 5 videos ahead and 1 behind current position
  void _preloadVideos(List<TipModel> shorts, [int currentIndex = 0]) {
    // Define the range of videos to preload
    final startIdx = (currentIndex - 1).clamp(0, shorts.length - 1);
    final endIdx = (currentIndex + 5).clamp(0, shorts.length - 1);

    log('Preloading videos from index $startIdx to $endIdx', name: 'ShortsPlayerScreen');

    for (int i = startIdx; i <= endIdx; i++) {
      final short = shorts[i];
      if (short.videoUrl != null && short.videoUrl!.isNotEmpty) {
        // Check if we already have this cached or are caching it
        if (!_cachedVideoFiles.containsKey(short.tipsId)) {
          log('Preloading video: ${short.videoUrl}', name: 'ShortsPlayerScreen');
          _cachedVideoFiles[short.tipsId] = null; // Mark as "loading"

          // Fetch and store the file
          customCacheManager.getSingleFile(short.videoUrl!).then((file) {
            _cachedVideoFiles[short.tipsId] = file;
            log('Video cached: ${short.tipsId}', name: 'ShortsPlayerScreen');
          }).catchError((e) {
            log('Failed to cache video ${short.tipsId}: $e', name: 'ShortsPlayerScreen');
          });
        }
      }
    }
  }

  void _setInitialPage(ShortsProvider shortsProvider) {
    final index = shortsProvider.shorts.indexWhere(
          (short) => short.tipsId == widget.initialTip!.tipsId,
    );
    if (index != -1 && _pageController.hasClients) {
      _pageController.jumpToPage(index);
      shortsProvider.changeCurrentIndex(index);
      _preloadVideos(shortsProvider.shorts, index);
    }
  }

  @override
  void didUpdateWidget(ShortsPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabActive && !oldWidget.tabActive) {
      final shortsProvider = Provider.of<ShortsProvider>(
        context,
        listen: false,
      );
      if (shortsProvider.shorts.isEmpty) {
        shortsProvider.loadShorts().then((_) {
          if (widget.initialTip != null) {
            _setInitialPage(shortsProvider);
          }
          _preloadVideos(shortsProvider.shorts);
        });
      } else {
        if (widget.initialTip != null) {
          _setInitialPage(shortsProvider);
        } else {
          _preloadVideos(shortsProvider.shorts, shortsProvider.currentIndex);
        }
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _isPageChanging = true;
      _showUI = true;
    });

    final shortsProvider = Provider.of<ShortsProvider>(context, listen: false);
    shortsProvider.changeCurrentIndex(index);

    // Preload next videos
    _preloadVideos(shortsProvider.shorts, index);

    // Reset page changing flag after a short delay to ensure video plays
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isPageChanging = false;
        });
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _volumeIcon = _isMuted ? Icons.volume_off : Icons.volume_up;
      _showVolumeIcon = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showVolumeIcon = false;
        });
      }
    });
  }

  void _onScreenTap() {
    if (!_showUI) {
      setState(() {
        _showUI = true;
        widget.onFullScreenChanged?.call(true);
        _isFullscreen = false;
      });
    } else {
      _toggleMute();
    }
  }

  void _enterFullScreen() {
    setState(() {
      _showUI = false;
      widget.onFullScreenChanged?.call(false);
      _isFullscreen = true;
    });
  }

  void _exitFullScreen() {
    setState(() {
      _showUI = true;
      widget.onFullScreenChanged?.call(true);
      _isFullscreen = false;
    });
  }

  void _showComments() {
    setState(() {
      _isCommentsVisible = true;
    });
  }

  void _hideComments() {
    setState(() {
      _isCommentsVisible = false;
    });
  }

  void pauseVideo() {
    // Handled in _ShortVideoPageState
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bottom padding for navigation bar - 50.h as requested
    final bottomPadding = _isFullscreen ? 0.0 : 50.h;

    return Consumer<ShortsProvider>(
      builder: (context, shortsProvider, child) {
        if (!widget.tabActive) {
          return Container(
            color: Colors.black,
            child: const Center(child: SizedBox()),
          );
        }

        if (shortsProvider.isLoading) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (shortsProvider.error != null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                shortsProvider.error!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        final shorts =
        widget.relatedTips != null && widget.relatedTips!.isNotEmpty
            ? widget.relatedTips!
            : shortsProvider.shorts;
        if (shorts.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No shorts available',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          // Always use dark background regardless of theme
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Main content with bottom padding
              Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  itemCount: shorts.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final short = shorts[index];
                    final isPremium = short.isPremium;
                    final canAccessPremium = Provider.of<PremiumStatusProvider>(
                      context,
                    ).canAccessPremium;
                    final isLocked = isPremium && !canAccessPremium;
                    final isActive = widget.tabActive &&
                        index == shortsProvider.currentIndex;

                    // Pass the cached file to the player if available
                    final cachedFile = _cachedVideoFiles[short.tipsId];

                    return _ShortVideoPage(
                      key: ValueKey(short.tipsId),
                      tip: short,
                      videoUrl: isLocked ? null : short.videoUrl,
                      isActive: isActive,
                      showUI: _showUI,
                      isLiked: shortsProvider.isShortLiked(short.tipsId),
                      isMuted: _isMuted,
                      showVolumeIcon: _showVolumeIcon,
                      volumeIcon: _volumeIcon,
                      onLike: () => shortsProvider.toggleLike(short.tipsId, context),
                      onComment: _showComments,
                      onShare: () {},
                      onScreenTap: _onScreenTap,
                      onEnterFullScreen: _enterFullScreen,
                      onExitFullScreen: _exitFullScreen,
                      cacheManager: customCacheManager,
                      cachedVideoFile: cachedFile,
                      isPageChanging: _isPageChanging,
                    );
                  },
                ),
              ),
              if (_isCommentsVisible)
                _CommentsSheet(
                  onClose: _hideComments,
                  tipsId: shortsProvider.currentShort?.tipsId ?? '',
                ),
              if (shortsProvider.isLoadingMore)
                Positioned(
                  bottom: bottomPadding + 20.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ShortVideoPage extends StatefulWidget {
  final TipModel tip;
  final String? videoUrl;
  final bool isActive;
  final bool showUI;
  final bool isLiked;
  final bool isMuted;
  final bool showVolumeIcon;
  final IconData volumeIcon;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onScreenTap;
  final VoidCallback onEnterFullScreen;
  final VoidCallback onExitFullScreen;
  final CacheManager cacheManager;
  final File? cachedVideoFile;
  final bool isPageChanging;

  const _ShortVideoPage({
    Key? key,
    required this.tip,
    this.videoUrl,
    required this.isActive,
    required this.showUI,
    required this.isLiked,
    required this.isMuted,
    required this.showVolumeIcon,
    required this.volumeIcon,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onScreenTap,
    required this.onEnterFullScreen,
    required this.onExitFullScreen,
    required this.cacheManager,
    this.cachedVideoFile,
    required this.isPageChanging,
  }) : super(key: key);

  @override
  _ShortVideoPageState createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<_ShortVideoPage>
    with AutomaticKeepAliveClientMixin {
  BetterPlayerController? _controller;
  bool _initialized = false;
  File? _cachedVideoFile;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isPrepared = false;

  @override
  void initState() {
    super.initState();
    // Start with the cached file if available
    _cachedVideoFile = widget.cachedVideoFile;

    // Don't show loading if we already have the cached file
    if (_cachedVideoFile != null) {
      _isLoading = false;
      _isPrepared = true;
    }

    if (widget.isActive) {
      _initializePlayer();
    } else {
      // If not active, still try to prepare the video without showing loading
      _prepareVideo();
    }
  }

  @override
  void didUpdateWidget(_ShortVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update cached file if it changed
    if (widget.cachedVideoFile != oldWidget.cachedVideoFile) {
      _cachedVideoFile = widget.cachedVideoFile;
    }

    // Handle active state changes - improve swiping
    if (widget.isActive && !oldWidget.isActive) {
      // When becoming active
      if (_controller != null) {
        // If controller exists, just play it
        _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
        _controller!.play();
        setState(() {
          _isLoading = false;
        });
        log('Playing existing controller for ${widget.tip.tipsId}', name: 'ShortVideoPage');
      } else {
        // If no controller, initialize it
        _initializePlayer();
        log('Initializing player for ${widget.tip.tipsId}', name: 'ShortVideoPage');
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      // When becoming inactive, pause but don't dispose
      if (_controller != null) {
        _controller!.pause();
        log('Pausing controller for ${widget.tip.tipsId}', name: 'ShortVideoPage');
      }
    }

    // Handle URL changes
    if (widget.videoUrl != oldWidget.videoUrl && widget.isActive) {
      _disposePlayer();
      _initializePlayer();
    }

    // Handle mute state changes
    if (widget.isMuted != oldWidget.isMuted && _controller != null) {
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
    }

    // Play video when page change completes
    if (!widget.isPageChanging && oldWidget.isPageChanging && widget.isActive) {
      if (_controller != null) {
        log('Playing after page change for ${widget.tip.tipsId}', name: 'ShortVideoPage');
        _controller!.play();
      } else if (!_initialized && widget.videoUrl != null) {
        log('Initializing after page change for ${widget.tip.tipsId}', name: 'ShortVideoPage');
        _initializePlayer();
      }
    }
  }

  // Prepare video without showing loading indicator
  void _prepareVideo() {
    if (_initialized || widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return;
    }

    // Use cached file if we have it
    if (_cachedVideoFile != null) {
      _isPrepared = true;
      return;
    }

    // Try to get from cache
    widget.cacheManager
        .getSingleFile(widget.videoUrl!)
        .then((file) {
      _cachedVideoFile = file;
      _isPrepared = true;
      log('Cache hit for video preparation: ${file.path}', name: 'ShortVideoPage');
    })
        .catchError((e) {
      log('Cache miss for video preparation: $e', name: 'ShortVideoPage');
    });
  }

  void _initializePlayer() {
    if (_initialized || widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return;
    }

    // Only show loading if we don't have a cached file
    if (_cachedVideoFile == null) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    }

    log('Initializing player for URL: ${widget.videoUrl}', name: 'ShortVideoPage');

    // If we already have a cached file, use it
    if (_cachedVideoFile != null) {
      log('Using cached file directly: ${_cachedVideoFile!.path}', name: 'ShortVideoPage');
      _setupPlayer();
    } else {
      // Otherwise try to get it from cache
      widget.cacheManager
          .getSingleFile(widget.videoUrl!)
          .then((file) {
        _cachedVideoFile = file;
        log('Cache hit for video: ${file.path}', name: 'ShortVideoPage');
        _setupPlayer();
      })
          .catchError((e) {
        log('Cache miss for video: $e', name: 'ShortVideoPage');
        // Still try to setup the player with the URL
        _setupPlayer();
      });
    }
  }

  void _setupPlayer() {
    if (!mounted) return;

    final configuration = BetterPlayerConfiguration(
      autoPlay: true,
      looping: true,
      aspectRatio: 9 / 16,
      fit: BoxFit.cover,
      handleLifecycle: true,
      startAt: const Duration(milliseconds: 0),
      autoDispose: false,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        showControls: false,
        enableMute: false,
        enableFullscreen: false,
        enablePlayPause: false,
        enableProgressBar: false,
        enableSkips: false,
        enableOverflowMenu: false,
      ),
      // Show loading indicator only if we don't have a cached file
      placeholder: _cachedVideoFile != null
          ? null
          : Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      errorBuilder: (context, errorMessage) {
        log('Video error: $errorMessage', name: 'ShortVideoPage');
        _hasError = true;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 32.sp),
              SizedBox(height: 8.h),
              Text(
                'Failed to load video',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );

    // Determine the data source based on whether we have a cached file
    final BetterPlayerDataSource dataSource;
    if (_cachedVideoFile != null) {
      log('Using cached file for video: ${_cachedVideoFile!.path}', name: 'ShortVideoPage');
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        _cachedVideoFile!.path,
        cacheConfiguration: BetterPlayerCacheConfiguration(
          useCache: true,
          preCacheSize: 10 * 1024 * 1024,
          maxCacheSize: 100 * 1024 * 1024,
          maxCacheFileSize: 50 * 1024 * 1024,
          key: widget.tip.tipsId,
        ),
      );
    } else {
      log('Using network URL for video: ${widget.videoUrl}', name: 'ShortVideoPage');
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.videoUrl!,
        cacheConfiguration: BetterPlayerCacheConfiguration(
          useCache: true,
          preCacheSize: 10 * 1024 * 1024,
          maxCacheSize: 100 * 1024 * 1024,
          maxCacheFileSize: 50 * 1024 * 1024,
          key: widget.tip.tipsId,
        ),
      );
    }

    try {
      _controller = BetterPlayerController(configuration);
      _controller!.setupDataSource(dataSource).then((_) {
        if (mounted) {
          _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);

          // Only play if this page is active and not during page transition
          if (widget.isActive && !widget.isPageChanging) {
            _controller!.play();
            log('Starting playback for ${widget.tip.tipsId}', name: 'ShortVideoPage');
          } else {
            _controller!.pause();
            log('Setup complete but paused for ${widget.tip.tipsId}', name: 'ShortVideoPage');
          }

          setState(() {
            _initialized = true;
            _isLoading = false;
            _isPrepared = true;
          });
          log('Player initialized successfully for ${widget.tip.tipsId}', name: 'ShortVideoPage');
        }
      }).catchError((e) {
        log('Error setting up player: $e', name: 'ShortVideoPage');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      });
    } catch (e) {
      log('Exception in setupPlayer: $e', name: 'ShortVideoPage');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _disposePlayer() {
    if (_controller != null) {
      log('Disposing player for ${widget.tip.tipsId}', name: 'ShortVideoPage');
      _controller!.pause();
      _controller!.dispose(forceDispose: true);
      _controller = null;
      _initialized = false;
    }
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
    ).canAccessPremium;
    final isPremium = widget.tip.isPremium;
    final isLocked = isPremium && !canAccessPremium;

    if (isLocked) {
      return _buildPremiumLockedScreen();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Always solid black background
        Container(color: Colors.black),

        // Video Player - explicitly use Positioned.fill
        if (_controller != null && !_hasError)
          Positioned.fill(
            child: BetterPlayer(controller: _controller!),
          ),

        // Error widget
        if (_hasError)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 40.sp),
                SizedBox(height: 16.h),
                Text(
                  'Failed to load video',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                    });
                    _disposePlayer();
                    _initializePlayer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          ),

        // Loading indicator - only show if isLoading is true
        if (_isLoading)
          Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),

        // Screen tap area
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onScreenTap,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),

        // Bottom gradient and info
        if (widget.showUI)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.tip.tipsTitle ?? 'Untitled',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.white70, size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        widget.tip.tipsAuthor ?? 'Unknown',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (widget.tip.tipsDescription.isNotEmpty)
                    Text(
                      widget.tip.tipsDescription,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),

        // Right side action buttons - position at 80.h (moved down)
        if (widget.showUI)
          Positioned(
            right: 12.w,
            bottom: 80.h, // Changed from 120.h to 80.h to move buttons down
            child: Column(
              children: [
                _ActionButton(
                  icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatViewCount(widget.tip.likeCount),
                  isActive: widget.isLiked,
                  onTap: widget.onLike,
                ),
                SizedBox(height: 12.h),
                _ActionButton(
                  icon: Icons.comment,
                  label: _formatViewCount(widget.tip.commentCount),
                  onTap: widget.onComment,
                ),
                SizedBox(height: 12.h),
                _ActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: widget.onShare,
                ),
                SizedBox(height: 12.h),
                _ActionButton(
                  icon: Icons.visibility,
                  label: _formatViewCount(widget.tip.viewCount),
                  onTap: () {},
                ),
                SizedBox(height: 12.h),
                _ActionButton(
                  icon: Icons.fullscreen,
                  label: 'Full screen',
                  onTap: widget.onEnterFullScreen,
                ),
              ],
            ),
          ),

        // Fullscreen exit button
        if (!widget.showUI)
          Positioned(
            top: 16.h,
            right: 12.w,
            child: _ActionButton(
              icon: Icons.fullscreen_exit,
              label: '',
              onTap: widget.onExitFullScreen,
            ),
          ),

        // Volume indicator (appears briefly when toggling mute)
        if (widget.showVolumeIcon)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Icon(
                  widget.volumeIcon,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumLockedScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium locked content UI
            Icon(Icons.lock, color: Colors.yellow, size: 48.sp),
            SizedBox(height: 16.h),
            Text(
              'Premium Content',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                'Subscribe to unlock this premium short video',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, RoutesName.subscriptionScreen);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
              child: Text(
                'Subscribe Now',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.primary : Colors.white,
              size: 24.sp,
            ),
          ),
          if (label.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.sp,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final VoidCallback onClose;
  final String tipsId;

  const _CommentsSheet({Key? key, required this.onClose, required this.tipsId})
      : super(key: key);

  @override
  _CommentsSheetState createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  List<CommentModel> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('tipsId', isEqualTo: widget.tipsId)
          .where('parentId', isNull: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final comments = snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id))
          .toList();

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      log('Error loading comments: $e', name: 'CommentsSheet');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = _authService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You need to be logged in to comment'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final commentRef = _firestore.collection('comments').doc();
      final comment = CommentModel(
        id: commentRef.id,
        tipsId: widget.tipsId,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        userPhotoUrl: user.photoURL ?? '',
        text: text,
        createdAt: DateTime.now(),
      );

      await commentRef.set(comment.toFirestore());
      await _firestore.collection('tips').doc(widget.tipsId).update({
        'commentCount': FieldValue.increment(1),
      });

      setState(() {
        _comments.insert(0, comment);
        _commentController.clear();
      });

      final shortsProvider = Provider.of<ShortsProvider>(
        context,
        listen: false,
      );
      final videoIndex = shortsProvider.shorts.indexWhere(
            (v) => v.tipsId == widget.tipsId,
      );
      if (videoIndex != -1) {
        final video = shortsProvider.shorts[videoIndex];
        shortsProvider.shorts[videoIndex] = video.copyWith(
          commentCount: video.commentCount + 1,
        );
        shortsProvider.notifyListeners();
      }

      FocusScope.of(context).unfocus();
    } catch (e) {
      log('Error adding comment: $e', name: 'CommentsSheet');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    return 'Just now';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 12.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Comments',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: isDarkMode ? Colors.white : Colors.black,
                              size: 24.sp,
                            ),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    ),
                    Expanded(
                      child: _isLoading
                          ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                          : _comments.isEmpty
                          ? Center(
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      )
                          : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18.r,
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                  backgroundImage:
                                  comment.userPhotoUrl.isNotEmpty
                                      ? NetworkImage(comment.userPhotoUrl)
                                      : null,
                                  child: comment.userPhotoUrl.isEmpty
                                      ? Text(
                                    comment.userName.isNotEmpty
                                        ? comment.userName[0]
                                        .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  )
                                      : null,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              comment.userName,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12.sp,
                                                fontWeight:
                                                FontWeight.w600,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              overflow:
                                              TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            _formatTimeAgo(
                                              comment.createdAt,
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10.sp,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        comment.text,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12.sp,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite_border,
                                            size: 14.sp,
                                            color: isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            comment.likeCount.toString(),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10.sp,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(width: 16.w),
                                          Text(
                                            'Reply',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10.sp,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(16.w),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.sp,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 10.h,
                                  ),
                                ),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.sp,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            CircleAvatar(
                              radius: 18.r,
                              backgroundColor: AppColors.primary,
                              child: IconButton(
                                icon: Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                                onPressed: _addComment,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}