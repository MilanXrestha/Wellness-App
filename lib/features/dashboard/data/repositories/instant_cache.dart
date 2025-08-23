import 'dart:developer';

/// A lightweight synchronous memory cache for critical UI data
class InstantCache {
  static final InstantCache _instance = InstantCache._internal();
  static InstantCache get instance => _instance;

  InstantCache._internal();

  // Store only the most recent dashboard data for each user
  final Map<String, dynamic> _dashboardCache = {};

  // Track freshness
  final Map<String, DateTime> _lastUpdated = {};

  /// Get dashboard data instantly for a user
  dynamic getDashboardData(String userId) {
    if (_dashboardCache.containsKey(userId)) {
      final age = DateTime.now().difference(_lastUpdated[userId]!);
      log('InstantCache: Found dashboard data for $userId (age: ${age.inSeconds}s)', name: 'InstantCache');
      return _dashboardCache[userId];
    }
    log('InstantCache: No data for $userId', name: 'InstantCache');
    return null;
  }

  /// Store dashboard data for instant access
  void storeDashboardData(String userId, dynamic data) {
    _dashboardCache[userId] = data;
    _lastUpdated[userId] = DateTime.now();
    log('InstantCache: Stored dashboard data for $userId', name: 'InstantCache');
  }

  /// Clear data for a user
  void clear(String userId) {
    _dashboardCache.remove(userId);
    _lastUpdated.remove(userId);
    log('InstantCache: Cleared data for $userId', name: 'InstantCache');
  }

  /// Check if we have fresh data (less than 30 minutes old)
  bool hasFreshData(String userId) {
    if (!_dashboardCache.containsKey(userId)) return false;

    final lastUpdate = _lastUpdated[userId];
    if (lastUpdate == null) return false;

    final age = DateTime.now().difference(lastUpdate);
    return age.inMinutes < 30;
  }
}