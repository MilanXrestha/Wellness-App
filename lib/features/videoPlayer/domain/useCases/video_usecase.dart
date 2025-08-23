import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import '../../data/models/comments_model.dart';
import '../../data/services/video_service.dart';

class GetVideosUseCase {
  final VideoService _videoService;

  GetVideosUseCase(this._videoService);

  Future<List<TipModel>> execute({
    bool? isShort,
    String? categoryId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) {
    return _videoService.getVideos(
      isShort: isShort,
      categoryId: categoryId,
      limit: limit,
      lastDocument: lastDocument,
    );
  }
}

class IncrementViewCountUseCase {
  final VideoService _videoService;

  IncrementViewCountUseCase(this._videoService);

  Future<void> execute(String tipsId) {
    return _videoService.incrementViewCount(tipsId);
  }
}

class ToggleLikeUseCase {
  final VideoService _videoService;

  ToggleLikeUseCase(this._videoService);

  Future<void> execute(String tipsId, String userId) {
    return _videoService.toggleLike(tipsId, userId);
  }
}

class IsVideoLikedUseCase {
  final VideoService _videoService;

  IsVideoLikedUseCase(this._videoService);

  Future<bool> execute(String tipsId, String userId) {
    return _videoService.isVideoLiked(tipsId, userId);
  }
}

class AddCommentUseCase {
  final VideoService _videoService;

  AddCommentUseCase(this._videoService);

  Future<CommentModel?> execute({
    required String tipsId,
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String text,
    String? parentId,
  }) {
    return _videoService.addComment(
      tipsId: tipsId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      text: text,
      parentId: parentId,
    );
  }
}

class GetCommentsUseCase {
  final VideoService _videoService;

  GetCommentsUseCase(this._videoService);

  Future<List<CommentModel>> execute(String tipsId, {int limit = 20}) {
    return _videoService.getComments(tipsId, limit: limit);
  }
}

class GetRepliesUseCase {
  final VideoService _videoService;

  GetRepliesUseCase(this._videoService);

  Future<List<CommentModel>> execute(String commentId) {
    return _videoService.getReplies(commentId);
  }
}
