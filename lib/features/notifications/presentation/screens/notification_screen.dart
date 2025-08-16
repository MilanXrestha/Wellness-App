import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wellness_app/features/notifications/data/models/notification_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/db/database_helper.dart';
import 'dart:developer';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _checkUnreadNotifications();
  }

  Future<void> _checkUnreadNotifications() async {
    final userId = AuthService().getCurrentUser()?.uid;
    if (userId != null) {
      try {
        final notifications = await DatabaseHelper.instance.getNotificationsByUser(userId);
        log('Local notifications fetched: ${notifications.length}');
        setState(() {
          _hasUnreadNotifications = notifications.any((n) => !n.isRead);
        });
      } catch (e, stackTrace) {
        log('Error fetching local notifications: $e', stackTrace: stackTrace);
      }
    } else {
      log('No userId found for checking unread notifications');
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      log('Marked ${notifications.docs.length} notifications as read in Firestore');

      final localNotifications = await DatabaseHelper.instance.getNotificationsByUser(userId);
      for (var notification in localNotifications) {
        if (!notification.isRead) {
          await DatabaseHelper.instance.insertNotification(
            NotificationModel(
              id: notification.id,
              userId: notification.userId,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              isRead: true,
              payload: notification.payload,
              timestamp: notification.timestamp,
            ),
          );
        }
      }
      setState(() {
        _hasUnreadNotifications = false;
      });
      log('Marked all notifications as read locally');
    } catch (e, stackTrace) {
      log('Error marking all notifications as read: $e', stackTrace: stackTrace);
    }
  }

  Future<void> _deleteNotification(String id, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(id).delete();
      log('Deleted notification from Firestore: $id');
      await DatabaseHelper.instance.deleteNotification(id);
      log('Deleted notification from local database: $id');
      await _checkUnreadNotifications();
    } catch (e, stackTrace) {
      log('Error deleting notification $id: $e', stackTrace: stackTrace);
    }
  }

  Widget _buildNotificationList(
      BuildContext context,
      List<NotificationModel> notifications,
      ThemeData theme,
      bool isDarkMode,
      ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(16.r),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20.w),
            child: Icon(
              Icons.delete,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          onDismissed: (direction) async {
            await _deleteNotification(notification.id, notification.userId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Notification deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    final restoredNotification = NotificationModel(
                      id: notification.id,
                      userId: notification.userId,
                      title: notification.title,
                      body: notification.body,
                      type: notification.type,
                      isRead: notification.isRead,
                      payload: notification.payload,
                      timestamp: notification.timestamp,
                    );
                    try {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(notification.id)
                          .set(restoredNotification.toFirestore());
                      log('Restored notification to Firestore: ${notification.id}');
                      await DatabaseHelper.instance.insertNotification(restoredNotification);
                      log('Restored notification to local database: ${notification.id}');
                      await _checkUnreadNotifications();
                    } catch (e, stackTrace) {
                      log('Error restoring notification ${notification.id}: $e', stackTrace: stackTrace);
                    }
                  },
                ),
              ),
            );
          },
          child: Animate(
            effects: [
              FadeEffect(duration: 300.ms, delay: (index * 100).ms),
              SlideEffect(
                begin: Offset(0, 0.1),
                end: Offset.zero,
                duration: 300.ms,
                delay: (index * 100).ms,
              ),
            ],
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16.r),
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [Colors.grey[850]!, Colors.grey[900]!]
                          : [Colors.white, Colors.grey.shade100],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                      width: 1.w,
                    ),
                  ),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: () async {
                        log('Tapped notification: id=${notification.id}, title=${notification.title}, payload=${notification.payload}');
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(notification.id)
                            .update({'isRead': true});
                        await DatabaseHelper.instance.insertNotification(
                          NotificationModel(
                            id: notification.id,
                            userId: notification.userId,
                            title: notification.title,
                            body: notification.body,
                            type: notification.type,
                            isRead: true,
                            payload: notification.payload,
                            timestamp: notification.timestamp,
                          ),
                        );
                        await _checkUnreadNotifications();
                        final payloadMap = notification.payload;
                        final isFromReminder = payloadMap['isFromReminder'] as bool? ?? false;
                        if (payloadMap.containsKey('tipId')) {
                          final tipId = payloadMap['tipId'] as String?;
                          log('Fetching tip with tipId=$tipId');
                          if (tipId != null && tipId.isNotEmpty) {
                            final tipDoc = await FirebaseFirestore.instance
                                .collection('tips')
                                .doc(tipId)
                                .get();
                            if (tipDoc.exists && tipDoc.data() != null) {
                              final tip = TipModel.fromFirestore(
                                tipDoc.data()!,
                                tipDoc.id,
                              );
                              log('Navigating to TipsDetailScreen with tip: title=${tip.tipsTitle}, id=${tip.tipsId}');
                              Navigator.pushNamed(
                                context,
                                RoutesName.tipsDetailScreen,
                                arguments: {
                                  'tip': tip,
                                  'categoryName': isFromReminder
                                      ? 'Recently Added'
                                      : (notification.type == 'tip' ? 'Health Tips' : 'Latest Quotes'),
                                  'userId': notification.userId,
                                  'featuredTips': <TipModel>[], // Empty to avoid extra content
                                  'allHealthTips': false,      // Always false to show only the specific tip
                                  'allQuotes': false,          // Always false to show only the specific tip
                                },
                              );
                            } else {
                              log('Tip not found for tipId=$tipId');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Tip not found')),
                              );
                            }
                          } else {
                            log('Invalid or missing tipId in payload');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invalid notification data')),
                            );
                          }
                        } else {
                          log('No tipId in payload');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No tip associated with this notification')),
                          );
                        }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: notification.isRead
                                  ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
                                  : AppColors.primary.withOpacity(0.1),
                            ),
                            child: Icon(
                              notification.isRead
                                  ? Icons.notifications
                                  : Icons.notifications_active,
                              color: notification.isRead
                                  ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                                  : AppColors.primary,
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  notification.body,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14.sp,
                                    color: isDarkMode
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _formatTimestamp(notification.timestamp),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12.sp,
                                    color: isDarkMode
                                        ? AppColors.darkTextSecondary.withOpacity(0.7)
                                        : AppColors.lightTextSecondary.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              margin: EdgeInsets.only(top: 8.h),
                              width: 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),





                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildShimmer(BuildContext context, bool isDarkMode) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 200.w,
                          height: 16.h,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          width: 150.w,
                          height: 14.h,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          width: 100.w,
                          height: 12.h,
                          color: Colors.grey,
                        ),
                      ],
                    ),
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
    final userId = AuthService().getCurrentUser()?.uid;
    log('NotificationScreen userId: $userId');

    if (userId != null) {
      FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get()
          .then((snapshot) {
        log('Firestore query returned ${snapshot.docs.length} documents: ${snapshot.docs.map((doc) => doc.id).toList()}');
      }).catchError((e, stackTrace) {
        log('Error fetching Firestore notifications: $e', stackTrace: stackTrace);
      });
    } else {
      log('No userId, skipping Firestore query');
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Notifications',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          actions: [
            if (_hasUnreadNotifications)
              TextButton(
                onPressed: () => _markAllAsRead(userId!),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                ),
                child: Text(
                  'Mark All Read',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: userId == null
            ? Center(
          child: Text(
            'Please sign in to view notifications',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 16.sp,
            ),
          ),
        )
            : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            log('StreamBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}, error: ${snapshot.error}');
            if (snapshot.connectionState == ConnectionState.waiting) {
              log('StreamBuilder waiting');
              return _buildShimmer(context, isDarkMode);
            }
            if (snapshot.hasError) {
              log('StreamBuilder error: ${snapshot.error}');
              return FutureBuilder<List<NotificationModel>>(
                future: DatabaseHelper.instance.getNotificationsByUser(userId),
                builder: (context, localSnapshot) {
                  if (localSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmer(context, isDarkMode);
                  }
                  if (localSnapshot.hasError || !localSnapshot.hasData || localSnapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error ?? 'No notifications available'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 16.sp,
                        ),
                      ),
                    );
                  }
                  final notifications = localSnapshot.data!;
                  log('Using local notifications: ${notifications.length}');
                  return _buildNotificationList(context, notifications, theme, isDarkMode);
                },
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              log('StreamBuilder no data, checking local cache');
              return FutureBuilder<List<NotificationModel>>(
                future: DatabaseHelper.instance.getNotificationsByUser(userId),
                builder: (context, localSnapshot) {
                  if (localSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmer(context, isDarkMode);
                  }
                  if (localSnapshot.hasError || !localSnapshot.hasData || localSnapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No notifications available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 16.sp,
                        ),
                      ),
                    );
                  }
                  final notifications = localSnapshot.data!;
                  log('Using local notifications: ${notifications.length}');
                  return _buildNotificationList(context, notifications, theme, isDarkMode);
                },
              );
            }

            final notifications = snapshot.data!.docs
                .map(
                  (doc) => NotificationModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
                .toList();
            log('StreamBuilder fetched ${notifications.length} notifications: ${notifications.map((n) => n.id).toList()}');

            return _buildNotificationList(context, notifications, theme, isDarkMode);
          },
        ),
      ),
    );
  }
}