import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/favorites/data/models/favorite_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'dart:math' as Math;
import '../../domain/useCases/video_usecase.dart';
import 'package:provider/provider.dart';
import 'dart:developer';

class ShortsProvider with ChangeNotifier {
  final GetVideosUseCase _getVideosUseCase;
  final IncrementViewCountUseCase _incrementViewCountUseCase;
  final ToggleLikeUseCase _toggleLikeUseCase;
  final IsVideoLikedUseCase _isVideoLikedUseCase;
  final AuthService _authService;
  BuildContext? _context;

  List<TipModel> _shorts = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  Map<String, bool> _likedVideos = {};
  Map<String, bool> _viewedVideos = {};

  ShortsProvider({
    required GetVideosUseCase getVideosUseCase,
    required IncrementViewCountUseCase incrementViewCountUseCase,
    required ToggleLikeUseCase toggleLikeUseCase,
    required IsVideoLikedUseCase isVideoLikedUseCase,
    required AuthService authService,
  }) : _getVideosUseCase = getVideosUseCase,
        _incrementViewCountUseCase = incrementViewCountUseCase,
        _toggleLikeUseCase = toggleLikeUseCase,
        _isVideoLikedUseCase = isVideoLikedUseCase,
        _authService = authService;

  // Set context for accessing providers
  void setContext(BuildContext context) {
    _context = context;
  }

  // Getters
  List<TipModel> get shorts => _shorts;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  TipModel? get currentShort =>
      _shorts.isNotEmpty && _currentIndex < _shorts.length
          ? _shorts[_currentIndex]
          : null;
  bool isShortLiked(String tipsId) => _likedVideos[tipsId] ?? false;

  // Load initial shorts
  Future<void> loadShorts({String? categoryId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final shorts = await _getVideosUseCase.execute(
        isShort: true,
        categoryId: categoryId,
        limit: 10,
      );

      final uniqueShorts = _removeDuplicates(shorts);
      log('Loaded shorts: ${uniqueShorts.map((s) => s.tipsId).toList()}', name: 'ShortsProvider');

      _shorts = uniqueShorts;
      _hasMore = shorts.length >= 10;
      _currentIndex = 0;
      _isLoading = false;

      _checkLikeStatus();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load shorts: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more shorts for infinite scrolling
  Future<void> loadMoreShorts({String? categoryId}) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final moreShorts = await _getVideosUseCase.execute(
        isShort: true,
        categoryId: categoryId,
        limit: 10,
      );

      final uniqueMoreShorts = _removeDuplicates(moreShorts)
          .where((newShort) => !_shorts.any((existing) => existing.tipsId == newShort.tipsId))
          .toList();

      log('Loaded more shorts: ${uniqueMoreShorts.map((s) => s.tipsId).toList()}', name: 'ShortsProvider');

      if (uniqueMoreShorts.isEmpty) {
        _hasMore = false;
      } else {
        _shorts.addAll(uniqueMoreShorts);
        _hasMore = uniqueMoreShorts.length >= 10;
      }

      _isLoadingMore = false;
      _checkLikeStatus();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load more shorts: $e';
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Helper to remove duplicates from a list of shorts
  List<TipModel> _removeDuplicates(List<TipModel> shorts) {
    final Map<String, TipModel> uniqueMap = {};
    for (final short in shorts) {
      uniqueMap[short.tipsId] = short;
    }
    return uniqueMap.values.toList();
  }

  // Change current short
  void changeCurrentIndex(int index) {
    if (index < 0 || index >= _shorts.length) return;

    _currentIndex = index;
    log('Changed to index: $index, tipsId: ${_shorts[index].tipsId}', name: 'ShortsProvider');
    _incrementViewCount();
    notifyListeners();

    if (_hasMore && _currentIndex >= _shorts.length - 3) {
      loadMoreShorts();
    }
  }

  // Check like status for all shorts
  Future<void> _checkLikeStatus() async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    for (var short in _shorts) {
      if (_likedVideos.containsKey(short.tipsId)) continue;

      try {
        final isLiked = await _isVideoLikedUseCase.execute(
          short.tipsId,
          userId,
        );
        _likedVideos[short.tipsId] = isLiked;
      } catch (e) {
        _likedVideos[short.tipsId] = false;
      }
    }

    notifyListeners();
  }

  // Toggle like for a short and sync with FavoritesProvider
  Future<void> toggleLike(String tipsId, BuildContext context) async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) {
      _error = 'You need to be logged in to like videos';
      notifyListeners();
      return;
    }

    // Get current like state
    final isCurrentlyLiked = _likedVideos[tipsId] ?? false;
    final newLikeState = !isCurrentlyLiked;

    // Find the video in the list
    final videoIndex = _shorts.indexWhere((v) => v.tipsId == tipsId);
    if (videoIndex == -1) {
      log('Video not found in shorts list: $tipsId', name: 'ShortsProvider');
      return;
    }

