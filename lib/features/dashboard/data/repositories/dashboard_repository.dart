import 'dart:developer';
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

class DashboardRepository {
  final DataRepository _dataRepository;
  final WellnessCacheService _cacheService;

  DashboardRepository({
    DataRepository? dataRepository,
    WellnessCacheService? cacheService,
  })  : _dataRepository = dataRepository ?? DataRepository.instance,
        _cacheService = cacheService ?? WellnessCacheService();

  String _sanitizeText(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .replaceAll('\u2019', "'") // Right single quotation mark
        .replaceAll('\u2018', "'") // Left single quotation mark
        .replaceAll('&apos;', "'") // HTML entity
        .replaceAll('&#39;', "'"); // HTML entity numeric
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is String) {
        sanitized[key] = _sanitizeText(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeMap(value);
      } else if (value is List<dynamic>) {
        sanitized[key] = value.map((e) {
          if (e is String) return _sanitizeText(e);
          if (e is Map<String, dynamic>) return _sanitizeMap(e);
          return e;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  Future<bool> hasValidCache(String userId) async {
    if (userId.isEmpty) {
      log('hasValidCache: Invalid userId (empty)', name: 'DashboardRepository');
      return false;
    }
    try {
      final cacheData = await _cacheService.getCacheData(
        endpoint: 'dashboard',
        param: userId,
        hasInternet: await _dataRepository.isOnline(),
      );
      final hasCache = !cacheData.hasCacheExpired && cacheData.data.isNotEmpty;
      log('hasValidCache for user $userId: $hasCache', name: 'DashboardRepository');
      return hasCache;
    } catch (e, stackTrace) {
      log(
        'Error checking cache for user $userId: $e',
        name: 'DashboardRepository',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<DashboardData?> getCachedDashboardData(String userId) async {
    if (userId.isEmpty) {
      log('getCachedDashboardData: Invalid userId (empty)', name: 'DashboardRepository');
      return null;
    }

    try {
      final cacheData = await _cacheService.getCacheData(
        endpoint: 'dashboard',
        param: userId,
        hasInternet: false, // Force offline check to get cache immediately
      );

      if (!cacheData.hasCacheExpired && cacheData.data.isNotEmpty) {
        log('Found cached dashboard data for user $userId', name: 'DashboardRepository');
        return _deserializeDashboardData(_sanitizeMap(cacheData.data));
      }

      return null;
    } catch (e, stackTrace) {
      log(
        'Error getting cached dashboard data for user $userId: $e',
        name: 'DashboardRepository',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> syncAllData(String userId) async {
    if (userId.isEmpty) {
      log('syncAllData: Invalid userId (empty)', name: 'DashboardRepository');
      return;
    }
    try {
      await _dataRepository.syncAllData(userId);
      await _cacheService.saveDataToCache(
        endpoint: 'dashboard',
        param: userId,
        data: {},
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: true,
      );
      log('Data synced and cache refreshed for user $userId', name: 'DashboardRepository');
    } catch (e, stackTrace) {
      log(
        'Error syncing data for user $userId: $e',
        name: 'DashboardRepository',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<DashboardData> getDashboardData(String userId) async {
    if (userId.isEmpty) {
      log('getDashboardData: Invalid userId (empty)', name: 'DashboardRepository');
      return _emptyDashboardData();
    }

    try {
      final isOnline = await _dataRepository.isOnline();
      final cacheData = await _cacheService.getCacheData(
        endpoint: 'dashboard',
        param: userId,
        hasInternet: isOnline,
      );

      if (!cacheData.hasCacheExpired && cacheData.data.isNotEmpty) {
        log('Cache hit for dashboard data, user $userId', name: 'DashboardRepository');
        final dashboardData = _deserializeDashboardData(_sanitizeMap(cacheData.data));
        log(
          'Loaded dashboard data from cache for user $userId: '
              'user=${dashboardData.user?.userId ?? "null"}, '
              'tips=${dashboardData.tips.length}, '
              'categories=${dashboardData.categories.length}, '
              'preferences=${dashboardData.preferences.length}, '
              'reminders=${dashboardData.reminders.length}, '
              'notifications=${dashboardData.notifications.length}, '
              'favorites=${dashboardData.favorites.length}, '
              'subscription=${dashboardData.subscription?.userId ?? "null"}, '
              'transactions=${dashboardData.transactions.length}',
          name: 'DashboardRepository',
        );

        if (isOnline) {
          syncAllData(userId).catchError((e, stackTrace) {
            log('Background sync failed for user $userId: $e', name: 'DashboardRepository', stackTrace: stackTrace);
          });
        }

        log('Cache stats: ${_cacheService.getCacheStats()}', name: 'DashboardRepository');
        return dashboardData;
      }

      log('Cache miss for dashboard data, user $userId', name: 'DashboardRepository');
      final rawData = _sanitizeMap(await _dataRepository.getDashboardData(userId));
      final dashboardData = DashboardData(
        user: rawData['user'] != null ? UserModel.fromJson(rawData['user'] as Map<String, dynamic>) : null,
        preferences: (rawData['preferences'] as List<dynamic>?)
            ?.map((e) => PreferenceModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        userPreference: rawData['userPreference'] != null
            ? UserPreferenceModel.fromJson(rawData['userPreference'] as Map<String, dynamic>)
            : null,
        categories: (rawData['categories'] as List<dynamic>?)
            ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        tips: (rawData['tips'] as List<dynamic>?)
            ?.map((e) => TipModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        notifications: (rawData['notifications'] as List<dynamic>?)
            ?.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        reminders: (rawData['reminders'] as List<dynamic>?)
            ?.map((e) => ReminderModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        favorites: (rawData['favorites'] as List<dynamic>?)
            ?.map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
        subscription: rawData['subscription'] != null
            ? SubscriptionModel.fromJson(rawData['subscription'] as Map<String, dynamic>)
            : null,
        transactions: (rawData['transactions'] as List<dynamic>?)
            ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
      );

      final cacheableData = {
        'user': dashboardData.user?.toJson(),
        'preferences': dashboardData.preferences.map((e) => e.toJson()).toList(),
        'userPreference': dashboardData.userPreference?.toJson(),
        'categories': dashboardData.categories.map((e) => e.toJson()).toList(),
        'tips': dashboardData.tips.map((e) => e.toJson()).toList(),
        'notifications': dashboardData.notifications.map((e) => e.toJson()).toList(),
        'reminders': dashboardData.reminders.map((e) => e.toJson()).toList(),
        'favorites': dashboardData.favorites.map((e) => e.toJson()).toList(),
        'subscription': dashboardData.subscription?.toJson(),
        'transactions': dashboardData.transactions.map((e) => e.toJson()).toList(),
      };

      await _cacheService.saveDataToCache(
        endpoint: 'dashboard',
        param: userId,
        data: _sanitizeMap(cacheableData),
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );

      log(
        'Loaded and cached dashboard data for user $userId: '
            'user=${dashboardData.user?.userId ?? "null"}, '
            'tips=${dashboardData.tips.length}, '
            'categories=${dashboardData.categories.length}, '
            'preferences=${dashboardData.preferences.length}, '
            'reminders=${dashboardData.reminders.length}, '
            'notifications=${dashboardData.notifications.length}, '
            'favorites=${dashboardData.favorites.length}, '
            'subscription=${dashboardData.subscription?.userId ?? "null"}, '
            'transactions=${dashboardData.transactions.length}',
        name: 'DashboardRepository',
      );

      log('Cache stats: ${_cacheService.getCacheStats()}', name: 'DashboardRepository');
      return dashboardData;
    } catch (e, stackTrace) {
      log(
        'Error fetching dashboard data for user $userId: $e',
        name: 'DashboardRepository',
        stackTrace: stackTrace,
      );
      return _emptyDashboardData();
    }
  }

  Future<void> clearDashboardCache(String userId) async {
    if (userId.isEmpty) {
      log('clearDashboardCache: Invalid userId (empty)', name: 'DashboardRepository');
      return;
    }
    try {
      await _cacheService.clearCache();
      log('Dashboard cache cleared for user $userId', name: 'DashboardRepository');
    } catch (e, stackTrace) {
      log(
        'Error clearing dashboard cache for user $userId: $e',
        name: 'DashboardRepository',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

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