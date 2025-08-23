import 'package:flutter/foundation.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';

import '../../data/models/comments_model.dart';
import '../../domain/useCases/video_usecase.dart';

class VideoPlayerProvider with ChangeNotifier {
  final IncrementViewCountUseCase _incrementViewCountUseCase;
  final ToggleLikeUseCase _toggleLikeUseCase;
  final IsVideoLikedUseCase _isVideoLikedUseCase;
  final AddCommentUseCase _addCommentUseCase;
  final GetCommentsUseCase _getCommentsUseCase;
  final GetRepliesUseCase _getRepliesUseCase;
  final AuthService _authService;

  TipModel? _currentVideo;
  bool _isLiked = false;
  bool _isLoading = false;
  bool _isCommentsLoading = false;
  bool _viewCounted = false;
  String? _error;
  List<CommentModel> _comments = [];
  Map<String, List<CommentModel>> _replies = {};

  VideoPlayerProvider({
    required IncrementViewCountUseCase incrementViewCountUseCase,
    required ToggleLikeUseCase toggleLikeUseCase,
    required IsVideoLikedUseCase isVideoLikedUseCase,
    required AddCommentUseCase addCommentUseCase,
    required GetCommentsUseCase getCommentsUseCase,
    required GetRepliesUseCase getRepliesUseCase,
    required AuthService authService,
  }) : _incrementViewCountUseCase = incrementViewCountUseCase,
       _toggleLikeUseCase = toggleLikeUseCase,
       _isVideoLikedUseCase = isVideoLikedUseCase,
       _addCommentUseCase = addCommentUseCase,
       _getCommentsUseCase = getCommentsUseCase,
       _getRepliesUseCase = getRepliesUseCase,
       _authService = authService;

  // Getters
  TipModel? get currentVideo => _currentVideo;

  bool get isLiked => _isLiked;

  bool get isLoading => _isLoading;

  bool get isCommentsLoading => _isCommentsLoading;

  String? get error => _error;

  List<CommentModel> get comments => _comments;

  Map<String, List<CommentModel>> get replies => _replies;

  // Initialize video data
  Future<void> initializeVideo(TipModel video) async {
    _currentVideo = video;
    _isLoading = true;
    _viewCounted = false;
    _error = null;
    notifyListeners();

    try {
      // Check if user has liked the video
      final userId = _authService.getCurrentUser()?.uid;
      if (userId != null) {
        _isLiked = await _isVideoLikedUseCase.execute(video.tipsId, userId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Increment view count
  Future<void> incrementViewCount() async {
    if (_currentVideo == null || _viewCounted) return;

    try {
      await _incrementViewCountUseCase.execute(_currentVideo!.tipsId);
      _viewCounted = true;

      // Update the current video with incremented view count
      _currentVideo = _currentVideo!.copyWith(
        viewCount: _currentVideo!.viewCount + 1,
      );
      notifyListeners();
    } catch (e) {
      // Silently fail - view count is not critical
      debugPrint('Error incrementing view count: $e');
    }
  }

  // Toggle like status
  Future<void> toggleLike() async {
    if (_currentVideo == null) return;

    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) {
      _error = 'You need to be logged in to like videos';
      notifyListeners();
      return;
    }

    try {
      // Optimistic update
      _isLiked = !_isLiked;
      final updatedLikeCount = _isLiked
          ? _currentVideo!.likeCount + 1
          : _currentVideo!.likeCount - 1;

      _currentVideo = _currentVideo!.copyWith(likeCount: updatedLikeCount);
      notifyListeners();

      // Make the API call
      await _toggleLikeUseCase.execute(_currentVideo!.tipsId, userId);
    } catch (e) {
      // Revert the optimistic update
      _isLiked = !_isLiked;
      final updatedLikeCount = _isLiked
          ? _currentVideo!.likeCount + 1
          : _currentVideo!.likeCount - 1;

      _currentVideo = _currentVideo!.copyWith(likeCount: updatedLikeCount);

      _error = 'Failed to update like status';
      notifyListeners();
    }
  }

  // Load comments
  Future<void> loadComments() async {
    if (_currentVideo == null) return;

    _isCommentsLoading = true;
    notifyListeners();

    try {
      _comments = await _getCommentsUseCase.execute(_currentVideo!.tipsId);
      _isCommentsLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load comments';
      _isCommentsLoading = false;
      notifyListeners();
    }
  }

  // Load replies for a specific comment
  Future<void> loadReplies(String commentId) async {
    try {
      final replies = await _getRepliesUseCase.execute(commentId);
      _replies[commentId] = replies;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load replies';
      notifyListeners();
    }
  }

  // Add a comment
  Future<bool> addComment(String text, {String? parentId}) async {
    if (_currentVideo == null) return false;

    final user = _authService.getCurrentUser();
    if (user == null) {
      _error = 'You need to be logged in to comment';
      notifyListeners();
      return false;
    }

    try {
      final comment = await _addCommentUseCase.execute(
        tipsId: _currentVideo!.tipsId,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        userPhotoUrl: user.photoURL ?? '',
        text: text,
        parentId: parentId,
      );

      if (comment == null) {
        _error = 'Failed to add comment';
        notifyListeners();
        return false;
      }

      if (parentId == null) {
        // Add to top-level comments
        _comments.insert(0, comment);
        _currentVideo = _currentVideo!.copyWith(
          commentCount: _currentVideo!.commentCount + 1,
        );
      } else {
        // Add to replies
        _replies[parentId] = _replies[parentId] ?? [];
        _replies[parentId]!.add(comment);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add comment';
      notifyListeners();
      return false;
    }
  }
}
