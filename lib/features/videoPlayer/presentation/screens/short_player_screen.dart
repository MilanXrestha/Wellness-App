import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/splash/domain/app_initializer.dart';
import 'package:wellness_app/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:developer';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../data/models/comments_model.dart';
import '../providers/shorts_provider.dart';

// Custom cache manager for videos with limited size to prevent OOM
final _videoCacheManager = DefaultCacheManager();

class ShortsPlayerScreen extends StatefulWidget {
  final String categoryName;
  final TipModel? initialTip;
  final List<TipModel>? relatedTips;
  final bool tabActive;
  final ValueChanged<bool>? onFullScreenChanged;
  final bool showAllVideos;

  const ShortsPlayerScreen({
    super.key,
    required this.categoryName,
    this.initialTip,
    this.relatedTips,
    required this.tabActive,
    this.onFullScreenChanged,
    this.showAllVideos = false,
  });

  @override
  State<ShortsPlayerScreen> createState() => ShortsPlayerScreenState();
}

class ShortsPlayerScreenState extends State<ShortsPlayerScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  bool _isCommentsVisible = false;
  bool _showUI = true;
  bool _isMuted = false;
  bool _showVolumeIcon = false;
  IconData _volumeIcon = Icons.volume_up;
  final AuthService _authService = AuthService();
  bool _isFullscreen = false;
  int _currentPage = 0;
  bool _initialLoadComplete = false;
  Timer? _initialPlayTimer;
  bool _isOffline = false;
  ShortVideoPageState? _activeVideoPage;
  final DashboardRepository _dashboardRepository = DashboardRepository.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: 0);
    _checkConnectivity();
    if (widget.tabActive) {
      _loadInitialShorts();
    }
  }

  // In ShortsPlayerScreen.dart, add this method:
  Future<bool> _verifyAuthentication() async {
    // First try standard auth check
    final user = _authService.getCurrentUser();
    if (user != null) {
      log('User verified: ${user.uid}', name: 'ShortsPlayerScreen');
      return true;
    }

    // If that fails, give Firebase Auth a moment to catch up
    log('Initial auth check failed, waiting for auth state to propagate...', name: 'ShortsPlayerScreen');
    await Future.delayed(Duration(milliseconds: 500));

    // Try again after a short delay
    final retryUser = _authService.getCurrentUser();
    if (retryUser != null) {
      log('User verified after retry: ${retryUser.uid}', name: 'ShortsPlayerScreen');
      return true;
    }

    // If still not authenticated, check if we're on the dashboard (which means we should be authenticated)
    final prefs = await SharedPreferences.getInstance();
    final lastLoginTimestamp = prefs.getInt('last_login_timestamp') ?? 0;
    final timeSinceLogin = DateTime.now().millisecondsSinceEpoch - lastLoginTimestamp;

    // If we logged in recently (within 30 seconds), assume auth is valid but delayed
    if (timeSinceLogin < 30000) {
      log('Recent login detected, assuming auth is valid', name: 'ShortsPlayerScreen');
      return true;
    }

    log('Authentication check failed', name: 'ShortsPlayerScreen');
    return false;
  }

  Future<void> _checkConnectivity() async {
    _isOffline = AppInitializer.instance.isOffline;
    log(
      'Connectivity check: isOffline=$_isOffline',
      name: 'ShortsPlayerScreen',
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _loadInitialShorts() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Add this block to verify authentication first
      final isAuthenticated = await _verifyAuthentication();
      if (!isAuthenticated) {
        log('Not authenticated, showing login screen', name: 'ShortsPlayerScreen');
        if (mounted) {
          Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
        }
        return;
      }

      final shortsProvider = Provider.of<ShortsProvider>(context, listen: false);
      log('Loading shorts, provider has ${shortsProvider.shorts.length} shorts', name: 'ShortsPlayerScreen');

      // Critical check: only load new shorts if the list is actually empty
      if (shortsProvider.shorts.isEmpty) {
        if (_isOffline) {
          // Load from cache in offline mode
          final userId = _authService.getCurrentUser()?.uid ?? '';
          final cachedShorts = await _dashboardRepository.getCachedShorts(userId);
          if (cachedShorts.isNotEmpty) {
            shortsProvider.addShorts(cachedShorts);
            log('Loaded ${cachedShorts.length} shorts from cache', name: 'ShortsPlayerScreen');
          } else {
            log('No cached shorts available offline', name: 'ShortsPlayerScreen');
            setState(() {
              _initialLoadComplete = true;
            });
            return;
          }
        } else {
          // Load from API in online mode - use null categoryId to get all shorts
          await shortsProvider.loadShorts(categoryId: null); // Load ALL shorts
          log('Loaded shorts from API, now has ${shortsProvider.shorts.length} shorts', name: 'ShortsPlayerScreen');
        }
      }

      // Even if we already had shorts, let's directly check after loading
      if (shortsProvider.shorts.isEmpty) {
        log('Still no shorts available after loading attempt', name: 'ShortsPlayerScreen');
        setState(() {
          _initialLoadComplete = true;
        });
        return;
      }

      if (widget.initialTip != null) {
        _setInitialPage(shortsProvider);
      } else {
        // Always start at index 0 for tab view
        _currentPage = 0;
        shortsProvider.changeCurrentIndex(0);
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
          log('Jumped to first video for tab view', name: 'ShortsPlayerScreen');
        }
      }

      setState(() {
        _initialLoadComplete = true;
      });

      _scheduleInitialVideoPlay();
    });
  }

  void _scheduleInitialVideoPlay() {
    _initialPlayTimer?.cancel();
    _initialPlayTimer = Timer(const Duration(milliseconds: 300), () {
      if (_activeVideoPage != null && mounted) {
        _activeVideoPage!.playVideo();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pauseCurrentVideo();
    } else if (state == AppLifecycleState.resumed && widget.tabActive) {
      _checkConnectivity();
      if (_activeVideoPage != null) {
        _activeVideoPage!.playVideo();
      }
    }
  }

  void _setInitialPage(ShortsProvider shortsProvider) {
    if (widget.initialTip == null) return;

    // Find index of the initial tip
    final index = shortsProvider.shorts.indexWhere(
      (short) => short.tipsId == widget.initialTip!.tipsId,
    );

    log(
      'Setting initial page to index $index for tip ID ${widget.initialTip!.tipsId}',
      name: 'ShortsPlayerScreen',
    );

    if (index != -1) {
      setState(() {
        _currentPage = index;
      });
      shortsProvider.changeCurrentIndex(index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(index);
          log('Successfully jumped to page $index', name: 'ShortsPlayerScreen');
        } else {
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(index);
              log('Retry: jumped to page $index', name: 'ShortsPlayerScreen');
            }
          });
        }
      });
    } else {
      // If not found, add it to the list
      shortsProvider.addShorts([widget.initialTip!]);
      log('Added initial tip to shorts list', name: 'ShortsPlayerScreen');
      Future.delayed(Duration(milliseconds: 50), () {
        _setInitialPage(shortsProvider);
      });
    }
  }

  @override
  void didUpdateWidget(ShortsPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabActive && !oldWidget.tabActive) {
      log('Tab became active', name: 'ShortsPlayerScreen');
      _checkConnectivity();
      _loadInitialShorts();
    } else if (!widget.tabActive && oldWidget.tabActive) {
      log('Tab became inactive, cleaning up', name: 'ShortsPlayerScreen');
      pauseCurrentVideo();
    }
  }

  void pauseCurrentVideo() {
    if (_activeVideoPage != null) {
      _activeVideoPage!.pauseVideo();
    }
  }

  void setActiveVideoPage(ShortVideoPageState videoPage) {
    if (_activeVideoPage != null && _activeVideoPage != videoPage) {
      _activeVideoPage!.pauseVideo();
    }
    _activeVideoPage = videoPage;
  }

  void _onPageChanged(int index) {
    if (_currentPage != index) {
      log(
        'Page changed from $_currentPage to $index',
        name: 'ShortsPlayerScreen',
      );
      setState(() {
        _currentPage = index;
        _showUI = true;
      });
      final shortsProvider = Provider.of<ShortsProvider>(
        context,
        listen: false,
      );
      shortsProvider.changeCurrentIndex(index);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _volumeIcon = _isMuted ? Icons.volume_off : Icons.volume_up;
      _showVolumeIcon = true;
    });
    if (_activeVideoPage != null) {
      _activeVideoPage!.setMuted(_isMuted);
    }
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _showVolumeIcon) {
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
    pauseCurrentVideo();
    setState(() {
      _isCommentsVisible = true;
    });
  }

  void _hideComments() {
    setState(() {
      _isCommentsVisible = false;
    });
    if (_activeVideoPage != null && widget.tabActive) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _activeVideoPage != null) {
          _activeVideoPage!.playVideo();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialPlayTimer?.cancel();
    pauseCurrentVideo();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = _isFullscreen ? 0.0 : 50.h;

    return Consumer<ShortsProvider>(
      builder: (context, shortsProvider, child) {
        if (!widget.tabActive) {
          return Container(
            color: Colors.black,
            child: const Center(child: SizedBox()),
          );
        }

        if (shortsProvider.isLoading && !_initialLoadComplete) {
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isOffline
                        ? 'No internet connection. Showing cached content.'
                        : shortsProvider.error!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.sp,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isOffline && shortsProvider.shorts.isEmpty)
                    ElevatedButton(
                      onPressed: () => _loadInitialShorts(),
                      child: Text('Retry'),
                    ),
                ],
              ),
            ),
          );
        }

        // Always use all shorts from the provider
        final shorts = shortsProvider.shorts;

        if (shorts.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isOffline
                        ? 'No cached shorts available'
                        : 'No shorts available',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                  if (!_isOffline)
                    ElevatedButton(
                      onPressed: () => _loadInitialShorts(),
                      child: Text('Retry'),
                    ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  physics: _OneDirectionScrollPhysics(),
                  // Custom physics to prevent backward swiping
                  itemCount: shorts.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final short = shorts[index];
                    final isPremium = short.isPremium;
                    final canAccessPremium = Provider.of<PremiumStatusProvider>(
                      context,
                    ).canAccessPremium;
                    final isLocked = isPremium && !canAccessPremium;
                    final isActive = widget.tabActive && index == _currentPage;

                    return ShortVideoPage(
                      key: ValueKey(short.tipsId),
                      tip: short,
                      videoUrl: isLocked ? null : short.videoUrl,
                      index: index,
                      isActive: isActive,
                      showUI: _showUI,
                      isLiked: shortsProvider.isShortLiked(short.tipsId),
                      isMuted: _isMuted,
                      showVolumeIcon: _showVolumeIcon && isActive,
                      volumeIcon: _volumeIcon,
                      onLike: () => _isOffline
                          ? _queueInteraction('like', short.tipsId)
                          : shortsProvider.toggleLike(short.tipsId, context),
                      onComment: _showComments,
                      onShare: () {},
                      onScreenTap: _onScreenTap,
                      onEnterFullScreen: _enterFullScreen,
                      onExitFullScreen: _exitFullScreen,
                      onActive: (state) {
                        if (isActive) {
                          setActiveVideoPage(state);
                        }
                      },
                      showThumbnail: !_isOffline,
                    );
                  },
                ),
              ),
              if (_isCommentsVisible)
                CommentsSheet(
                  onClose: _hideComments,
                  tipsId: shortsProvider.currentShort?.tipsId ?? '',
                  isOffline: _isOffline,
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

  Future<void> _queueInteraction(String type, String tipsId) async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    try {
      final db = await openDatabase('wellness_app.db');
      await db.insert('queued_interactions', {
        'userId': userId,
        'tipsId': tipsId,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      log('Queued $type for $tipsId', name: 'ShortsPlayerScreen');
      await db.close();
    } catch (e) {
      log('Error queuing interaction: $e', name: 'ShortsPlayerScreen');
    }
  }
}

// Custom ScrollPhysics that prevents backward scrolling from the first item
class _OneDirectionScrollPhysics extends ScrollPhysics {
  _OneDirectionScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  _OneDirectionScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _OneDirectionScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // For vertical PageView:
    // - AxisDirection.up means swiping backward (up) when at the first page
    // - Only prevent scrolling if at the beginning of the list
    if (position.pixels <= position.minScrollExtent) {
      return position.axisDirection != AxisDirection.up;
    }
    return true;
  }
}

