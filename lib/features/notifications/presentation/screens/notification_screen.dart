import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wellness_app/features/notifications/data/models/notification_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/core/resources/colors.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/db/database_helper.dart';
import 'dart:developer';

import '../../../dashboard/presentation/providers/notification_count_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _hasUnreadNotifications = false;
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  Stream<QuerySnapshot>? _notificationStream;

  @override
  void initState() {
    super.initState();
    final userId = AuthService()
        .getCurrentUser()
        ?.uid;
    if (userId != null) {
      _notificationStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots();

      // Load initial data
      _loadInitialData();
    }

    // Fetch the latest count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationCountProvider>(context, listen: false)
          .fetchUnreadNotificationCount();
    });
  }

  Future<void> _loadInitialData() async {
    final userId = AuthService()
        .getCurrentUser()
        ?.uid;
    if (userId != null) {
      try {
        final notifications = await DatabaseHelper.instance
            .getNotificationsByUser(userId);
        log('Local notifications fetched: ${notifications.length}');
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _hasUnreadNotifications = notifications.any((n) => !n.isRead);
            _isLoading = false;
          });
        }
      } catch (e, stackTrace) {
        log('Error fetching local notifications: $e', stackTrace: stackTrace);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      log('No userId found for checking unread notifications');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    // First update local state
    List<NotificationModel> updatedNotifications = _notifications.map((
        notification) =>
        NotificationModel(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          body: notification.body,
          type: notification.type,
          isRead: true,
          payload: notification.payload,
          timestamp: notification.timestamp,
        )
    ).toList();

    setState(() {
      _notifications = updatedNotifications;
      _hasUnreadNotifications = false;
    });

    // Then perform the server update
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
      log('Marked ${notifications.docs
          .length} notifications as read in Firestore');

      final localNotifications = await DatabaseHelper.instance
          .getNotificationsByUser(userId);
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
      // Update the notification provider
      final provider = Provider.of<NotificationCountProvider>(
          context, listen: false);
      await provider.markAllNotificationsAsRead();

      log('Marked all notifications as read locally');
    } catch (e, stackTrace) {
      log('Error marking all notifications as read: $e',
          stackTrace: stackTrace);
    }
  }

  Future<void> _deleteNotification(String id, String userId, int index) async {
    // First remove from local list
    final deletedNotification = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
      _hasUnreadNotifications = _notifications.any((n) => !n.isRead);
    });

    try {
      // Then perform the server operation
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .delete();
      log('Deleted notification from Firestore: $id');
      await DatabaseHelper.instance.deleteNotification(id);
      log('Deleted notification from local database: $id');
    } catch (e, stackTrace) {
      log('Error deleting notification $id: $e', stackTrace: stackTrace);
      // If there was an error, add the notification back
      setState(() {
        _notifications.insert(index, deletedNotification);
        _hasUnreadNotifications = _notifications.any((n) => !n.isRead);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification')),
      );
    }
  }

  Future<void> _navigateToContent(NotificationModel notification) async {
    try {
      // Mark notification as read locally first for immediate UI feedback
      int notificationIndex = _notifications.indexWhere((n) =>
      n.id == notification.id);
      if (notificationIndex >= 0 && !_notifications[notificationIndex].isRead) {
        setState(() {
          _notifications[notificationIndex] = NotificationModel(
            id: notification.id,
            userId: notification.userId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            isRead: true,
            payload: notification.payload,
            timestamp: notification.timestamp,
          );
          _hasUnreadNotifications = _notifications.any((n) => !n.isRead);
        });
      }

      // Extract data from payload
      final payloadMap = notification.payload;
      final tipId = payloadMap['tipId'] as String?;
      final contentType = payloadMap['contentType'] as String? ??
          notification.type;
      final isFromReminder = payloadMap['isFromReminder'] as bool? ?? false;

      if (tipId == null || tipId.isEmpty) {
        log('No tipId in notification payload');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No content associated with this notification')),
        );
        return;
      }

      // Start the marking as read operation in the background
      final markAsReadFuture = FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .update({'isRead': true})
          .then((_) {
        return DatabaseHelper.instance.insertNotification(
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
      })
          .then((_) {
        Provider.of<NotificationCountProvider>(context, listen: false)
            .decrementUnreadCount();
      });

      // Fetch only the tip data needed for navigation
      final tipDoc = await FirebaseFirestore.instance
          .collection('tips')
          .doc(tipId)
          .get();

      if (!tipDoc.exists || tipDoc.data() == null) {
        log('Tip not found for tipId=$tipId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Content not found')),
        );
        return;
      }

      final tip = TipModel.fromFirestore(tipDoc.data()!, tipDoc.id);
      log('Fetched tip: ${tip.tipsId}, type: ${tip.tipsType}');

      // Navigate based on content type - without waiting for related content
      switch (tip.tipsType) {
        case 'video':
        // Check if the video is short (isShort is true or duration < 60 seconds)
          if (tip.isShort == true ||
              (tip.durationInSeconds != null && tip.durationInSeconds! < 60)) {
            Navigator.pushNamed(
              context,
              RoutesName.shortVideoPlayerScreen,
              arguments: {
                'tip': tip,
                'categoryName': isFromReminder
                    ? 'Short Video Content'
                    : 'Shorts',
                'featuredTips': [tip], // Just pass the current tip
              },
            );
          }
          else {
            Navigator.pushNamed(
              context,
              RoutesName.videoPlayerScreen,
              arguments: {
                'tip': tip,
                'categoryName': isFromReminder ? 'Video Content' : 'Videos',
                'featuredTips': [tip],
                // Just pass the current tip
                'shouldLoadRelated': true,
                // Signal to load related content after navigation
              },
            );
          }
          break;

        case 'audio':
          Navigator.pushNamed(
            context,
            RoutesName.mediaPlayerScreen,
            arguments: {
              'tip': tip,
              'categoryName': isFromReminder ? 'Audio Content' : 'Audio',
              'featuredTips': [tip],
              // Just pass the current tip
              'shouldLoadRelated': true,
              // Signal to load related content after navigation
            },
          );
          break;

        case 'image':
          Navigator.pushNamed(
            context,
            RoutesName.imageViewerScreen,
            arguments: {
              'tip': tip,
              'imageTips': [tip],
              // Just pass the current tip
              'initialIndex': 0,
              'shouldLoadRelated': true,
              // Signal to load related content after navigation
            },
          );
          break;

        default:
          Navigator.pushNamed(
            context,
            RoutesName.tipsDetailScreen,
            arguments: {
              'tip': tip,
              'categoryName': isFromReminder
                  ? 'Recently Added'
                  : (tip.tipsType == 'tip' ? 'Health Tips' : 'Latest Quotes'),
              'userId': notification.userId,
              'featuredTips': [tip],
              // Just pass the current tip
              'allHealthTips': false,
              'allQuotes': false,
              'shouldLoadRelated': true,
              // Signal to load related content after navigation
            },
          );
          break;
      }

      // Complete the background operation
      await markAsReadFuture;
    } catch (e, stackTrace) {
      log('Error navigating to content: $e', stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Get an icon based on notification type/content type
  IconData _getNotificationIcon(NotificationModel notification) {
    final contentType = notification.payload['contentType'] as String? ??
        notification.type;

    switch (contentType.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.headphones;
      case 'image':
        return Icons.image;
      case 'quote':
        return Icons.format_quote;
      case 'healthtips':
        return Icons.medical_services;
      case 'tip':
        return Icons.lightbulb;
      default:
        return notification.isRead ? Icons.notifications : Icons
            .notifications_active;
    }
  }

  // Get a color based on notification type/content type
  Color _getNotificationColor(NotificationModel notification, bool isDarkMode) {
    final contentType = notification.payload['contentType'] as String? ??
        notification.type;

    if (notification.isRead) {
      return isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    }

    switch (contentType.toLowerCase()) {
      case 'video':
        return Colors.red[400]!;
      case 'audio':
        return Colors.purple[400]!;
      case 'image':
        return Colors.blue[400]!;
      case 'quote':
        return Colors.amber[400]!;
      case 'healthtips':
        return Colors.green[400]!;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildNotificationList(BuildContext context,
      List<NotificationModel> notifications,
      ThemeData theme,
      bool isDarkMode,) {
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          'No notifications available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDarkMode ? AppColors.darkTextSecondary : AppColors
                .lightTextSecondary,
            fontSize: 16.sp,
          ),
        ),
      );
    }

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
            final deletedNotification = notification;
            final deletedIndex = index;

            await _deleteNotification(
                notification.id, notification.userId, index);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Notification deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    setState(() {
                      // Insert back at the original position if possible
                      if (deletedIndex <= _notifications.length) {
                        _notifications.insert(
                            deletedIndex, deletedNotification);
                      } else {
                        _notifications.add(deletedNotification);
                      }
                      _hasUnreadNotifications = _notifications.any((n) =>
                      !n.isRead);
                    });

                    try {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(deletedNotification.id)
                          .set(deletedNotification.toFirestore());
                      log(
                          'Restored notification to Firestore: ${deletedNotification
                              .id}');
                      await DatabaseHelper.instance.insertNotification(
                          deletedNotification);
                      log(
                          'Restored notification to local database: ${deletedNotification
                              .id}');
                    } catch (e, stackTrace) {
                      log('Error restoring notification ${deletedNotification
                          .id}: $e', stackTrace: stackTrace);
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
                      color: isDarkMode ? Colors.grey.shade600 : Colors.grey
                          .shade300,
                      width: 1.w,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.r),
                    onTap: () => _navigateToContent(notification),
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getNotificationColor(
                                  notification, isDarkMode).withOpacity(0.15),
                            ),
                            child: Icon(
                              _getNotificationIcon(notification),
                              color: _getNotificationColor(
                                  notification, isDarkMode),
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
                                    fontWeight: notification.isRead ? FontWeight
                                        .normal : FontWeight.w600,
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
                                Row(
                                  children: [
                                    Text(
                                      _formatTimestamp(notification.timestamp),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontSize: 12.sp,
                                        color: isDarkMode
                                            ? AppColors.darkTextSecondary
                                            .withOpacity(0.7)
                                            : AppColors.lightTextSecondary
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    // Show content type badge
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: _getNotificationColor(
                                            notification, isDarkMode)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                            8.r),
                                      ),
                                      child: Text(
                                        _getContentTypeLabel(notification),
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: _getNotificationColor(
                                              notification, isDarkMode),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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

  String _getContentTypeLabel(NotificationModel notification) {
    final contentType = notification.payload['contentType'] as String? ??
        notification.type;

    switch (contentType.toLowerCase()) {
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      case 'image':
        return 'Image';
      case 'quote':
        return 'Quote';
      case 'healthtips':
        return 'Health';
      case 'tip':
        return 'Tip';
      default:
        return contentType.capitalize();
    }
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

  // Process stream data outside of build to avoid setState during build
  void _processNotificationSnapshot(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasData && !snapshot.hasError) {
      final newNotifications = snapshot.data!.docs
          .map(
            (doc) =>
            NotificationModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
      )
          .toList();

      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _notifications = newNotifications;
            _isLoading = false;
            _hasUnreadNotifications = _notifications.any((n) => !n.isRead);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final userId = AuthService()
        .getCurrentUser()
        ?.uid;
    log('NotificationScreen userId: $userId');

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
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              CupertinoIcons.back, // iOS style back icon
              color: isDarkMode ? Colors.white : Colors.black,
              size: 24.sp,
            ),
          ),
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
                onPressed: () => userId != null ? _markAllAsRead(userId) : null,
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
              color: isDarkMode ? AppColors.darkTextSecondary : AppColors
                  .lightTextSecondary,
              fontSize: 16.sp,
            ),
          ),
        )
            : _isLoading && _notifications.isEmpty
            ? _buildShimmer(context, isDarkMode)
            : StreamBuilder<QuerySnapshot>(
          stream: _notificationStream,
          builder: (context, snapshot) {
            // Never call setState here - just process the data
            if (snapshot.connectionState == ConnectionState.active) {
              _processNotificationSnapshot(snapshot);
            }

            // Always render using the current state
            return _buildNotificationList(
                context, _notifications, theme, isDarkMode);
          },
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}