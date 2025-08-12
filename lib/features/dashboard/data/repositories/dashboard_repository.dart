import 'dart:developer';
import 'package:lru_cache/lru_cache.dart';
import 'package:wellness_app/core/services/data_repository.dart';
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

class CachedItem<T> {
  final T data;
  final DateTime cachedAt;

  CachedItem(this.data, this.cachedAt);
}

class DashboardRepository {
  final DataRepository _dataRepository;
  late final LruCache<String, CachedItem<DashboardData>> _dashboardCache;
  static const _ttl = Duration(minutes: 30);

  DashboardRepository({DataRepository? dataRepository})
    : _dataRepository = dataRepository ?? DataRepository.instance,
      _dashboardCache = LruCache(50);

  bool _isCacheValid(CachedItem<DashboardData>? cachedItem) {
    return cachedItem != null &&
        DateTime.now().difference(cachedItem.cachedAt) < _ttl;
  }

  Future<void> syncAllData(String userId) async {
    if (userId.isEmpty) {
      log('syncAllData: Invalid userId (empty)', name: 'DashboardRepository');
      return;
    }
    try {
      await _dataRepository.syncAllData(userId);
      log('Data synced for user $userId', name: 'DashboardRepository');
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
      log(
        'getDashboardData: Invalid userId (empty)',
        name: 'DashboardRepository',
      );
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

    final cacheKey = 'dashboard_$userId';
    final cachedData = await _dashboardCache.get(cacheKey);
    if (_isCacheValid(cachedData)) {
      log(
        'Dashboard data fetched from cache for user $userId',
        name: 'DashboardRepository',
      );
      return cachedData!.data;
    }

    try {
      final data = await _dataRepository.getDashboardData(userId);
      final dashboardData = DashboardData(
        user: data['user'] as UserModel?,
        preferences: data['preferences'] as List<PreferenceModel>,
        userPreference: data['userPreference'] as UserPreferenceModel?,
        categories: data['categories'] as List<CategoryModel>,
        tips: data['tips'] as List<TipModel>,
        notifications: data['notifications'] as List<NotificationModel>,
        reminders: data['reminders'] as List<ReminderModel>,
        favorites: data['favorites'] as List<FavoriteModel>,
        subscription: data['subscription'] as SubscriptionModel?,
        transactions: data['transactions'] as List<TransactionModel>,
      );

      _dashboardCache.put(cacheKey, CachedItem(dashboardData, DateTime.now()));
      log(
        'Loaded dashboard data and cached for user $userId: '
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

      return dashboardData;
    } catch (e, stackTrace) {
      log(
        'Error fetching dashboard data for user $userId: $e',
        name: 'DashboardRepository',
        stackTrace: stackTrace,
      );
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

  Future<void> clearCache() async {
    _dashboardCache = LruCache(50);
    log('Dashboard cache cleared', name: 'DashboardRepository');
  }
}
