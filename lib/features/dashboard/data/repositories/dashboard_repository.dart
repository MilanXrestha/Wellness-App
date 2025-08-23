import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import 'package:wellness_app/core/services/wellness_cache_service.dart';
import 'package:wellness_app/features/dashboard/data/models/dashboard_data.dart';
import 'package:wellness_app/features/profile/data/user_model.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/features/preferences/data/models/user_preference_model.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/notifications/data/models/notification_model.dart';
import 'package:wellness_app/features/reminders/data/models/reminder_model.dart';
import 'package:wellness_app/features/favorites/data/models/favorite_model.dart';
import 'package:wellness_app/features/subscription/data/models/subscription_model.dart';
import 'package:wellness_app/features/subscription/data/models/transaction_model.dart';

import 'instant_cache.dart';

class DashboardRepository {
  // Private constructor with direct initialization
  DashboardRepository._internal() {
    _dataRepository = DataRepository.instance;
    _cacheService = WellnessCacheService();
    log('DashboardRepository initialized', name: 'DashboardRepository');
  }

  // Static instance with proper initialization
  static final DashboardRepository _instance = DashboardRepository._internal();

  // Public accessor for the singleton
  static DashboardRepository get instance => _instance;

  // Factory constructor for testing or custom instances
  factory DashboardRepository({
    DataRepository? dataRepository,
    WellnessCacheService? cacheService,
  }) {
    // Only modify the instance if parameters are provided
    if (dataRepository != null) {
      _instance._dataRepository = dataRepository;
    }
    if (cacheService != null) {
      _instance._cacheService = cacheService;
    }
    return _instance;
  }

  // Dependencies - initialized in constructor
  late DataRepository _dataRepository;
  late WellnessCacheService _cacheService;
  final InstantCache _instantCache = InstantCache.instance;

  /// Get dashboard data instantly from memory if available
  DashboardData? getLastDashboardDataSync(String userId) {
    if (userId.isEmpty) return null;

    try {
      // Try to get data from the instant cache
      final cachedData = _instantCache.getDashboardData(userId);
      if (cachedData != null) {
        log('Retrieved dashboard data from instant cache for user $userId', name: 'DashboardRepository');
        return _deserializeDashboardData(cachedData);
      }
      return null;
    } catch (e) {
      log('Error retrieving dashboard data from instant cache: $e', name: 'DashboardRepository');
      return null;
    }
  }

  /// Check if we have valid cache for this user (any source)
  Future<bool> hasValidCache(String userId) async {
    if (userId.isEmpty) {
      log('hasValidCache: Invalid userId (empty)', name: 'DashboardRepository');
      return false;
    }

    // First check instant cache (fastest)
    if (_instantCache.hasFreshData(userId)) {
      log('Found valid instant cache for user $userId', name: 'DashboardRepository');
      return true;
    }

    try {
      // Then check WellnessCacheService
      final cacheData = await _cacheService.getCacheData(
        endpoint: 'dashboard',
        param: userId,
        hasInternet: false, // Force offline check
      );
      final hasCache = !cacheData.hasCacheExpired && cacheData.data.isNotEmpty;
      log('hasValidCache for user $userId: $hasCache', name: 'DashboardRepository');
      return hasCache;
    } catch (e) {
      log('Error checking cache for user $userId: $e', name: 'DashboardRepository');
      return false;
    }
  }

  /// Get dashboard data from cache (any source)
  Future<DashboardData?> getCachedDashboardData(String userId) async {
    if (userId.isEmpty) {
      log('getCachedDashboardData: Invalid userId (empty)', name: 'DashboardRepository');
      return null;
    }

    // First try instant cache
    final instantData = getLastDashboardDataSync(userId);
    if (instantData != null) {
      return instantData;
    }

    try {
      // Then try WellnessCacheService
      final cacheData = await _cacheService.getCacheData(
        endpoint: 'dashboard',
        param: userId,
        hasInternet: false, // Force offline check
      );

      if (!cacheData.hasCacheExpired && cacheData.data.isNotEmpty) {
        log('Found cached dashboard data for user $userId', name: 'DashboardRepository');
        final dashboardData = _deserializeDashboardData(cacheData.data);

        // Update instant cache for next time
        _instantCache.storeDashboardData(userId, cacheData.data);

        return dashboardData;
      }

      return null;
    } catch (e) {
      log('Error getting cached dashboard data for user $userId: $e', name: 'DashboardRepository');
      return null;
    }
  }

