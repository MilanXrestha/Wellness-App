import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:wellness_app/features/videoPlayer/data/models/comments_model.dart';

import '../../../../core/db/database_helper.dart';
import '../../../videoPlayer/data/models/likes_model.dart';
import 'instant_cache.dart';

class DashboardRepository {
  // Private constructor with direct initialization
  DashboardRepository._internal() {
    _dataRepository = DataRepository.instance;
    _cacheService = WellnessCacheService();
    _databaseHelper = DatabaseHelper.instance;
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
    DatabaseHelper? databaseHelper,
  }) {
    if (dataRepository != null) {
      _instance._dataRepository = dataRepository;
    }
    if (cacheService != null) {
      _instance._cacheService = cacheService;
    }
    if (databaseHelper != null) {
      _instance._databaseHelper = databaseHelper;
    }
    return _instance;
  }

  // Dependencies - initialized in constructor
  late DataRepository _dataRepository;
  late WellnessCacheService _cacheService;
  late DatabaseHelper _databaseHelper;
  final InstantCache _instantCache = InstantCache.instance;

  /// Get cached shorts (TipModel list) for a specific category
  Future<List<TipModel>> getCachedShorts(
    String userId, {
    String? categoryId,
  }) async {
    if (userId.isEmpty) {
      log(
        'getCachedShorts: Invalid userId (empty)',
        name: 'DashboardRepository',
      );
      return [];
    }

    try {
      // First try instant cache
      final cachedData = _instantCache.getDashboardData(userId);
      if (cachedData != null) {
        final dashboardData = _deserializeDashboardData(cachedData);
        final tips = categoryId != null
            ? dashboardData.tips
                  .where((tip) => tip.categoryId == categoryId)
                  .toList()
            : dashboardData.tips;
        log(
          'Retrieved ${tips.length} cached shorts from instant cache for user $userId, category $categoryId',
          name: 'DashboardRepository',
        );
        return tips;
      }

      // Then try SQLite via DatabaseHelper
      final tips = categoryId != null
          ? await _databaseHelper.getTipsByCategory(categoryId)
          : await _databaseHelper.getAllTips();
      log(
        'Retrieved ${tips.length} cached shorts from SQLite for user $userId, category $categoryId',
        name: 'DashboardRepository',
      );

      // Store in instant cache for faster access next time
      if (tips.isNotEmpty) {
        final dashboardData =
            await getCachedDashboardData(userId) ?? _emptyDashboardData();
        final updatedData = DashboardData(
          user: dashboardData.user,
          preferences: dashboardData.preferences,
          userPreference: dashboardData.userPreference,
          categories: dashboardData.categories,
          tips: tips,
          notifications: dashboardData.notifications,
          reminders: dashboardData.reminders,
          favorites: dashboardData.favorites,
          subscription: dashboardData.subscription,
          transactions: dashboardData.transactions,
        );
        _instantCache.storeDashboardData(
          userId,
          _serializeDashboardData(updatedData),
        );
      }

      return tips;
    } catch (e) {
      log(
        'Error getting cached shorts for user $userId, category $categoryId: $e',
        name: 'DashboardRepository',
      );
      return [];
    }
  }

  /// Sync queued interactions (likes and comments) when online
  Future<void> syncQueuedInteractions(String userId) async {
    if (userId.isEmpty) {
      log(
        'syncQueuedInteractions: Invalid userId (empty)',
        name: 'DashboardRepository',
      );
      return;
    }

    if (await isOffline()) {
      log(
        'Device is offline, skipping sync of queued interactions for user $userId',
        name: 'DashboardRepository',
      );
      return;
    }

    try {
      final db = await _databaseHelper.database;

      // Sync queued comments
      final queuedComments = await _databaseHelper.getQueuedComments();
      for (var comment in queuedComments) {
        final commentModel = CommentModel.fromMap(comment);
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('comments')
            .doc(commentModel.id)
            .set(commentModel.toFirestore());
        await FirebaseFirestore.instance
            .collection('tips')
            .doc(commentModel.tipsId)
            .update({'commentCount': FieldValue.increment(1)});

        // Update local cache
        await _databaseHelper.insertComment(commentModel);
        await _databaseHelper.deleteQueuedComment(commentModel.id);
        log(
          'Synced comment ${commentModel.id} for tip ${commentModel.tipsId}',
          name: 'DashboardRepository',
        );
      }

      // Sync queued interactions (likes)
      final queuedInteractions = await _databaseHelper.getQueuedInteractions();
      for (var interaction in queuedInteractions) {
        final tipsId = interaction['tipsId'] as String;
        final type = interaction['type'] as String;
        final id = interaction['id'] as int;

        if (type == 'like') {
          final likeModel = LikeModel(
            id: '${userId}_$tipsId',
            tipsId: tipsId,
            userId: userId,
            createdAt: DateTime.parse(interaction['timestamp'] as String),
          );
          await FirebaseFirestore.instance
              .collection('likes')
              .doc(likeModel.id)
              .set(likeModel.toFirestore());
          await FirebaseFirestore.instance
              .collection('tips')
              .doc(tipsId)
              .update({'likeCount': FieldValue.increment(1)});
          // Update local tip cache
          final tip = await _databaseHelper.getTip(tipsId);
          if (tip != null) {
            await _databaseHelper.insertTip(
              tip.copyWith(likeCount: tip.likeCount + 1),
            );
          }
          await _databaseHelper.deleteQueuedInteraction(id);
          log('Synced like for tip $tipsId', name: 'DashboardRepository');
        }
      }

      log(
        'Completed syncing queued interactions for user $userId',
        name: 'DashboardRepository',
      );
    } catch (e) {
      log(
        'Error syncing queued interactions for user $userId: $e',
        name: 'DashboardRepository',
      );
      rethrow;
    }
  }

  /// Get dashboard data instantly from memory if available
  DashboardData? getLastDashboardDataSync(String userId) {
    if (userId.isEmpty) return null;

    try {
      final cachedData = _instantCache.getDashboardData(userId);
      if (cachedData != null) {
        log(
          'Retrieved dashboard data from instant cache for user $userId',
          name: 'DashboardRepository',
        );
        return _deserializeDashboardData(cachedData);
      }
      return null;
    } catch (e) {
      log(
        'Error retrieving dashboard data from instant cache: $e',
        name: 'DashboardRepository',
      );
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
      log(
        'Found valid instant cache for user $userId',
        name: 'DashboardRepository',
      );
      return true;
    }

    try {
      // Then check WellnessCacheService
      final cacheData = await _cacheService.getCacheData(
        endpoint: 'dashboard',
        param: userId,
        hasInternet: false,
      );
      final hasCache = !cacheData.hasCacheExpired && cacheData.data.isNotEmpty;
      log(
        'hasValidCache for user $userId: $hasCache',
        name: 'DashboardRepository',
      );
      return hasCache;
    } catch (e) {
      log(
        'Error checking cache for user $userId: $e',
        name: 'DashboardRepository',
      );
      return false;
    }
  }

  /// Get dashboard data from cache (any source)
  Future<DashboardData?> getCachedDashboardData(String userId) async {
    if (userId.isEmpty) {
      log(
        'getCachedDashboardData: Invalid userId (empty)',
        name: 'DashboardRepository',
      );
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
        hasInternet: false,
      );

      if (!cacheData.hasCacheExpired && cacheData.data.isNotEmpty) {
        log(
          'Found cached dashboard data for user $userId',
          name: 'DashboardRepository',
        );
        final dashboardData = _deserializeDashboardData(cacheData.data);

        // Update instant cache for next time
        _instantCache.storeDashboardData(userId, cacheData.data);

        return dashboardData;
      }

      return null;
    } catch (e) {
      log(
        'Error getting cached dashboard data for user $userId: $e',
        name: 'DashboardRepository',
      );
      return null;
    }
  }

  /// Check if device is offline
  Future<bool> isOffline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult == ConnectivityResult.none;
      log(
        'Network status: ${isOffline ? 'Offline' : 'Online'}',
        name: 'DashboardRepository',
      );
      return isOffline;
    } catch (e) {
      log('Error checking connectivity: $e', name: 'DashboardRepository');
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
      log(
        'Device is offline, skipping sync for user $userId',
        name: 'DashboardRepository',
      );
      return;
    }

    try {
      await _dataRepository.syncAllData(userId);

      // Sync queued interactions
      await syncQueuedInteractions(userId);

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

      log(
        'Data synced and cache cleared for user $userId',
        name: 'DashboardRepository',
      );
    } catch (e) {
      log(
        'Error syncing data for user $userId: $e',
        name: 'DashboardRepository',
      );
      rethrow;
    }
  }

  /// Get dashboard data - optimized for both online and offline modes
  Future<DashboardData> getDashboardData(String userId) async {
    if (userId.isEmpty) {
      log(
        'getDashboardData: Invalid userId (empty)',
        name: 'DashboardRepository',
      );
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
        log(
          'Cache hit for dashboard data, user $userId',
          name: 'DashboardRepository',
        );
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
        log(
          'Device is offline and no cache available for user $userId',
          name: 'DashboardRepository',
        );
        return _emptyDashboardData();
      }

      // Fetch fresh data from network
      log(
        'Cache miss for dashboard data, user $userId',
        name: 'DashboardRepository',
      );
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

      // Cache individual tips in SQLite
      for (var tip in dashboardData.tips) {
        await _databaseHelper.insertTip(tip);
      }

      log(
        'Loaded and cached dashboard data for user $userId',
        name: 'DashboardRepository',
      );
      return dashboardData;
    } catch (e) {
      log(
        'Error fetching dashboard data for user $userId: $e',
        name: 'DashboardRepository',
      );

      // Try to return cached data even if there was an error
      final cachedData = await getCachedDashboardData(userId);
      if (cachedData != null) {
        log(
          'Returning cached data after error for user $userId',
          name: 'DashboardRepository',
        );
        return cachedData;
      }

      return _emptyDashboardData();
    }
  }

  /// Trigger a background refresh without blocking the UI
  Future<void> _refreshInBackground(String userId) async {
    Future(() async {
      try {
        log(
          'Starting background refresh for user $userId',
          name: 'DashboardRepository',
        );
        final rawData = await _dataRepository.getDashboardData(userId);
        final dashboardData = _deserializeDashboardData(rawData);

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

        // Cache individual tips in SQLite
        for (var tip in dashboardData.tips) {
          await _databaseHelper.insertTip(tip);
        }

        log(
          'Background refresh completed for user $userId',
          name: 'DashboardRepository',
        );
      } catch (e) {
        log(
          'Error in background refresh for user $userId: $e',
          name: 'DashboardRepository',
        );
      }
    });
  }

  /// Clear all dashboard caches
  Future<void> clearDashboardCache(String userId) async {
    if (userId.isEmpty) {
      log(
        'clearDashboardCache: Invalid userId (empty)',
        name: 'DashboardRepository',
      );
      return;
    }
    try {
      // Clear instant cache first
      _instantCache.clear(userId);

      // Clear WellnessCacheService
      await _cacheService.clearCache();
      await _databaseHelper.clearCacheTable();
      log(
        'Dashboard cache cleared for user $userId',
        name: 'DashboardRepository',
      );
    } catch (e) {
      log(
        'Error clearing dashboard cache for user $userId: $e',
        name: 'DashboardRepository',
      );
      rethrow;
    }
  }

  /// Convert raw data to DashboardData model
  DashboardData _deserializeDashboardData(Map<String, dynamic> data) {
    return DashboardData(
      user: data['user'] != null
          ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
          : null,
      preferences:
          (data['preferences'] as List<dynamic>?)
              ?.map((e) => PreferenceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      userPreference: data['userPreference'] != null
          ? UserPreferenceModel.fromJson(
              data['userPreference'] as Map<String, dynamic>,
            )
          : null,
      categories:
          (data['categories'] as List<dynamic>?)
              ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tips:
          (data['tips'] as List<dynamic>?)
              ?.map((e) => TipModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notifications:
          (data['notifications'] as List<dynamic>?)
              ?.map(
                (e) => NotificationModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      reminders:
          (data['reminders'] as List<dynamic>?)
              ?.map((e) => ReminderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      favorites:
          (data['favorites'] as List<dynamic>?)
              ?.map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subscription: data['subscription'] != null
          ? SubscriptionModel.fromJson(
              data['subscription'] as Map<String, dynamic>,
            )
          : null,
      transactions:
          (data['transactions'] as List<dynamic>?)
              ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Serialize DashboardData to raw data
  Map<String, dynamic> _serializeDashboardData(DashboardData data) {
    return {
      'user': data.user?.toJson(),
      'preferences': data.preferences.map((e) => e.toJson()).toList(),
      'userPreference': data.userPreference?.toJson(),
      'categories': data.categories.map((e) => e.toJson()).toList(),
      'tips': data.tips.map((e) => e.toJson()).toList(),
      'notifications': data.notifications.map((e) => e.toJson()).toList(),
      'reminders': data.reminders.map((e) => e.toJson()).toList(),
      'favorites': data.favorites.map((e) => e.toJson()).toList(),
      'subscription': data.subscription?.toJson(),
      'transactions': data.transactions.map((e) => e.toJson()).toList(),
    };
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