class ShortVideoPage extends StatefulWidget {
  final TipModel tip;
  final String? videoUrl;
  final int index;
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
  final Function(ShortVideoPageState) onActive;
  final bool showThumbnail;

  const ShortVideoPage({
    Key? key,
    required this.tip,
    this.videoUrl,
    required this.index,
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
    required this.onActive,
    this.showThumbnail = false,
  }) : super(key: key);

  @override
  ShortVideoPageState createState() => ShortVideoPageState();
}

class ShortVideoPageState extends State<ShortVideoPage>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _disposed = false;
  int _errorCount = 0;
  bool _isFirstBuild = true;
  bool _isLoadingVideo = false;
  Timer? _initTimer;
  Timer? _playerReadyTimer;
  Timer? _retryTimer;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _scheduleInitialization(immediate: true);
    }
  }

  Future<void> _scheduleInitialization({bool immediate = false}) async {
    _initTimer?.cancel();
    final delay = immediate
        ? const Duration(milliseconds: 10)
        : const Duration(milliseconds: 100);
    _initTimer = Timer(delay, () {
      if (!_disposed && !_isInitialized && !_isLoadingVideo) {
        _initializePlayer();
      }
    });
  }

  Future<void> _initializePlayer() async {
    if (_isInitialized ||
        _disposed ||
        widget.videoUrl == null ||
        widget.videoUrl!.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingVideo = true;
    });
    log(
      'Initializing player for ${widget.tip.tipsId} at index ${widget.index}',
      name: 'ShortVideoPage',
    );

    try {
      // Check cache first
      final fileInfo = await _videoCacheManager.getFileFromCache(
        widget.videoUrl!,
      );
      if (fileInfo != null && fileInfo.file.existsSync()) {
        _controller = VideoPlayerController.file(
          fileInfo.file,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
        log('Loaded ${widget.tip.tipsId} from cache', name: 'ShortVideoPage');
      } else {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl!),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
        // Cache the video
        await _videoCacheManager.downloadFile(widget.videoUrl!);
        log(
          'Downloaded and cached ${widget.tip.tipsId}',
          name: 'ShortVideoPage',
        );
      }

      await _controller!.initialize();
      if (_disposed) {
        _disposePlayer();
        return;
      }

      _controller!.setLooping(true);
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
      setState(() {
        _isInitialized = true;
        _isLoadingVideo = false;
        _hasError = false;
        _errorCount = 0;
      });

      if (widget.isActive && !_disposed) {
        _controller!.play();
        log(
          'Started playback for ${widget.tip.tipsId}',
          name: 'ShortVideoPage',
        );
        widget.onActive(this);
      }
    } catch (e) {
      log('Error initializing player: $e', name: 'ShortVideoPage');
      _retryCount++;
      _disposePlayer();
      if (!_disposed) {
        setState(() {
          _isLoadingVideo = false;
          _hasError = true;
        });
        if (_retryCount < 3) {
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(milliseconds: 500 * _retryCount), () {
            if (!_disposed) {
              log(
                'Auto-retrying video load (attempt $_retryCount)',
                name: 'ShortVideoPage',
              );
              _initializePlayer();
            }
          });
        }
      }
    }
  }

  @override
  void didUpdateWidget(ShortVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tip.tipsId != oldWidget.tip.tipsId ||
        widget.videoUrl != oldWidget.videoUrl) {
      log(
        'Video content changed from ${oldWidget.tip.tipsId} to ${widget.tip.tipsId}',
        name: 'ShortVideoPage',
      );
      _disposePlayer();
      if (widget.isActive) {
        _scheduleInitialization(immediate: true);
      }
    }
    if (widget.isActive && !oldWidget.isActive) {
      log(
        'Video became active: ${widget.tip.tipsId} at index ${widget.index}',
        name: 'ShortVideoPage',
      );
      if (_isInitialized && _controller != null) {
        _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
        _controller!.play();
        widget.onActive(this);
      } else if (!_hasError || _errorCount < 3) {
        _scheduleInitialization(immediate: true);
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      log(
        'Video became inactive: ${widget.tip.tipsId}',
        name: 'ShortVideoPage',
      );
      pauseVideo();
    }
    if (widget.isMuted != oldWidget.isMuted &&
        _controller != null &&
        _isInitialized) {
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  void pauseVideo() {
    if (_controller != null && _isInitialized) {
      try {
        _controller!.pause();
      } catch (e) {
        log('Error pausing video: $e', name: 'ShortVideoPage');
      }
    }
  }

  void playVideo() {
    if (_controller != null && _isInitialized) {
      try {
        _controller!.play();
        log('Playing video: ${widget.tip.tipsId}', name: 'ShortVideoPage');
      } catch (e) {
        log('Error playing video: $e', name: 'ShortVideoPage');
      }
    } else if (!_isInitialized && !_hasError && !_isLoadingVideo) {
      _scheduleInitialization(immediate: true);
      _playerReadyTimer?.cancel();
      _playerReadyTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (_isInitialized && _controller != null) {
          _controller!.play();
          log(
            'Playing after delayed init: ${widget.tip.tipsId}',
            name: 'ShortVideoPage',
          );
          timer.cancel();
        } else if (timer.tick > 50) {
          timer.cancel();
        }
      });
    }
  }

  void setMuted(bool muted) {
    if (_controller != null && _isInitialized) {
      try {
        _controller!.setVolume(muted ? 0.0 : 1.0);
      } catch (e) {
        log('Error setting volume: $e', name: 'ShortVideoPage');
      }
    }
  }

  void _disposePlayer() {
    _initTimer?.cancel();
    _playerReadyTimer?.cancel();
    _retryTimer?.cancel();
    if (_controller != null) {
      try {
        _controller!.pause();
        _controller!.dispose();
        log(
          'Disposed controller for ${widget.tip.tipsId}',
          name: 'ShortVideoPage',
        );
      } catch (e) {
        log('Error disposing controller: $e', name: 'ShortVideoPage');
      }
      _controller = null;
      _isInitialized = false;
    }
  }

  void _retryLoading() {
    _disposePlayer();
    setState(() {
      _hasError = false;
      _isLoadingVideo = false;
      _retryCount = 0;
    });
    _scheduleInitialization(immediate: true);
  }

  String _formatViewCount(int count) {
    if (count <= 0) return "";
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  void dispose() {
    _disposed = true;
    _disposePlayer();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isFirstBuild && widget.isActive) {
      _isFirstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && widget.isActive) {
          widget.onActive(this);
        }
      });
    }

    final canAccessPremium = Provider.of<PremiumStatusProvider>(
      context,
    ).canAccessPremium;
    final isPremium = widget.tip.isPremium;
    final isLocked = isPremium && !canAccessPremium;

    if (isLocked) {
      return _buildPremiumLockedScreen();
    }

    if (widget.isActive && !_isInitialized && !_hasError && !_isLoadingVideo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && !_isInitialized && !_hasError && !_isLoadingVideo) {
          _scheduleInitialization();
        }
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        if (widget.tip.thumbnailUrl != null &&
            widget.showThumbnail &&
            !_isInitialized &&
            !_hasError)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.tip.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.black),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.black),
              cacheManager: _videoCacheManager,
            ),
          ),
        if (_controller != null && _isInitialized && !_hasError)
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
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
                  onPressed: _retryLoading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onScreenTap,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        if (widget.showUI)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 240.h,
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
                  SizedBox(height: 30.h),
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
        if (widget.showUI)
          Positioned(
            right: 12.w,
            bottom: 100.h,
            child: Column(
              children: [
                ActionButton(
                  icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatViewCount(widget.tip.likeCount),
                  isActive: widget.isLiked,
                  onTap: widget.onLike,
                ),
                SizedBox(height: 12.h),
                ActionButton(
                  icon: Icons.comment,
                  label: _formatViewCount(widget.tip.commentCount),
                  onTap: widget.onComment,
                ),
                SizedBox(height: 12.h),
                ActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: widget.onShare,
                ),
                SizedBox(height: 12.h),
                if (widget.tip.viewCount > 0)
                  ActionButton(
                    icon: Icons.visibility,
                    label: _formatViewCount(widget.tip.viewCount),
                    onTap: () {},
                  ),
                SizedBox(height: 12.h),
                ActionButton(
                  icon: Icons.fullscreen,
                  label: 'Full screen',
                  onTap: widget.onEnterFullScreen,
                ),
              ],
            ),
          ),
        if (!widget.showUI)
          Positioned(
            top: 16.h,
            right: 12.w,
            child: ActionButton(
              icon: Icons.fullscreen_exit,
              label: '',
              onTap: widget.onExitFullScreen,
            ),
          ),
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

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const ActionButton({
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

class CommentsSheet extends StatefulWidget {
  final VoidCallback onClose;
  final String tipsId;
  final bool isOffline;

  const CommentsSheet({
    Key? key,
    required this.onClose,
    required this.tipsId,
    required this.isOffline,
  }) : super(key: key);

  @override
  CommentsSheetState createState() => CommentsSheetState();
}

class CommentsSheetState extends State<CommentsSheet> {
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
      if (widget.isOffline) {
        final db = await openDatabase('wellness_app.db');
        final cachedComments = await db.query(
          'comments',
          where: 'tipsId = ? AND parentId IS NULL',
          whereArgs: [widget.tipsId],
          orderBy: 'createdAt DESC',
          limit: 20,
        );
        final comments = cachedComments
            .map((map) => CommentModel.fromMap(map))
            .toList();
        await db.close();
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
        log(
          'Loaded ${comments.length} cached comments for ${widget.tipsId}',
          name: 'CommentsSheet',
        );
      } else {
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
        // Cache comments
        final db = await openDatabase('wellness_app.db');
        for (var comment in comments) {
          await db.insert(
            'comments',
            comment.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await db.close();
        log(
          'Loaded and cached ${comments.length} comments for ${widget.tipsId}',
          name: 'CommentsSheet',
        );
      }
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

    final comment = CommentModel(
      id: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
      tipsId: widget.tipsId,
      userId: user.uid,
      userName: user.displayName ?? 'Anonymous',
      userPhotoUrl: user.photoURL ?? '',
      text: text,
      createdAt: DateTime.now(),
    );

    try {
      if (widget.isOffline) {
        final db = await openDatabase('wellness_app.db');
        await db.insert('queued_comments', {
          'id': comment.id,
          'tipsId': widget.tipsId,
          'userId': user.uid,
          'userName': user.displayName ?? 'Anonymous',
          'userPhotoUrl': user.photoURL ?? '',
          'text': text,
          'createdAt': comment.createdAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await db.insert(
          'comments',
          comment.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await db.close();
        setState(() {
          _comments.insert(0, comment);
          _commentController.clear();
        });
        log('Queued comment for ${widget.tipsId}', name: 'CommentsSheet');
      } else {
        final commentRef = _firestore.collection('comments').doc(comment.id);
        await commentRef.set(comment.toFirestore());
        await _firestore.collection('tips').doc(widget.tipsId).update({
          'commentCount': FieldValue.increment(1),
        });
        setState(() {
          _comments.insert(0, comment);
          _commentController.clear();
        });
        // Cache comment
        final db = await openDatabase('wellness_app.db');
        await db.insert(
          'comments',
          comment.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await db.close();
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
        onTap: widget.onClose,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: GestureDetector(
            onTap: () {},
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
                          color: isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[300],
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
                                  widget.isOffline
                                      ? 'No cached comments available'
                                      : 'No comments yet. Be the first to comment!',
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
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.h,
                                    ),
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
                                              ? NetworkImage(
                                                  comment.userPhotoUrl,
                                                )
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
                                                  if (comment.likeCount >
                                                      0) ...[
                                                    Icon(
                                                      Icons.favorite_border,
                                                      size: 14.sp,
                                                      color: isDarkMode
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      comment.likeCount
                                                          .toString(),
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 10.sp,
                                                        color: isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                      ),
                                                    ),
                                                    SizedBox(width: 16.w),
                                                  ],
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
                          color: isDarkMode
                              ? Colors.grey[850]
                              : Colors.grey[100],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
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
                                  enabled: !widget
                                      .isOffline, // Disable input in offline mode
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
      ),
    );
  }
}
