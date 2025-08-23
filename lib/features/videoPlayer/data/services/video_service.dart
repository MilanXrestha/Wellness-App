import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/videoPlayer/data/models/likes_model.dart';

import '../models/comments_model.dart';

class VideoService {
  // Lazy getter that returns null if Firebase isn't available
  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isEmpty) {
        developer.log('No Firebase app initialized', name: 'VideoService');
        return null;
      }
      return FirebaseFirestore.instance;
    } catch (e) {
      developer.log('Firebase not available: $e', name: 'VideoService');
      return null;
    }
  }

  // Get videos (can filter by isShort and category)
  Future<List<TipModel>> getVideos({
    bool? isShort,
    String? categoryId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final db = _firestore;
      if (db == null) {
        developer.log(
          'Firebase not available for getVideos',
          name: 'VideoService',
        );
        return [];
      }

      Query query = db.collection('tips').where('tipsType', isEqualTo: 'video');

      if (isShort != null) {
        query = query.where('isShort', isEqualTo: isShort);
      }

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) => TipModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      developer.log('Error getting videos: $e', name: 'VideoService');
      return [];
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String tipsId) async {
    try {
      final db = _firestore;
      if (db == null) {
        developer.log(
          'Firebase not available for incrementViewCount',
          name: 'VideoService',
        );
        return;
      }

      await db.collection('tips').doc(tipsId).update({
        'viewCount': FieldValue.increment(1),
      });
      developer.log('Incremented view count for $tipsId', name: 'VideoService');
    } catch (e) {
      developer.log('Error incrementing view count: $e', name: 'VideoService');
    }
  }

  // Toggle like (like/unlike)
  Future<void> toggleLike(String tipsId, String userId) async {
    try {
      final db = _firestore;
      if (db == null) {
        developer.log(
          'Firebase not available for toggleLike',
          name: 'VideoService',
        );
        return;
      }

      final likeId = '${userId}_${tipsId}';
      final likeDoc = await db.collection('likes').doc(likeId).get();

      if (likeDoc.exists) {
        // Unlike
        await db.runTransaction((transaction) async {
          transaction.delete(db.collection('likes').doc(likeId));
          transaction.update(db.collection('tips').doc(tipsId), {
            'likeCount': FieldValue.increment(-1),
          });
        });
        developer.log(
          'Removed like for $tipsId by user $userId',
          name: 'VideoService',
        );
      } else {
        // Like
        await db.runTransaction((transaction) async {
          transaction.set(
            db.collection('likes').doc(likeId),
            LikeModel.create(userId, tipsId).toFirestore(),
          );
          transaction.update(db.collection('tips').doc(tipsId), {
            'likeCount': FieldValue.increment(1),
          });
        });
        developer.log(
          'Added like for $tipsId by user $userId',
          name: 'VideoService',
        );
      }
    } catch (e) {
      developer.log('Error toggling like: $e', name: 'VideoService');
    }
  }

  // Check if user liked a video
  Future<bool> isVideoLiked(String tipsId, String userId) async {
    try {
      final db = _firestore;
      if (db == null) {
        developer.log(
          'Firebase not available for isVideoLiked',
          name: 'VideoService',
        );
        return false;
      }

      final likeId = '${userId}_${tipsId}';
      final likeDoc = await db.collection('likes').doc(likeId).get();
      return likeDoc.exists;
    } catch (e) {
      developer.log(
        'Error checking if video is liked: $e',
        name: 'VideoService',
      );
      return false;
    }
  }

  // Add comment
  Future<CommentModel?> addComment({
    required String tipsId,
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String text,
    String? parentId,
  }) async {
    try {
      final db = _firestore;
      if (db == null) {
        developer.log(
          'Firebase not available for addComment',
          name: 'VideoService',
        );
        return null;
      }

      final commentRef = db.collection('comments').doc();
      final comment = CommentModel(
        id: commentRef.id,
        tipsId: tipsId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        text: text,
        createdAt: DateTime.now(),
        parentId: parentId,
      );

      await db.runTransaction((transaction) async {
        transaction.set(commentRef, comment.toFirestore());

        if (parentId == null) {
          // Only increment comment count for top-level comments
          transaction.update(db.collection('tips').doc(tipsId), {
            'commentCount': FieldValue.increment(1),
          });
        }
      });

      developer.log('Added comment for $tipsId', name: 'VideoService');
      return comment;
    } catch (e) {
      developer.log('Error adding comment: $e', name: 'VideoService');
      return null;
    }
  }

  // Get comments for a video
  Future<List<CommentModel>> getComments(
    String tipsId, {
    int limit = 20,
  }) async {
    try {
      final db = _firestore;
      if (db == null) {
        developer.log(
          'Firebase not available for getComments',
          name: 'VideoService',
        );
        return [];
      }

      final snapshot = await db
          .collection('comments')
          .where('tipsId', isEqualTo: tipsId)
          .where('parentId', isNull: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      developer.log('Error getting comments: $e', name: 'VideoService');
      return [];
    }
  }

  // Get replies for a comment
  Future<List<CommentModel>> getReplies(String commentId) async {
    try {
      final db = _firestore;
      if (db == null) {
        developer.log(
          'Firebase not available for getReplies',
          name: 'VideoService',
        );
        return [];
      }

      final snapshot = await db
          .collection('comments')
          .where('parentId', isEqualTo: commentId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      developer.log('Error getting replies: $e', name: 'VideoService');
      return [];
    }
  }

  // Update duration info
  Future<void> updateVideoDuration(String tipsId, int durationInSeconds) async {
    try {
      final db = _firestore;
      if (db == null) {
        developer.log(
          'Firebase not available for updateVideoDuration',
          name: 'VideoService',
        );
        return;
      }

      await db.collection('tips').doc(tipsId).update({
        'durationInSeconds': durationInSeconds,
        'isShort': durationInSeconds < 60,
      });
      developer.log(
        'Updated duration for $tipsId: $durationInSeconds',
        name: 'VideoService',
      );
    } catch (e) {
      developer.log('Error updating video duration: $e', name: 'VideoService');
    }
  }
}