  /// Check if device is offline
  Future<bool> isOffline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult == ConnectivityResult.none;
      log('Network status: ${isOffline ? 'Offline' : 'Online'}', name: 'DashboardRepository');
      return isOffline;
    } catch (e) {
      log('Error checking connectivity: $e', name: 'DashboardRepository');
      // Default to online if we can't check
      return false;
    }
  }

  /// Sync all data for this user
  Future<void> syncAllData(String userId) async {
    if (userId.isEmpty) {
      log('syncAllData: Invalid userId (empty)', name: 'DashboardRepository');
      return;
    }

    // Skip if offline
    if (await isOffline()) {
      log('Device is offline, skipping sync for user $userId', name: 'DashboardRepository');
      return;
    }

    try {
      await _dataRepository.syncAllData(userId);

      // Clear SQLite cache to force refresh
      await _cacheService.saveDataToCache(
        endpoint: 'dashboard',
        param: userId,
        data: {},
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: true,
      );

      // Clear instant cache too
      _instantCache.clear(userId);

      log('Data synced and cache cleared for user $userId', name: 'DashboardRepository');
    } catch (e) {
      log('Error syncing data for user $userId: $e', name: 'DashboardRepository');
      rethrow;
    }
  }

  /// Get dashboard data - optimized for both online and offline modes
  Future<DashboardData> getDashboardData(String userId) async {
    if (userId.isEmpty) {
      log('getDashboardData: Invalid userId (empty)', name: 'DashboardRepository');
      return _emptyDashboardData();
    }

    try {
      // First check if device is offline
      final offline = await isOffline();

      // Try WellnessCacheService
      final cacheData = await _cacheService.getCacheData(
        endpoint: 'dashboard',
        param: userId,
        hasInternet: !offline,
      );

      if (!cacheData.hasCacheExpired && cacheData.data.isNotEmpty) {
        log('Cache hit for dashboard data, user $userId', name: 'DashboardRepository');
        final dashboardData = _deserializeDashboardData(cacheData.data);

        // Store in instant cache for fastest access next time
        _instantCache.storeDashboardData(userId, cacheData.data);

        // If we're online, trigger a background refresh
        if (!offline) {
          _refreshInBackground(userId);
        }

        return dashboardData;
      }

      // If we're offline and no cache, return empty data
      if (offline) {
        log('Device is offline and no cache available for user $userId', name: 'DashboardRepository');
        return _emptyDashboardData();
      }

      // Fetch fresh data from network
      log('Cache miss for dashboard data, user $userId', name: 'DashboardRepository');
      final rawData = await _dataRepository.getDashboardData(userId);
      final dashboardData = _deserializeDashboardData(rawData);

      // Update both caches
      _instantCache.storeDashboardData(userId, rawData);

      await _cacheService.saveDataToCache(
        endpoint: 'dashboard',
        param: userId,
        data: rawData,
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );

      log('Loaded and cached dashboard data for user $userId', name: 'DashboardRepository');
      return dashboardData;
    } catch (e) {
      log('Error fetching dashboard data for user $userId: $e', name: 'DashboardRepository');

      // Try to return cached data even if there was an error
      final cachedData = await getCachedDashboardData(userId);
      if (cachedData != null) {
        log('Returning cached data after error for user $userId', name: 'DashboardRepository');
        return cachedData;
      }

      return _emptyDashboardData();
    }
  }

  /// Trigger a background refresh without blocking the UI
  Future<void> _refreshInBackground(String userId) async {
    // Use async without await to run in background
    Future(() async {
      try {
        log('Starting background refresh for user $userId', name: 'DashboardRepository');
        final rawData = await _dataRepository.getDashboardData(userId);

        // Update instant cache with fresh data
        _instantCache.storeDashboardData(userId, rawData);

        // Update SQLite cache
        await _cacheService.saveDataToCache(
          endpoint: 'dashboard',
          param: userId,
          data: rawData,
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: true,
        );

        log('Background refresh completed for user $userId', name: 'DashboardRepository');
      } catch (e) {
        log('Error in background refresh for user $userId: $e', name: 'DashboardRepository');
      }
    });
  }

  /// Clear all dashboard caches
  Future<void> clearDashboardCache(String userId) async {
    if (userId.isEmpty) {
      log('clearDashboardCache: Invalid userId (empty)', name: 'DashboardRepository');
      return;
    }
    try {
      // Clear instant cache first
      _instantCache.clear(userId);

      // Clear WellnessCacheService
      await _cacheService.clearCache();
      log('Dashboard cache cleared for user $userId', name: 'DashboardRepository');
    } catch (e) {
      log('Error clearing dashboard cache for user $userId: $e', name: 'DashboardRepository');
      rethrow;
    }
  }

  /// Convert raw data to DashboardData model
  DashboardData _deserializeDashboardData(Map<String, dynamic> data) {
    return DashboardData(
      user: data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null,
      preferences: (data['preferences'] as List<dynamic>?)
          ?.map((e) => PreferenceModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      userPreference: data['userPreference'] != null
          ? UserPreferenceModel.fromJson(data['userPreference'] as Map<String, dynamic>)
          : null,
      categories: (data['categories'] as List<dynamic>?)
          ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      tips: (data['tips'] as List<dynamic>?)
          ?.map((e) => TipModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      notifications: (data['notifications'] as List<dynamic>?)
          ?.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      reminders: (data['reminders'] as List<dynamic>?)
          ?.map((e) => ReminderModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      favorites: (data['favorites'] as List<dynamic>?)
          ?.map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      subscription: data['subscription'] != null
          ? SubscriptionModel.fromJson(data['subscription'] as Map<String, dynamic>)
          : null,
      transactions: (data['transactions'] as List<dynamic>?)
          ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  /// Create an empty dashboard data object
  DashboardData _emptyDashboardData() {
    return DashboardData(
      user: null,
      preferences: [],
      userPreference: null,
      categories: [],
      tips: [],
      notifications: [],
      reminders: [],
      favorites: [],
      subscription: null,
      transactions: [],
    );
  }
}