    final video = _shorts[videoIndex];

    // Prepare for optimistic update
    final originalVideo = video;
    final originalLikeState = isCurrentlyLiked;

    try {
      // Apply optimistic update to local state immediately
      _likedVideos[tipsId] = newLikeState;

      // Update like count
      final updatedLikeCount = newLikeState
          ? video.likeCount + 1
          : Math.max(0, video.likeCount - 1);

      _shorts[videoIndex] = video.copyWith(likeCount: updatedLikeCount);

      // Notify UI immediately for responsive feedback
      notifyListeners();

      // Perform the actual database update
      await _toggleLikeUseCase.execute(tipsId, userId);

      // Update favorites
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

      if (newLikeState) {
        // Add to favorites
        final favorite = FavoriteModel(
          id: '${userId}_$tipsId',
          tipId: tipsId,
          userId: userId,
          createdAt: DateTime.now(),
        );

        // Check if it's already a favorite to avoid duplicates
        if (!favoritesProvider.isFavorite(tipsId, userId)) {
          await favoritesProvider.addFavorite(favorite);
          log('Added video $tipsId to favorites', name: 'ShortsProvider');
        }
      } else {
        // Remove from favorites
        if (favoritesProvider.isFavorite(tipsId, userId)) {
          final favorite = favoritesProvider.favorites.firstWhere(
                (f) => f.tipId == tipsId && f.userId == userId,
            orElse: () => FavoriteModel(id: '${userId}_$tipsId', tipId: tipsId, userId: userId),
          );

          await favoritesProvider.deleteFavorite(favorite.id);
          log('Removed video $tipsId from favorites', name: 'ShortsProvider');
        }
      }
    } catch (e) {
      // Revert optimistic updates on error
      log('Error toggling like: $e', name: 'ShortsProvider');

      // Restore original state
      _likedVideos[tipsId] = originalLikeState;
      _shorts[videoIndex] = originalVideo;

      _error = 'Failed to update like status: $e';
      notifyListeners();
    }
  }

  // Increment view count for current short
  Future<void> _incrementViewCount() async {
    final currentShort = this.currentShort;
    if (currentShort == null) return;

    if (_viewedVideos[currentShort.tipsId] ?? false) return;

    try {
      await _incrementViewCountUseCase.execute(currentShort.tipsId);
      _viewedVideos[currentShort.tipsId] = true;

      final videoIndex = _shorts.indexWhere(
            (v) => v.tipsId == currentShort.tipsId,
      );
      if (videoIndex != -1) {
        _shorts[videoIndex] = currentShort.copyWith(
          viewCount: currentShort.viewCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      log('Error incrementing view count: $e', name: 'ShortsProvider');
    }
  }

  // Enhanced addShorts method
  void addShorts(List<TipModel> newShorts) {
    if (newShorts.isEmpty) return;

    final uniqueNewShorts = _removeDuplicates(newShorts)
        .where((newShort) => !_shorts.any((existing) => existing.tipsId == newShort.tipsId))
        .toList();

    log('Adding new shorts: ${uniqueNewShorts.map((s) => s.tipsId).toList()}', name: 'ShortsProvider');

    if (uniqueNewShorts.isNotEmpty) {
      _shorts.insertAll(0, uniqueNewShorts);
      notifyListeners();
    }
  }

  // Select a short by ID
  void selectShortById(String tipsId) {
    final index = _shorts.indexWhere((s) => s.tipsId == tipsId);
    if (index != -1) {
      changeCurrentIndex(index);
    }
  }

  // Sync like status with favorites
  Future<void> syncWithFavorites(BuildContext context) async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    try {
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);

      // Force reload favorites to ensure we have the latest data
      await favoritesProvider.loadFavorites(userId);

      bool updated = false;

      // Update like status based on favorites
      for (var short in _shorts) {
        final isFavorite = favoritesProvider.isFavorite(short.tipsId, userId);
        if (_likedVideos[short.tipsId] != isFavorite) {
          _likedVideos[short.tipsId] = isFavorite;
          updated = true;

          // Also update like counts if necessary
          final videoIndex = _shorts.indexWhere((v) => v.tipsId == short.tipsId);
          if (videoIndex != -1) {
            // Only update if the count doesn't match the like status
            final currentVideo = _shorts[videoIndex];
            final expectedLikeState = isFavorite;

            // Simple heuristic: if liked, count should be at least 1
            if (expectedLikeState && currentVideo.likeCount < 1) {
              _shorts[videoIndex] = currentVideo.copyWith(likeCount: Math.max(1, currentVideo.likeCount));
            }
          }
        }
      }

      if (updated) {
        log('Updated like status for ${_shorts.length} videos based on favorites', name: 'ShortsProvider');
        notifyListeners();
      }
    } catch (e) {
      log('Error syncing with favorites: $e', name: 'ShortsProvider');
    }
  }
}