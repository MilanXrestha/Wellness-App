import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'dart:developer';

class NotificationCountProvider with ChangeNotifier {
  int _unreadCount = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  int get unreadCount => _unreadCount;

  Future<void> fetchUnreadNotificationCount() async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      _unreadCount = querySnapshot.docs.length;
      log('Unread notification count: $_unreadCount');
      notifyListeners();
    } catch (e) {
      log('Error fetching unread notification count: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final userId = _authService.getCurrentUser()?.uid;
    if (userId == null) return;

    try {
      // Update Firestore
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Update local count
      _unreadCount = 0;
      notifyListeners();
      log('All notifications marked as read');
    } catch (e) {
      log('Error marking notifications as read: $e');
    }
  }

  void decrementUnreadCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }
}
