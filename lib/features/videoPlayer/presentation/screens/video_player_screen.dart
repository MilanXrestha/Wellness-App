import 'dart:io';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/favorites/data/models/favorite_model.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/subscription/presentation/providers/premium_status_provider.dart';
import '../../data/models/comments_model.dart';
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
  bool _isLiked = false;
  String? _videoError;
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _favoriteScaleAnimation;
  bool _isLoading = true;
  bool _isDescriptionExpanded = false;
  bool _isFullScreen = false;
  bool _autoplayEnabled = true;

  // Comment section expanded state
  bool _isCommentSectionExpanded = false;

  // Comment expansion tracking
  Set<String> _expandedCommentIds = {};

  // Current video tracking
  List<TipModel> _relatedVideos = [];
  late TipModel _currentTip;

  // View count tracking
  int _viewCount = 0;
  bool _viewCounted = false;

  // Comments
  List<CommentModel> _comments = [];
  List<CommentModel> _replies = [];
  bool _isLoadingComments = false;
  final TextEditingController _commentController = TextEditingController();
  String? _replyToCommentId;
  String? _replyToUserName;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  // Downloading
  bool _isDownloading = false;

  // Pagination for comments
  bool _hasMoreComments = true;
  bool _isLoadingMoreComments = false;
  DocumentSnapshot? _lastCommentDoc;
  final int _commentsLimit = 15;

  // Cast status
  bool _isCasting = false;
  bool _isConnectingCast = false;

  // Helper to check if controller is safe to use
  bool get _isControllerReady {
    return _controller?.isVideoInitialized() == true;
  }

  @override
  void initState() {
    super.initState();
    _currentTip = widget.tip;
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

    _prepareRelatedVideos();
    _initializeVideoPlayer();
    _scrollController.addListener(_scrollListener);

    // Lock to portrait on initialization
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUser();
      _loadViewCount();
      _loadComments();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadComments();
  }

  void _prepareRelatedVideos() {
    _relatedVideos = widget.featuredTips
        .where((tip) =>
    tip.categoryId == widget.tip.categoryId &&
        tip.tipsId != widget.tip.tipsId &&
        tip.tipsType == 'video')
        .toList();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreComments &&
        _hasMoreComments) {
      _loadMoreComments();
    }
  }

  void _loadViewCount() async {
    try {
      final docRef = _firestore.collection('tips').doc(_currentTip.tipsId);
      final doc = await docRef.get();

      if (doc.exists && doc.data()!.containsKey('viewCount')) {
        _safeSetState(() {
          _viewCount = doc.data()!['viewCount'] ?? 0;
        });
      } else {
        _safeSetState(() {
          _viewCount = 0;
        });
      }

      if (!_viewCounted) {
        await docRef.update({'viewCount': FieldValue.increment(1)});
        _safeSetState(() {
          _viewCount += 1;
          _viewCounted = true;
        });
      }
    } catch (e) {
      log('Error loading view count: $e', name: 'VideoPlayerScreen');
    }
  }

  void _loadComments() async {
    _safeSetState(() {
      _isLoadingComments = true;
      _comments = [];
      _replies = [];
      _lastCommentDoc = null;
      _hasMoreComments = true;
    });

    try {
      log('Fetching comments for tipsId: ${_currentTip.tipsId}', name: 'VideoPlayerScreen');
      final commentsQuery = await _firestore
          .collection('comments')
          .where('tipsId', isEqualTo: _currentTip.tipsId)
          .where('parentId', isNull: true)
          .orderBy('createdAt', descending: true)
          .limit(_commentsLimit)
          .get();

      log('Comments fetched: ${commentsQuery.docs.length}', name: 'VideoPlayerScreen');

      if (commentsQuery.docs.isEmpty) {
        _safeSetState(() {
          _isLoadingComments = false;
          _hasMoreComments = false;
        });
        return;
      }

      List<CommentModel> comments = commentsQuery.docs
          .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id))
          .toList();

      _lastCommentDoc = commentsQuery.docs.last;
      _hasMoreComments = commentsQuery.docs.length >= _commentsLimit;

      List<String> commentIds = comments.map((comment) => comment.id).toList();

      if (commentIds.isNotEmpty) {
        final repliesQuery = await _firestore
            .collection('comments')
            .where('parentId', whereIn: commentIds)
            .get();

        List<CommentModel> replies = repliesQuery.docs
            .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id))
            .toList();

        _safeSetState(() {
          _comments = comments;
          _replies = replies;
          _isLoadingComments = false;
        });
      } else {
        _safeSetState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      log('Error loading comments: $e', name: 'VideoPlayerScreen');
      _safeSetState(() {
        _isLoadingComments = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load comments: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _loadMoreComments() async {
    if (_lastCommentDoc == null || !_hasMoreComments || _isLoadingMoreComments) {
      return;
    }

    _safeSetState(() {
      _isLoadingMoreComments = true;
    });

    try {
      final commentsQuery = await _firestore
          .collection('comments')
          .where('tipsId', isEqualTo: _currentTip.tipsId)
          .where('parentId', isNull: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastCommentDoc!)
          .limit(_commentsLimit)
          .get();

      if (commentsQuery.docs.isEmpty) {
        _safeSetState(() {
          _isLoadingMoreComments = false;
          _hasMoreComments = false;
        });
        return;
      }

      List<CommentModel> newComments = commentsQuery.docs
          .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id))
          .toList();

      _lastCommentDoc = commentsQuery.docs.last;
      _hasMoreComments = commentsQuery.docs.length >= _commentsLimit;

      List<String> commentIds = newComments.map((comment) => comment.id).toList();

      if (commentIds.isNotEmpty) {
        final repliesQuery = await _firestore
            .collection('comments')
            .where('parentId', whereIn: commentIds)
            .get();

        List<CommentModel> newReplies = repliesQuery.docs
            .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id))
            .toList();

        _safeSetState(() {
          _comments.addAll(newComments);
          _replies.addAll(newReplies);
          _isLoadingMoreComments = false;
        });
      } else {
        _safeSetState(() {
          _comments.addAll(newComments);
          _isLoadingMoreComments = false;
        });
      }
    } catch (e) {
      log('Error loading more comments: $e', name: 'VideoPlayerScreen');
      _safeSetState(() {
        _isLoadingMoreComments = false;
      });
    }
  }

  Future<void> _addComment() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to add a comment'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      return;
    }

    try {
      final commentRef = _firestore.collection('comments').doc();

      final newComment = CommentModel(
        id: commentRef.id,
        tipsId: _currentTip.tipsId,
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'Anonymous',
        userPhotoUrl: currentUser.photoURL ?? '',
        text: _commentController.text.trim(),
        createdAt: DateTime.now(),
        parentId: _replyToCommentId,
        likeCount: 0,
      );

      await commentRef.set(newComment.toFirestore());

      if (_replyToCommentId == null) {
        await _firestore.collection('tips').doc(_currentTip.tipsId).update({
          'commentCount': FieldValue.increment(1),
        });
      }

      _safeSetState(() {
        if (_replyToCommentId == null) {
          _comments.insert(0, newComment);
        } else {
          _replies.add(newComment);
        }
        _commentController.clear();
        _replyToCommentId = null;
        _replyToUserName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment added successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      FocusScope.of(context).unfocus();
    } catch (e) {
      log('Error adding comment: $e', name: 'VideoPlayerScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _prepareToReply(CommentModel comment) {
    _safeSetState(() {
      _replyToCommentId = comment.id;
      _replyToUserName = comment.userName;
      if (!_isCommentSectionExpanded) {
        _isCommentSectionExpanded = true;
      }
    });

    FocusScope.of(context).requestFocus(FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _cancelReply() {
    _safeSetState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
    });
  }

  void _toggleCommentExpansion(String commentId) {
    _safeSetState(() {
      if (_expandedCommentIds.contains(commentId)) {
        _expandedCommentIds.remove(commentId);
      } else {
        _expandedCommentIds.add(commentId);
      }
    });
  }

  void _toggleCommentSection() {
    _safeSetState(() {
      _isCommentSectionExpanded = !_isCommentSectionExpanded;
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // Modified to fix fullscreen orientation issues
  void _initializeVideoPlayer() {
    if (_currentTip.videoUrl != null && _currentTip.videoUrl!.isNotEmpty) {
      log('Initializing BetterPlayer with URL: ${_currentTip.videoUrl}', name: 'VideoPlayerScreen');

      final configuration = BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.contain,
        looping: false,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        // Let the player handle orientations itself during fullscreen
        autoDetectFullscreenDeviceOrientation: false,
        // This prevents the player from setting orientations internally
        deviceOrientationsOnFullScreen: [],
        deviceOrientationsAfterFullScreen: [],
        handleLifecycle: true,
        rotation: 0,
        placeholder: Container(
          color: Colors.black,
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
        subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
          fontSize: 0,
        ),
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableSkips: true,
          enableFullscreen: true,
          enablePip: true,
          enablePlaybackSpeed: true,
          enableSubtitles: false,
          enableAudioTracks: false,
          playIcon: Icons.play_arrow_rounded,
          pauseIcon: Icons.pause_rounded,
          fullscreenEnableIcon: Icons.fullscreen_rounded,
          fullscreenDisableIcon: Icons.fullscreen_exit_rounded,
          pipMenuIcon: Icons.picture_in_picture_rounded,
          skipBackIcon: Icons.replay_10_rounded,
          skipForwardIcon: Icons.forward_10_rounded,
          controlBarColor: Colors.black.withOpacity(0.5),
          progressBarPlayedColor: AppColors.primary,
          progressBarHandleColor: AppColors.primary,
          progressBarBufferedColor: AppColors.primary.withOpacity(0.3),
          progressBarBackgroundColor: Colors.white.withOpacity(0.2),
          loadingColor: AppColors.primary,
          overflowModalColor: Colors.black.withOpacity(0.8),
          overflowModalTextColor: Colors.white,
          overflowMenuIconsColor: AppColors.primary,
        ),
      );

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        _currentTip.videoUrl!,
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
          log('BetterPlayer exception: ${event.parameters}', name: 'VideoPlayerScreen');
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
        } else if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
          if (_autoplayEnabled && _relatedVideos.isNotEmpty) {
            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                _playNextVideo();
              }
            });
          }
        } else if (event.betterPlayerEventType == BetterPlayerEventType.openFullscreen) {
          _safeSetState(() {
            _isFullScreen = true;
            log('Entered fullscreen mode', name: 'VideoPlayerScreen');
          });

          // Force landscape orientation with a small delay to ensure it takes effect
          Future.delayed(Duration(milliseconds: 50), () {
            if (mounted) {
              log('Setting landscape orientation', name: 'VideoPlayerScreen');
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            }
          });
        } else if (event.betterPlayerEventType == BetterPlayerEventType.hideFullscreen) {
          _safeSetState(() {
            _isFullScreen = false;
            log('Exited fullscreen mode', name: 'VideoPlayerScreen');
          });

          // Restore portrait orientation with a small delay
          Future.delayed(Duration(milliseconds: 50), () {
            if (mounted) {
              log('Setting portrait orientation', name: 'VideoPlayerScreen');
              SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            }
          });
        }
      });
    } else {
      log('Invalid or missing video URL for tip: ${_currentTip.tipsId}', name: 'VideoPlayerScreen');
      _safeSetState(() {
        _videoError = 'No video URL provided';
        _isLoading = false;
      });
    }
  }

  void _playNextVideo() {
    if (_relatedVideos.isEmpty) return;

    final nextVideo = _relatedVideos.first;
    _relatedVideos.removeAt(0);

    if (_isControllerReady) {
      _controller!.pause();
    }

    var oldController = _controller;
    _controller = null;

    Future.delayed(Duration(milliseconds: 50), () {
      if (oldController != null) {
        try {
          oldController.dispose();
        } catch (e) {
          log('Error disposing old controller: $e', name: 'VideoPlayerScreen');
        }
      }
    });

    _safeSetState(() {
      _currentTip = nextVideo;
      _isLoading = true;
      _viewCounted = false;
      _expandedCommentIds.clear();
      _isCommentSectionExpanded = false;
    });

    _relatedVideos.add(widget.tip);
    _initializeVideoPlayer();
    _initializeUser();
    _loadViewCount();
    _loadComments();
  }

  void _initializeUser() {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    if (userId.isEmpty) {
      log('No user ID found, skipping favorite/like initialization', name: 'VideoPlayerScreen');
      return;
    }

    if (!mounted) return;

    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    favoritesProvider.loadFavorites(userId).then((_) {
      if (mounted) {
        _safeSetState(() {
          _isFavorite = favoritesProvider.isFavorite(_currentTip.tipsId, userId);
        });
      }
    }).catchError((error) {
      log('Error loading favorites for tip ${_currentTip.tipsId}: $error', name: 'VideoPlayerScreen');
    });

    _firestore
        .collection('likes')
        .doc('${userId}_${_currentTip.tipsId}')
        .get()
        .then((doc) {
      if (mounted) {
        _safeSetState(() {
          _isLiked = doc.exists;
        });
      }
    });
  }

  void _toggleFavorite() {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    if (userId.isEmpty) {
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

    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

    if (_isFavorite) {
      final favorite = favoritesProvider.favorites.firstWhere(
            (f) => f.tipId == _currentTip.tipsId && f.userId == userId,
        orElse: () => FavoriteModel(id: '', tipId: _currentTip.tipsId, userId: userId),
      );
      favoritesProvider.deleteFavorite(favorite.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: Colors.grey[700],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      final favorite = FavoriteModel(
        id: '${userId}_${_currentTip.tipsId}',
        tipId: _currentTip.tipsId,
        userId: userId,
        createdAt: DateTime.now(),
      );
      favoritesProvider.addFavorite(favorite);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to favorites'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
    _safeSetState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _toggleLike() {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to like this video'),
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

    if (_isLiked) {
      _firestore.collection('likes').doc('${userId}_${_currentTip.tipsId}').delete();
      _firestore.collection('tips').doc(_currentTip.tipsId).update({
        'likeCount': FieldValue.increment(-1),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Like removed'),
          backgroundColor: Colors.grey[700],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      _firestore.collection('likes').doc('${userId}_${_currentTip.tipsId}').set({
        'userId': userId,
        'tipId': _currentTip.tipsId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _firestore.collection('tips').doc(_currentTip.tipsId).update({
        'likeCount': FieldValue.increment(1),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Liked!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
    _safeSetState(() {
      _isLiked = !_isLiked;
    });
  }

  Future<void> _shareVideo() async {
    HapticFeedback.lightImpact();

    try {
      final shareText = 'Check out this video: ${_currentTip.tipsTitle}\n\nWatch it on our Wellness App!';
      await Share.share(shareText, subject: _currentTip.tipsTitle);
    } catch (e) {
      log('Error sharing video: $e', name: 'VideoPlayerScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _castVideo() {
    HapticFeedback.lightImpact();

    if (_isCasting) {
      _stopCasting();
      return;
    }

    _safeSetState(() {
      _isConnectingCast = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Connecting to Chromecast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 20),
            Text('Searching for available devices...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _safeSetState(() {
                _isConnectingCast = false;
              });
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text('Cast to'),
            children: [
              ListTile(
                leading: Icon(Icons.tv),
                title: Text('Living Room TV'),
                onTap: () {
                  Navigator.pop(context);
                  _startCasting('Living Room TV');
                },
              ),
              ListTile(
                leading: Icon(Icons.tv),
                title: Text('Bedroom Chromecast'),
                onTap: () {
                  Navigator.pop(context);
                  _startCasting('Bedroom Chromecast');
                },
              ),
              ListTile(
                leading: Icon(Icons.search),
                title: Text('Find more devices'),
                onTap: () {
                  Navigator.pop(context);
                  _showCastInfo();
                },
              ),
            ],
          ),
        );
      }
    });
  }

  void _startCasting(String deviceName) {
    if (_isControllerReady) {
      _controller!.pause();
    }

    _safeSetState(() {
      _isCasting = true;
      _isConnectingCast = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Casting to $deviceName'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'STOP',
          onPressed: _stopCasting,
          textColor: Colors.white,
        ),
      ),
    );
  }

  void _stopCasting() {
    _safeSetState(() {
      _isCasting = false;
    });

    if (_isControllerReady) {
      _controller!.play();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stopped casting'),
        backgroundColor: Colors.grey[700],
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCastInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chromecast Setup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cast, size: 50, color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'To use Chromecast with this app:\n\n'
                  '1. Make sure your device is on the same WiFi network as your Chromecast\n\n'
                  '2. Install the Google Home app if you haven\'t already\n\n'
                  '3. Set up your Chromecast device in the Google Home app',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadVideo() async {
    if (!mounted) return;

    final canAccessPremium = Provider.of<PremiumStatusProvider>(context, listen: false).canAccessPremium;

    if (!canAccessPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download is a premium feature'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'UPGRADE',
            onPressed: () {
              Navigator.pushNamed(context, RoutesName.subscriptionScreen);
            },
          ),
        ),
      );
      return;
    }

    if (_currentTip.videoUrl == null || _currentTip.videoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No video URL available to download'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isDownloading) {
      return;
    }

    _safeSetState(() {
      _isDownloading = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting download...'),
          duration: Duration(seconds: 1),
        ),
      );

      final http.Response response = await http.get(Uri.parse(_currentTip.videoUrl!));
      final directory = await getTemporaryDirectory();
      final safeTitle = _currentTip.tipsTitle?.replaceAll(RegExp(r'[^\w\s]+'), '') ?? 'video';
      final fileName = '${safeTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Video downloaded successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'VIEW',
              onPressed: () {
                // Requires a plugin like open_file to view the file
              },
            ),
          ),
        );
      }
    } catch (e) {
      log('Error downloading video: $e', name: 'VideoPlayerScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _safeSetState(() {
        _isDownloading = false;
      });
    }
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '';

    final difference = DateTime.now().difference(date);

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
    } else {
      return 'Just now';
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

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 230.h,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 50.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to load video',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _videoError ?? 'Please check your connection',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14.sp,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
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
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments header with expand/collapse button
        InkWell(
          onTap: _toggleCommentSection,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Row(
                  children: [
                    if (_comments.isNotEmpty) ...[
                      Text(
                        '${_comments.length}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Icon(
                      _isCommentSectionExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Expandable comment section
        AnimatedCrossFade(
          firstChild: SizedBox(height: 8.h), // Collapsed state
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              // Comment input field
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_replyToUserName != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            margin: EdgeInsets.only(bottom: 8.h),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Replying to $_replyToUserName',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12.sp,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                GestureDetector(
                                  onTap: _cancelReply,
                                  child: Icon(
                                    Icons.close,
                                    size: 16.sp,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: _replyToUserName != null
                                ? 'Add a reply...'
                                : 'Add a comment...',
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                color: AppColors.primary,
                              ),
                              onPressed: _addComment,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Comments list
              _isLoadingComments
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
                  : _comments.isEmpty
                  ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _comments.length + (_hasMoreComments ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _comments.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Center(
                        child: _isLoadingMoreComments
                            ? CircularProgressIndicator(
                          color: AppColors.primary,
                        )
                            : TextButton(
                          onPressed: _loadMoreComments,
                          child: Text(
                            'Load more comments',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final comment = _comments[index];
                  final isExpanded = _expandedCommentIds.contains(comment.id);
                  final replies = _replies
                      .where((reply) => reply.parentId == comment.id)
                      .toList();

                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18.r,
                              backgroundImage: comment.userPhotoUrl.isNotEmpty
                                  ? NetworkImage(comment.userPhotoUrl)
                                  : null,
                              backgroundColor: comment.userPhotoUrl.isEmpty
                                  ? AppColors.primary.withOpacity(0.2)
                                  : null,
                              child: comment.userPhotoUrl.isEmpty
                                  ? Text(
                                comment.userName.isNotEmpty
                                    ? comment.userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              )
                                  : null,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          comment.userName,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        _formatTimeAgo(comment.createdAt),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12.sp,
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  if (comment.text.length > 100) ...[
                                    AnimatedCrossFade(
                                      firstChild: Text(
                                        comment.text.substring(0, 100) + '...',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14.sp,
                                          color: isDarkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      secondChild: Text(
                                        comment.text,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14.sp,
                                          color: isDarkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      crossFadeState: isExpanded
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: Duration(milliseconds: 300),
                                    ),
                                    SizedBox(height: 4.h),
                                    GestureDetector(
                                      onTap: () => _toggleCommentExpansion(comment.id),
                                      child: Text(
                                        isExpanded ? 'Show less' : 'Show more',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      comment.text,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14.sp,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.thumb_up_outlined,
                                            size: 16.sp,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            comment.likeCount.toString(),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12.sp,
                                              color: isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 16.w),
                                      GestureDetector(
                                        onTap: () => _prepareToReply(comment),
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (replies.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          ...replies.map((reply) => Padding(
                            padding: EdgeInsets.only(
                              left: 48.w,
                              top: 8.h,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14.r,
                                  backgroundImage: reply.userPhotoUrl.isNotEmpty
                                      ? NetworkImage(reply.userPhotoUrl)
                                      : null,
                                  backgroundColor: reply.userPhotoUrl.isEmpty
                                      ? AppColors.primary.withOpacity(0.2)
                                      : null,
                                  child: reply.userPhotoUrl.isEmpty
                                      ? Text(
                                    reply.userName.isNotEmpty
                                        ? reply.userName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  )
                                      : null,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              reply.userName,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode ? Colors.white : Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            _formatTimeAgo(reply.createdAt),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10.sp,
                                              color: isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2.h),
                                      if (reply.text.length > 100) ...[
                                        AnimatedCrossFade(
                                          firstChild: Text(
                                            reply.text.substring(0, 100) + '...',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12.sp,
                                              color: isDarkMode ? Colors.white : Colors.black,
                                            ),
                                          ),
                                          secondChild: Text(
                                            reply.text,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12.sp,
                                              color: isDarkMode ? Colors.white : Colors.black,
                                            ),
                                          ),
                                          crossFadeState: _expandedCommentIds.contains(reply.id)
                                              ? CrossFadeState.showSecond
                                              : CrossFadeState.showFirst,
                                          duration: Duration(milliseconds: 300),
                                        ),
                                        SizedBox(height: 2.h),
                                        GestureDetector(
                                          onTap: () => _toggleCommentExpansion(reply.id),
                                          child: Text(
                                            _expandedCommentIds.contains(reply.id)
                                                ? 'Show less'
                                                : 'Show more',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          reply.text,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12.sp,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          crossFadeState: _isCommentSectionExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 8.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.primary
                  : (isDarkMode ? Colors.white70 : Colors.black54),
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.sp,
                color: isActive
                    ? AppColors.primary
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modified to correctly handle fullscreen exit
  Future<bool> _handleBackPress() async {
    log('Handling back press, isFullScreen: $_isFullScreen', name: 'VideoPlayerScreen');
    if (_isFullScreen && _isControllerReady) {
      log('Triggering fullscreen exit via back press', name: 'VideoPlayerScreen');

      // Add a delay before calling exitFullScreen to ensure the orientation changes are processed
      Future.delayed(Duration(milliseconds: 50), () {
        if (_isControllerReady && mounted) {
          _controller!.exitFullScreen();
        }
      });

      return false; // Prevent default back behavior
    }
    return true; // Allow normal back navigation
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: _isFullScreen
            ? null
            : AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDarkMode ? Colors.white : Colors.black,
              size: 24.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.categoryName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _isCasting ? Icons.cast_connected : Icons.cast,
                    color: _isCasting
                        ? AppColors.primary
                        : (isDarkMode ? Colors.white : Colors.black),
                    size: 24.sp,
                  ),
                  if (_isConnectingCast)
                    SizedBox(
                      width: 36.w,
                      height: 36.h,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.w,
                      ),
                    ),
                ],
              ),
              onPressed: _castVideo,
            ),
            SizedBox(width: 8.w),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    if (_isLoading)
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3.w,
                          ),
                        ),
                      )
                    else if (_videoError != null)
                      _buildErrorWidget()
                    else if (_isControllerReady)
                        BetterPlayer(controller: _controller!)
                      else
                        Container(
                          color: Colors.black,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    if (_isCasting)
                      Container(
                        color: Colors.black.withOpacity(0.8),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cast_connected,
                                color: Colors.white,
                                size: 48.sp,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Casting to device',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              ElevatedButton.icon(
                                onPressed: _stopCasting,
                                icon: Icon(Icons.stop),
                                label: Text('Stop Casting'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12.h),
                        Text(
                          _currentTip.tipsTitle ?? 'No Title',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Text(
                              '${_formatViewCount(_viewCount)} views • ${_formatTimeAgo(_currentTip.createdAt)}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              label: 'Like',
                              onTap: _toggleLike,
                              isActive: _isLiked,
                            ),
                            _buildActionButton(
                              icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                              label: 'Favorite',
                              onTap: _toggleFavorite,
                              isActive: _isFavorite,
                            ),
                            _buildActionButton(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              onTap: _shareVideo,
                            ),
                            _buildActionButton(
                              icon: _isDownloading ? Icons.download_done : Icons.download_outlined,
                              label: 'Download',
                              onTap: _downloadVideo,
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Divider(color: isDarkMode ? Colors.white24 : Colors.black12),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24.r,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                (_currentTip.tipsAuthor?.isNotEmpty ?? false)
                                    ? _currentTip.tipsAuthor![0].toUpperCase()
                                    : 'A',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentTip.tipsAuthor ?? 'Unknown Author',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Expert',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14.sp,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        if (_currentTip.tipsDescription != null && _currentTip.tipsDescription!.isNotEmpty) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                AnimatedCrossFade(
                                  firstChild: Text(
                                    _currentTip.tipsDescription!,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14.sp,
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  secondChild: Text(
                                    _currentTip.tipsDescription!,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14.sp,
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                  crossFadeState: _isDescriptionExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: Duration(milliseconds: 300),
                                ),
                                if (_currentTip.tipsDescription!.length > 100)
                                  TextButton(
                                    onPressed: () {
                                      _safeSetState(() {
                                        _isDescriptionExpanded = !_isDescriptionExpanded;
                                      });
                                    },
                                    child: Text(
                                      _isDescriptionExpanded ? 'Show Less' : 'Show More',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14.sp,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      alignment: Alignment.centerLeft,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],
                        Divider(color: isDarkMode ? Colors.white24 : Colors.black12),
                        SizedBox(height: 16.h),
                        _buildCommentsSection(),
                        SizedBox(height: 16.h),
                        Divider(color: isDarkMode ? Colors.white24 : Colors.black12),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Up Next',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Autoplay',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14.sp,
                                    color: isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                Switch(
                                  value: _autoplayEnabled,
                                  onChanged: (value) {
                                    _safeSetState(() {
                                      _autoplayEnabled = value;
                                    });
                                  },
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        if (_relatedVideos.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Center(
                              child: Text(
                                'No related videos found',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _relatedVideos.length,
                            itemBuilder: (context, index) {
                              final video = _relatedVideos[index];
                              return InkWell(
                                onTap: () {
                                  if (_isControllerReady) {
                                    _controller!.pause();
                                  }

                                  var oldController = _controller;
                                  _controller = null;

                                  Future.delayed(Duration(milliseconds: 50), () {
                                    if (oldController != null) {
                                      try {
                                        oldController.dispose();
                                      } catch (e) {
                                        log('Error disposing controller: $e');
                                      }
                                    }
                                  });

                                  _safeSetState(() {
                                    final oldVideo = _currentTip;
                                    _currentTip = video;
                                    _relatedVideos[index] = oldVideo;
                                    _isLoading = true;
                                    _viewCounted = false;
                                    _expandedCommentIds.clear();
                                    _isCommentSectionExpanded = false;
                                  });

                                  _initializeVideoPlayer();
                                  _initializeUser();
                                  _loadViewCount();
                                  _loadComments();
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8.r),
                                            child: Container(
                                              width: 120.w,
                                              height: 68.h,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                image: video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty
                                                    ? DecorationImage(
                                                  image: NetworkImage(video.thumbnailUrl!),
                                                  fit: BoxFit.cover,
                                                )
                                                    : null,
                                              ),
                                              child: video.thumbnailUrl == null || video.thumbnailUrl!.isEmpty
                                                  ? Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 30.sp))
                                                  : null,
                                            ),
                                          ),
                                          if (video.mediaDuration != null)
                                            Positioned(
                                              right: 4.w,
                                              bottom: 4.h,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(4.r),
                                                ),
                                                child: Text(
                                                  video.mediaDuration!,
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 10.sp,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              video.tipsTitle ?? 'No Title',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                color: isDarkMode ? Colors.white : Colors.black,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              video.tipsAuthor ?? 'Unknown Author',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12.sp,
                                                color: isDarkMode ? Colors.white70 : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        SizedBox(height: 40.h),
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
    // Don't reset orientation here as it may interfere with fullscreen exit
    _animationController.dispose();
    _scrollController.dispose();
    _commentController.dispose();

    if (_controller != null) {
      try {
        _controller!.pause();
        _controller!.dispose();
        _controller = null;
      } catch (e) {
        log('Error disposing controller: $e', name: 'VideoPlayerScreen');
      }
    }

    // Set orientation back to portrait after a delay to ensure proper cleanup
    Future.delayed(Duration(milliseconds: 100), () {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    });

    super.dispose();
  }
}