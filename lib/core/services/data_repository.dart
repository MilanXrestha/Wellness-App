import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer';
import 'package:lru_cache/lru_cache.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/favorites/data/models/favorite_model.dart';
import 'package:wellness_app/features/notifications/data/models/notification_model.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/features/preferences/data/models/user_preference_model.dart';
import 'package:wellness_app/features/profile/data/user_model.dart';
import 'package:wellness_app/features/reminders/data/models/reminder_model.dart';
import 'package:wellness_app/features/subscription/data/models/subscription_model.dart';
import 'package:wellness_app/features/subscription/data/models/transaction_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/core/constants/app_constants.dart';
import 'package:wellness_app/core/db/database_helper.dart';

class CachedItem<T> {
  final T data;
  final DateTime cachedAt;
  CachedItem(this.data, this.cachedAt);
}

class DataRepository {
  static final DataRepository instance = DataRepository._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // LRU caches for different model types
  LruCache<String, CachedItem<UserModel>> _userCache = LruCache(50);
  LruCache<String, CachedItem<List<PreferenceModel>>> _preferencesCache = LruCache(10);
  LruCache<String, CachedItem<PreferenceModel>> _preferenceCache = LruCache(50);
  LruCache<String, CachedItem<UserPreferenceModel>> _userPreferenceCache = LruCache(50);
  LruCache<String, CachedItem<List<CategoryModel>>> _categoriesCache = LruCache(20);
  LruCache<String, CachedItem<CategoryModel>> _categoryCache = LruCache(100);
  LruCache<String, CachedItem<List<TipModel>>> _tipsCache = LruCache(50);
  LruCache<String, CachedItem<TipModel>> _tipCache = LruCache(200);
  LruCache<String, CachedItem<List<FavoriteModel>>> _favoritesCache = LruCache(50);
  LruCache<String, CachedItem<List<ReminderModel>>> _remindersCache = LruCache(50);
  LruCache<String, CachedItem<ReminderModel>> _reminderCache = LruCache(100);
  LruCache<String, CachedItem<List<NotificationModel>>> _notificationsCache = LruCache(50);
  LruCache<String, CachedItem<SubscriptionModel>> _subscriptionCache = LruCache(50);
  LruCache<String, CachedItem<List<TransactionModel>>> _transactionsCache = LruCache(50);
  LruCache<String, CachedItem<Map<String, dynamic>>> _dashboardCache = LruCache(50);


  // TTL for dynamic data (e.g., notifications, reminders)
  static const _ttl = Duration(minutes: 30);

  DataRepository._internal();

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;
    log('Network status: ${isOnline ? 'Online' : 'Offline'}');
    return isOnline;
  }

  bool _isCacheValid(CachedItem<dynamic>? cachedItem) {
    return cachedItem != null && DateTime.now().difference(cachedItem.cachedAt) < _ttl;
  }

  Future<UserModel?> getUser(String userId) async {
    if (userId.isEmpty) {
      log('getUser: Invalid userId (empty)');
      return null;
    }
    final cacheKey = 'user_$userId';
    final cachedUser = await _userCache.get(cacheKey); // await here
    if (_isCacheValid(cachedUser)) {
      log('User fetched from cache: $userId');
      return cachedUser!.data; // safe to use '!' if _isCacheValid checks for null
    }
    if (await _isOnline()) {
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .get();
        if (doc.exists) {
          final user = UserModel.fromFirestore(doc.data()!, userId);
          await _dbHelper.insertUser(user);
          _userCache.put(cacheKey, CachedItem(user, DateTime.now()));
          log('User fetched from Firestore and cached: ${user.userId}');
          return user;
        } else {
          log('User $userId not found in Firestore');
        }
      } catch (e) {
        log('Error fetching user from Firestore: $e');
      }
    }
    final user = await _dbHelper.getUser(userId);
    if (user != null) {
      _userCache.put(cacheKey, CachedItem(user, DateTime.now()));
      log('User fetched from local database and cached: ${user.userId}');
    } else {
      log('User $userId not found in local database');
    }
    return user;
  }

  Future<void> updateUser(UserModel user) async {
    if (user.userId.isEmpty) {
      log('updateUser: Invalid userId (empty)');
      return;
    }
    final cacheKey = 'user_${user.userId}';
    await _dbHelper.insertUser(user);
    _userCache.put(cacheKey, CachedItem(user, DateTime.now()));
    _dashboardCache.remove('dashboard_${user.userId}');
    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.userId)
            .set(user.toFirestore());
        log('User updated in Firestore: ${user.userId}');
      } catch (e) {
        log('Error updating user in Firestore: $e');
      }
    }
  }

  Future<void> deleteUser(String userId) async {
    if (userId.isEmpty) {
      log('deleteUser: Invalid userId (empty)');
      return;
    }
    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .delete();
        log('User deleted from Firestore: $userId');
      } catch (e) {
        log('Error deleting user from Firestore: $e');
      }
    }
    await _dbHelper.deleteUser(userId);
    _userCache.remove('user_$userId');
    _dashboardCache.remove('dashboard_$userId');
  }

  Future<List<PreferenceModel>> getPreferences() async {
    const cacheKey = 'all_preferences';
    final cachedPreferences = await _preferencesCache.get(cacheKey);
    if (_isCacheValid(cachedPreferences)) {
      log('Preferences fetched from cache');
      return cachedPreferences!.data;
    }
    if (await _isOnline()) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.preferencesCollection)
            .get();
        final preferences = snapshot.docs
            .map((doc) => PreferenceModel.fromFirestore(doc.data(), doc.id))
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var preference in preferences) {
          batch.insert(
            'preferences',
            {'preferenceId': preference.preferenceId, 'data': preference.toProto()},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          _preferenceCache.put('preference_${preference.preferenceId}', CachedItem(preference, DateTime.now()));
        }
        await batch.commit();
        _preferencesCache.put(cacheKey, CachedItem(preferences, DateTime.now()));
        log('Fetched ${preferences.length} preferences from Firestore and cached');
        return preferences;
      } catch (e) {
        log('Error fetching preferences from Firestore: $e');
      }
    }
    final preferences = await _dbHelper.getAllPreferences();
    for (var preference in preferences) {
      _preferenceCache.put('preference_${preference.preferenceId}', CachedItem(preference, DateTime.now()));
    }
    _preferencesCache.put(cacheKey, CachedItem(preferences, DateTime.now()));
    log('Fetched ${preferences.length} preferences from local database and cached');
    return preferences;
  }

  Future<PreferenceModel?> getPreference(String preferenceId) async {
    if (preferenceId.isEmpty) {
      log('getPreference: Invalid preferenceId (empty)');
      return null;
    }
    final cacheKey = 'preference_$preferenceId';
    final cachedPreference = await _preferenceCache.get(cacheKey);
    if (_isCacheValid(cachedPreference)) {
      log('Preference fetched from cache: $preferenceId');
      return cachedPreference!.data;
    }
    if (await _isOnline()) {
      try {
        final doc = await _firestore
            .collection(AppConstants.preferencesCollection)
            .doc(preferenceId)
            .get();
        if (doc.exists) {
          final preference = PreferenceModel.fromFirestore(doc.data()!, preferenceId);
          await _dbHelper.insertPreference(preference);
          _preferenceCache.put(cacheKey, CachedItem(preference, DateTime.now()));
          log('Preference fetched from Firestore and cached: $preferenceId');
          return preference;
        }
      } catch (e) {
        log('Error fetching preference from Firestore: $e');
      }
    }
    final preference = await _dbHelper.getPreference(preferenceId);
    if (preference != null) {
      _preferenceCache.put(cacheKey, CachedItem(preference, DateTime.now()));
      log('Preference fetched from local database and cached: $preferenceId');
    }
    return preference;
  }

  Future<UserPreferenceModel?> getUserPreference(String userId) async {
    if (userId.isEmpty) {
      log('getUserPreference: Invalid userId (empty)');
      return null;
    }
    final cacheKey = 'user_preference_$userId';
    final cachedUserPreference = await _userPreferenceCache.get(cacheKey);
    if (_isCacheValid(cachedUserPreference)) {
      log('User preference fetched from cache: $userId');
      return cachedUserPreference!.data;
    }
    await getPreferences();
    if (await _isOnline()) {
      try {
        final doc = await _firestore
            .collection(AppConstants.userPreferencesCollection)
            .doc(userId)
            .get();
        if (doc.exists) {
          final userPreference = UserPreferenceModel.fromFirestore(doc.data()!, userId);
          await _dbHelper.insertUserPreference(userPreference);
          _userPreferenceCache.put(cacheKey, CachedItem(userPreference, DateTime.now()));
          log('User preference fetched from Firestore and cached: $userId');
          return userPreference;
        }
      } catch (e) {
        log('Error fetching user preference from Firestore: $e');
      }
    }
    final userPreference = await _dbHelper.getUserPreference(userId);
    if (userPreference != null) {
      _userPreferenceCache.put(cacheKey, CachedItem(userPreference, DateTime.now()));
      log('User preference fetched from local database and cached: $userId');
    }
    return userPreference;
  }

  Future<void> updateUserPreference(UserPreferenceModel userPreference) async {
    if (userPreference.userId.isEmpty) {
      log('updateUserPreference: Invalid userId (empty)');
      return;
    }
    final cacheKey = 'user_preference_${userPreference.userId}';
    await _dbHelper.insertUserPreference(userPreference);
    _userPreferenceCache.put(cacheKey, CachedItem(userPreference, DateTime.now()));
    _dashboardCache.remove('dashboard_${userPreference.userId}');
    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.userPreferencesCollection)
            .doc(userPreference.userId)
            .set(userPreference.toFirestore());
        log('User preference updated in Firestore: ${userPreference.userId}');
      } catch (e) {
        log('Error updating user preference in Firestore: $e');
      }
    }
  }

  Future<void> deleteUserPreference(String userId) async {
    if (userId.isEmpty) {
      log('deleteUserPreference: Invalid userId (empty)');
      return;
    }
    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.userPreferencesCollection)
            .doc(userId)
            .delete();
        log('User preference deleted from Firestore: $userId');
      } catch (e) {
        log('Error deleting user preference from Firestore: $e');
      }
    }
    await _dbHelper.deleteUserPreference(userId);
    _userPreferenceCache.remove('user_preference_$userId');
    _dashboardCache.remove('dashboard_$userId');
  }

  Future<List<CategoryModel>> getCategories() async {
    const cacheKey = 'all_categories';
    final cachedCategories = await _categoriesCache.get(cacheKey);
    if (_isCacheValid(cachedCategories)) {
      log('Categories fetched from cache');
      return cachedCategories!.data;
    }
    if (await _isOnline()) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.categoriesCollection)
            .get();
        final categories = snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var category in categories) {
          batch.insert(
            'categories',
            {'categoryId': category.categoryId, 'data': category.toProto()},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          _categoryCache.put('category_${category.categoryId}', CachedItem(category, DateTime.now()));
        }
        await batch.commit();
        _categoriesCache.put(cacheKey, CachedItem(categories, DateTime.now()));
        log('Fetched ${categories.length} categories from Firestore and cached');
        return categories;
      } catch (e) {
        log('Error fetching categories from Firestore: $e');
      }
    }
    final categories = await _dbHelper.getAllCategories();
    for (var category in categories) {
      _categoryCache.put('category_${category.categoryId}', CachedItem(category, DateTime.now()));
    }
    _categoriesCache.put(cacheKey, CachedItem(categories, DateTime.now()));
    log('Fetched ${categories.length} categories from local database and cached');
    return categories;
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    if (categoryId.isEmpty) {
      log('getCategory: Invalid categoryId (empty)');
      return null;
    }
    final cacheKey = 'category_$categoryId';
    final cachedCategory = await _categoryCache.get(cacheKey);
    if (_isCacheValid(cachedCategory)) {
      log('Category fetched from cache: $categoryId');
      return cachedCategory!.data;
    }
    if (await _isOnline()) {
      try {
        final doc = await _firestore
            .collection(AppConstants.categoriesCollection)
            .doc(categoryId)
            .get();
        if (doc.exists) {
          final category = CategoryModel.fromFirestore(doc.data()!, categoryId);
          await _dbHelper.insertCategory(category);
          _categoryCache.put(cacheKey, CachedItem(category, DateTime.now()));
          _categoriesCache.remove('all_categories');
          log('Category fetched from Firestore and cached: $categoryId');
          return category;
        } else {
          log('Category $categoryId not found in Firestore');
        }
      } catch (e) {
        log('Error fetching category from Firestore: $e');
      }
    }
    final category = await _dbHelper.getCategory(categoryId);
    if (category != null) {
      _categoryCache.put(cacheKey, CachedItem(category, DateTime.now()));
      _categoriesCache.remove('all_categories');
      log('Category fetched from local database and cached: $categoryId');
    }
    return category;
  }

  Future<List<TipModel>> getTips({bool includePremium = false}) async {
    final cacheKey = includePremium ? 'all_tips_premium' : 'all_tips';
    final cachedTips = await _tipsCache.get(cacheKey);
    if (_isCacheValid(cachedTips)) {
      log('Tips fetched from cache: $cacheKey');
      return cachedTips!.data;
    }
    if (await _isOnline()) {
      try {
        final categories = await getCategories();
        final categoryIds = categories.map((c) => c.categoryId).toSet();
        final snapshot = await _firestore
            .collection(AppConstants.tipsCollection)
            .get();
        final tips = <TipModel>[];
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var doc in snapshot.docs) {
          final tip = TipModel.fromFirestore(doc.data(), doc.id);
          if ((includePremium || !tip.isPremium) && categoryIds.contains(tip.categoryId)) {
            batch.insert(
              'tips',
              {'tipsId': tip.tipsId, 'categoryId': tip.categoryId, 'data': tip.toProto()},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            _tipCache.put('tip_${tip.tipsId}', CachedItem(tip, DateTime.now()));
            tips.add(tip);
          }
        }
        await batch.commit();
        _tipsCache.put(cacheKey, CachedItem(tips, DateTime.now()));
        log('Fetched ${tips.length} tips from Firestore and cached');
        return tips;
      } catch (e) {
        log('Error fetching tips from Firestore: $e');
      }
    }
    final tips = await _dbHelper.getAllTips();
    final filteredTips = tips.where((tip) => includePremium || !tip.isPremium).toList();
    for (var tip in filteredTips) {
      _tipCache.put('tip_${tip.tipsId}', CachedItem(tip, DateTime.now()));
    }
    _tipsCache.put(cacheKey, CachedItem(filteredTips, DateTime.now()));
    log('Fetched ${filteredTips.length} tips from local database and cached');
    return filteredTips;
  }

  Future<List<TipModel>> getTipsByCategory(String categoryId, {bool includePremium = false}) async {
    if (categoryId.isEmpty) {
      log('getTipsByCategory: Invalid categoryId (empty)');
      return [];
    }
    final cacheKey = 'tips_by_category_${categoryId}_premium_$includePremium';
    final cachedTips = await _tipsCache.get(cacheKey);
    if (_isCacheValid(cachedTips)) {
      log('Tips fetched from cache: $cacheKey');
      return cachedTips!.data;
    }
    if (await _isOnline()) {
      try {
        final category = await getCategory(categoryId);
        if (category == null) {
          log('Category $categoryId not found');
          return [];
        }
        final snapshot = await _firestore
            .collection(AppConstants.tipsCollection)
            .where('categoryId', isEqualTo: categoryId)
            .get();
        final tips = <TipModel>[];
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var doc in snapshot.docs) {
          final tip = TipModel.fromFirestore(doc.data(), doc.id);
          if (includePremium || !tip.isPremium) {
            batch.insert(
              'tips',
              {'tipsId': tip.tipsId, 'categoryId': tip.categoryId, 'data': tip.toProto()},
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            _tipCache.put('tip_${tip.tipsId}', CachedItem(tip, DateTime.now()));
            tips.add(tip);
          }
        }
        await batch.commit();
        _tipsCache.put(cacheKey, CachedItem(tips, DateTime.now()));
        log('Fetched ${tips.length} tips for category $categoryId from Firestore and cached');
        return tips;
      } catch (e) {
        log('Error fetching tips by category from Firestore: $e');
      }
    }
    final tips = await _dbHelper.getTipsByCategory(categoryId);
    final filteredTips = tips.where((tip) => includePremium || !tip.isPremium).toList();
    for (var tip in filteredTips) {
      _tipCache.put('tip_${tip.tipsId}', CachedItem(tip, DateTime.now()));
    }
    _tipsCache.put(cacheKey, CachedItem(filteredTips, DateTime.now()));
    log('Fetched ${filteredTips.length} tips for category $categoryId from local database and cached');
    return filteredTips;
  }

  Future<TipModel?> getTip(String tipsId) async {
    if (tipsId.isEmpty) {
      log('getTip: Invalid tipsId (empty)');
      return null;
    }
    final cacheKey = 'tip_$tipsId';
    final cachedTip = await _tipCache.get(cacheKey);
    if (_isCacheValid(cachedTip)) {
      log('Tip fetched from cache: $tipsId');
      return cachedTip!.data;
    }
    if (await _isOnline()) {
      try {
        final doc = await _firestore
            .collection(AppConstants.tipsCollection)
            .doc(tipsId)
            .get();
        if (doc.exists) {
          final tip = TipModel.fromFirestore(doc.data()!, tipsId);
          if (await _dbHelper.getCategory(tip.categoryId) != null) {
            await _dbHelper.insertTip(tip);
            _tipCache.put(cacheKey, CachedItem(tip, DateTime.now()));
            _tipsCache.remove('all_tips');
            _tipsCache.remove('all_tips_premium');
            log('Tip fetched from Firestore and cached: $tipsId');
            return tip;
          } else {
            log('Category ${tip.categoryId} not found for tip $tipsId');
          }
        }
      } catch (e) {
        log('Error fetching tip from Firestore: $e');
      }
    }
    final tip = await _dbHelper.getTip(tipsId);
    if (tip != null) {
      _tipCache.put(cacheKey, CachedItem(tip, DateTime.now()));
      log('Tip fetched from local database and cached: $tipsId');
    }
    return tip;
  }

  Future<List<FavoriteModel>> getFavoritesByUser(String userId) async {
    return getFavorites(userId);
  }

  Future<List<FavoriteModel>> getFavorites(String userId) async {
    if (userId.isEmpty) {
      log('getFavorites: Invalid userId (empty)');
      return [];
    }
    final cacheKey = 'favorites_$userId';
    final cachedFavorites = await _favoritesCache.get(cacheKey);
    if (_isCacheValid(cachedFavorites)) {
      log('Favorites fetched from cache for userId: $userId');
      return cachedFavorites!.data;
    }
    final localFavorites = await _dbHelper.getFavoritesByUser(userId);
    _favoritesCache.put(cacheKey, CachedItem(localFavorites, DateTime.now()));
    log('Fetched ${localFavorites.length} favorites from local database and cached for userId: $userId');

    if (await _isOnline()) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.favoriteCollection)
            .where('userId', isEqualTo: userId)
            .get();
        final firestoreFavorites = snapshot.docs
            .map((doc) => FavoriteModel.fromFirestore(doc.data(), doc.id))
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var favorite in firestoreFavorites) {
          if (favorite.userId.isEmpty) {
            log('Skipping invalid favorite ${favorite.id} with empty userId');
            continue;
          }
          batch.insert(
            'favorites',
            {'id': favorite.id, 'userId': favorite.userId, 'data': favorite.toProto()},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit();
        _favoritesCache.put(cacheKey, CachedItem(firestoreFavorites, DateTime.now()));
        _dashboardCache.remove('dashboard_$userId');
        log('Synced ${firestoreFavorites.length} favorites from Firestore and cached for userId: $userId');
        return firestoreFavorites;
      } catch (e) {
        log('Error fetching favorites from Firestore for userId: $userId, error: $e');
      }
    }
    return localFavorites;
  }

  Future<FavoriteModel> addFavorite(FavoriteModel favorite) async {
    if (favorite.userId.isEmpty) {
      log('addFavorite: Invalid userId (empty)');
      throw Exception('Cannot add favorite with empty userId');
    }
    await _dbHelper.insertFavorite(favorite);
    final cacheKey = 'favorites_${favorite.userId}';
    _favoritesCache.remove(cacheKey);
    _dashboardCache.remove('dashboard_${favorite.userId}');
    log('Favorite added to local database: ${favorite.id}');

    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.favoriteCollection)
            .doc(favorite.id)
            .set(favorite.toFirestore());
        log('Favorite added to Firestore: ${favorite.id}');
      } catch (e) {
        log('Error adding favorite to Firestore: $e');
        await _dbHelper.insertPendingFavorite(favorite);
        log('Favorite stored in pending_operations: ${favorite.id}');
      }
    } else {
      await _dbHelper.insertPendingFavorite(favorite);
      log('Offline: Favorite stored in pending_operations: ${favorite.id}');
    }
    return favorite;
  }

  Future<void> deleteFavorite(String id) async {
    if (id.isEmpty) {
      log('deleteFavorite: Invalid favorite id (empty)');
      return;
    }
    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.favoriteCollection)
            .doc(id)
            .delete();
        log('Favorite deleted from Firestore: $id');
      } catch (e) {
        log('Error deleting favorite from Firestore: $e');
      }
    }
    final favorite = await _dbHelper.getFavorite(id);
    await _dbHelper.deleteFavorite(id);
    await _dbHelper.deletePendingFavorite(id);
    if (favorite != null) {
      _favoritesCache.remove('favorites_${favorite.userId}');
      _dashboardCache.remove('dashboard_${favorite.userId}');
    }
  }

  Future<List<ReminderModel>> getRemindersByUser(String userId) async {
    return getReminders(userId);
  }

  Future<List<ReminderModel>> getReminders(String userId) async {
    if (userId.isEmpty) {
      log('getReminders: Invalid userId (empty)');
      return [];
    }
    final cacheKey = 'reminders_$userId';
    final cachedReminders = await _remindersCache.get(cacheKey);
    if (_isCacheValid(cachedReminders)) {
      log('Reminders fetched from cache for userId: $userId');
      return cachedReminders!.data;
    }
    if (await _isOnline()) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.remindersCollection)
            .where('userId', isEqualTo: userId)
            .get();
        final reminders = snapshot.docs
            .map((doc) => ReminderModel.fromFirestore(doc.data(), doc.id))
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var reminder in reminders) {
          batch.insert(
            'reminders',
            {'id': reminder.id, 'userId': reminder.userId, 'data': reminder.toProto()},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit();
        _remindersCache.put(cacheKey, CachedItem(reminders, DateTime.now()));
        _dashboardCache.remove('dashboard_$userId');
        log('Fetched ${reminders.length} reminders from Firestore and cached for userId: $userId');
        return reminders;
      } catch (e) {
        log('Error fetching reminders from Firestore: $e');
      }
    }
    final reminders = await _dbHelper.getRemindersByUser(userId);
    _remindersCache.put(cacheKey, CachedItem(reminders, DateTime.now()));
    log('Fetched ${reminders.length} reminders from local database and cached for userId: $userId');
    return reminders;
  }

  Future<ReminderModel?> getReminderById(String reminderId) async {
    if (reminderId.isEmpty) {
      log('getReminderById: Invalid reminderId (empty)');
      return null;
    }
    final cacheKey = 'reminder_$reminderId';
    final cachedReminder = await _reminderCache.get(cacheKey);
    if (_isCacheValid(cachedReminder)) {
      log('Reminder fetched from cache: $reminderId');
      return cachedReminder!.data;
    }
    if (await _isOnline()) {
      try {
        final doc = await _firestore.collection(AppConstants.remindersCollection).doc(reminderId).get();
        if (doc.exists) {
          final reminder = ReminderModel.fromFirestore(doc.data()!, doc.id);
          await _dbHelper.insertReminder(reminder);
          _reminderCache.put(cacheKey, CachedItem(reminder, DateTime.now()));
          _remindersCache.remove('reminders_${reminder.userId}');
          _dashboardCache.remove('dashboard_${reminder.userId}');
          log('Reminder fetched from Firestore and cached: $reminderId');
          return reminder;
        }
      } catch (e) {
        log('Error fetching reminder $reminderId: $e');
      }
    }
    final reminder = await _dbHelper.getReminder(reminderId);
    if (reminder != null) {
      _reminderCache.put(cacheKey, CachedItem(reminder, DateTime.now()));
      log('Reminder fetched from local database and cached: $reminderId');
    }
    return reminder;
  }

  Future<void> addReminder(ReminderModel reminder) async {
    if (reminder.userId.isEmpty) {
      log('addReminder: Invalid userId (empty)');
      throw Exception('Cannot add reminder with empty userId');
    }
    await _dbHelper.insertReminder(reminder);
    _remindersCache.remove('reminders_${reminder.userId}');
    _reminderCache.put('reminder_${reminder.id}', CachedItem(reminder, DateTime.now()));
    _dashboardCache.remove('dashboard_${reminder.userId}');
    log('Reminder added to local database: ${reminder.id}');

    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.remindersCollection)
            .doc(reminder.id)
            .set(reminder.toFirestore());
        log('Reminder added to Firestore: ${reminder.id}');
      } catch (e) {
        log('Error adding reminder to Firestore: $e');
        await _dbHelper.insertPendingReminder(reminder);
        log('Reminder stored in pending_operations: ${reminder.id}');
      }
    } else {
      await _dbHelper.insertPendingReminder(reminder);
      log('Offline: Reminder stored in pending_operations: ${reminder.id}');
    }
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    if (reminder.userId.isEmpty) {
      log('updateReminder: Invalid userId (empty)');
      throw Exception('Cannot update reminder with empty userId');
    }
    await _dbHelper.insertReminder(reminder);
    _remindersCache.remove('reminders_${reminder.userId}');
    _reminderCache.put('reminder_${reminder.id}', CachedItem(reminder, DateTime.now()));
    _dashboardCache.remove('dashboard_${reminder.userId}');
    log('Reminder updated in local database: ${reminder.id}');

    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.remindersCollection)
            .doc(reminder.id)
            .set(reminder.toFirestore());
        log('Reminder updated in Firestore: ${reminder.id}');
      } catch (e) {
        log('Error updating reminder to Firestore: $e');
        await _dbHelper.insertPendingReminder(reminder);
        log('Reminder stored in pending_operations: ${reminder.id}');
      }
    } else {
      await _dbHelper.insertPendingReminder(reminder);
      log('Offline: Reminder stored in pending_operations: ${reminder.id}');
    }
  }

  Future<void> deleteReminder(String id) async {
    if (id.isEmpty) {
      log('deleteReminder: Invalid reminder id (empty)');
      return;
    }
    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.remindersCollection)
            .doc(id)
            .delete();
        log('Reminder deleted from Firestore: $id');
      } catch (e) {
        log('Error deleting reminder from Firestore: $e');
      }
    }
    final reminder = await _dbHelper.getReminder(id);
    await _dbHelper.deleteReminder(id);
    await _dbHelper.deletePendingReminder(id);
    if (reminder != null) {
      _remindersCache.remove('reminders_${reminder.userId}');
      _reminderCache.remove('reminder_$id');
      _dashboardCache.remove('dashboard_${reminder.userId}');
    }
  }

  Future<List<NotificationModel>> getNotifications(String userId, {int limit = 50}) async {
    if (userId.isEmpty) {
      log('getNotifications: Invalid userId (empty)');
      return [];
    }
    final cacheKey = 'notifications_$userId';
    final cachedNotifications = await _notificationsCache.get(cacheKey);
    if (_isCacheValid(cachedNotifications)) {
      log('Notifications fetched from cache for userId: $userId');
      return cachedNotifications!.data.take(limit).toList();
    }
    if (await _isOnline()) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();
        final notifications = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc.data(), doc.id))
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var notification in notifications) {
          batch.insert(
            'notifications',
            {'id': notification.id, 'userId': notification.userId, 'data': notification.toProto()},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit();
        _notificationsCache.put(cacheKey, CachedItem(notifications, DateTime.now()));
        _dashboardCache.remove('dashboard_$userId');
        log('Fetched ${notifications.length} notifications from Firestore and cached for userId: $userId');
        return notifications;
      } catch (e) {
        log('Error fetching notifications from Firestore: $e');
      }
    }
    final notifications = await _dbHelper.getNotificationsByUser(userId);
    _notificationsCache.put(cacheKey, CachedItem(notifications, DateTime.now()));
    log('Fetched ${notifications.length} notifications from SQLite and cached for userId: $userId');
    return notifications.take(limit).toList();
  }

  Future<void> markNotificationAsRead(String id) async {
    if (id.isEmpty) {
      log('markNotificationAsRead: Invalid notification id (empty)');
      return;
    }
    final notification = await _dbHelper.getNotification(id);
    if (notification == null) {
      log('Notification $id not found in local database');
      return;
    }
    final updated = NotificationModel(
      id: notification.id,
      userId: notification.userId,
      title: notification.title,
      body: notification.body,
      type: notification.type,
      isRead: true,
      payload: notification.payload,
      timestamp: notification.timestamp,
    );
    await _dbHelper.insertNotification(updated);
    _notificationsCache.remove('notifications_${notification.userId}');
    _dashboardCache.remove('dashboard_${notification.userId}');
    log('Notification marked as read in local database: $id');

    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.notificationsCollection)
            .doc(id)
            .set(updated.toFirestore());
        log('Notification updated in Firestore: $id');
      } catch (e) {
        log('Error updating notification in Firestore: $e');
        await _dbHelper.insertPendingNotification(updated);
        log('Notification stored in pending_operations: $id');
      }
    } else {
      await _dbHelper.insertPendingNotification(updated);
      log('Offline: Notification stored in pending_operations: $id');
    }
  }

  Future<void> deleteNotification(String id) async {
    if (id.isEmpty) {
      log('deleteNotification: Invalid notification id (empty)');
      return;
    }
    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.notificationsCollection)
            .doc(id)
            .delete();
        log('Notification deleted from Firestore: $id');
      } catch (e) {
        log('Error deleting notification from Firestore: $e');
      }
    }
    final notification = await _dbHelper.getNotification(id);
    await _dbHelper.deleteNotification(id);
    await _dbHelper.deletePendingNotification(id);
    if (notification != null) {
      _notificationsCache.remove('notifications_${notification.userId}');
      _dashboardCache.remove('dashboard_${notification.userId}');
    }
  }

  Future<SubscriptionModel?> getSubscription(String userId) async {
    if (userId.isEmpty) {
      log('getSubscription: Invalid userId (empty)');
      return null;
    }
    final cacheKey = 'subscription_$userId';
    final cachedSubscription = await _subscriptionCache.get(cacheKey);
    if (_isCacheValid(cachedSubscription)) {
      log('Subscription fetched from cache: $userId');
      return cachedSubscription!.data;
    }
    if (await _isOnline()) {
      try {
        final doc = await _firestore
            .collection(AppConstants.subscriptionsCollection)
            .doc(userId)
            .get();
        if (doc.exists) {
          final subscription = SubscriptionModel.fromFirestore(doc.data()!, userId);
          await _dbHelper.insertSubscription(subscription);
          _subscriptionCache.put(cacheKey, CachedItem(subscription, DateTime.now()));
          _dashboardCache.remove('dashboard_$userId');
          log('Subscription fetched from Firestore and cached: $userId');
          return subscription;
        }
      } catch (e) {
        log('Error fetching subscription from Firestore: $e');
      }
    }
    final subscription = await _dbHelper.getSubscription(userId);
    if (subscription != null) {
      _subscriptionCache.put(cacheKey, CachedItem(subscription, DateTime.now()));
      log('Subscription fetched from local database and cached: $userId');
    }
    return subscription;
  }

  Future<void> updateSubscription(SubscriptionModel subscription) async {
    if (subscription.userId.isEmpty) {
      log('updateSubscription: Invalid userId (empty)');
      return;
    }
    await _dbHelper.insertSubscription(subscription);
    final cacheKey = 'subscription_${subscription.userId}';
    _subscriptionCache.put(cacheKey, CachedItem(subscription, DateTime.now()));
    _dashboardCache.remove('dashboard_${subscription.userId}');
    log('Subscription updated in local database: ${subscription.userId}');

    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.subscriptionsCollection)
            .doc(subscription.userId)
            .set(subscription.toFirestore());
        log('Subscription updated in Firestore: ${subscription.userId}');
      } catch (e) {
        log('Error updating subscription to Firestore: $e');
        await _dbHelper.insertPendingSubscription(subscription);
        log('Subscription stored in pending_operations: ${subscription.userId}');
      }
    } else {
      await _dbHelper.insertPendingSubscription(subscription);
      log('Offline: Subscription stored in pending_operations: ${subscription.userId}');
    }
  }

  Future<void> deleteSubscription(String userId) async {
    if (userId.isEmpty) {
      log('deleteSubscription: Invalid userId (empty)');
      return;
    }
    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.subscriptionsCollection)
            .doc(userId)
            .delete();
        log('Subscription deleted from Firestore: $userId');
      } catch (e) {
        log('Error deleting subscription from Firestore: $e');
      }
    }
    await _dbHelper.deleteSubscription(userId);
    await _dbHelper.deletePendingSubscription(userId);
    _subscriptionCache.remove('subscription_$userId');
    _dashboardCache.remove('dashboard_$userId');
  }

  Future<List<TransactionModel>> getTransactions(String userId) async {
    if (userId.isEmpty) {
      log('getTransactions: Invalid userId (empty)');
      return [];
    }
    final cacheKey = 'transactions_$userId';
    final cachedTransactions = await _transactionsCache.get(cacheKey);
    if (_isCacheValid(cachedTransactions)) {
      log('Transactions fetched from cache for userId: $userId');
      return cachedTransactions!.data;
    }
    if (await _isOnline()) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.transactionsCollection)
            .where('userId', isEqualTo: userId)
            .get();
        final transactions = snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var transaction in transactions) {
          batch.insert(
            'transactions',
            {'id': transaction.id, 'userId': transaction.userId, 'data': transaction.toProto()},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit();
        _transactionsCache.put(cacheKey, CachedItem(transactions, DateTime.now()));
        _dashboardCache.remove('dashboard_$userId');
        log('Fetched ${transactions.length} transactions from Firestore and cached for userId: $userId');
        return transactions;
      } catch (e) {
        log('Error fetching transactions from Firestore: $e');
      }
    }
    final transactions = await _dbHelper.getTransactionsByUser(userId);
    _transactionsCache.put(cacheKey, CachedItem(transactions, DateTime.now()));
    log('Fetched ${transactions.length} transactions from local database and cached for userId: $userId');
    return transactions;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    if (transaction.userId.isEmpty) {
      log('addTransaction: Invalid userId (empty)');
      throw Exception('Cannot add transaction with empty userId');
    }
    await _dbHelper.insertTransaction(transaction);
    _transactionsCache.remove('transactions_${transaction.userId}');
    _dashboardCache.remove('dashboard_${transaction.userId}');
    log('Transaction added to local database: ${transaction.id}');

    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.transactionsCollection)
            .doc(transaction.id)
            .set(transaction.toFirestore());
        log('Transaction added to Firestore: ${transaction.id}');
      } catch (e) {
        log('Error adding transaction to Firestore: $e');
        await _dbHelper.insertPendingTransaction(transaction);
        log('Transaction stored in pending_operations: ${transaction.id}');
      }
    } else {
      await _dbHelper.insertPendingTransaction(transaction);
      log('Offline: Transaction stored in pending_operations: ${transaction.id}');
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (id.isEmpty) {
      log('deleteTransaction: Invalid transaction id (empty)');
      return;
    }
    if (await _isOnline()) {
      try {
        await _firestore
            .collection(AppConstants.transactionsCollection)
            .doc(id)
            .delete();
        log('Transaction deleted from Firestore: $id');
      } catch (e) {
        log('Error deleting transaction from Firestore: $e');
      }
    }
    final transaction = await _dbHelper.getTransaction(id);
    await _dbHelper.deleteTransaction(id);
    await _dbHelper.deletePendingTransaction(id);
    if (transaction != null) {
      _transactionsCache.remove('transactions_${transaction.userId}');
      _dashboardCache.remove('dashboard_${transaction.userId}');
    }
  }

  Future<bool> canAccessPremiumContent(String userId) async {
    if (userId.isEmpty) {
      log('canAccessPremiumContent: Invalid userId (empty)');
      return false;
    }
    final cacheKey = 'subscription_$userId';
    final cachedSubscription = await _subscriptionCache.get(cacheKey);
    SubscriptionModel? subscription;
    if (_isCacheValid(cachedSubscription)) {
      subscription = cachedSubscription!.data;
    } else {
      subscription = await getSubscription(userId);
    }
    if (subscription != null) {
      final canAccess = subscription.status == 'active' &&
          subscription.endDate != null &&
          subscription.endDate!.isAfter(DateTime.now());
      log('Premium access for user $userId: $canAccess');
      return canAccess;
    }
    log('No subscription found for user $userId, premium access denied');
    return false;
  }

  Future<void> syncAllData(String userId) async {
    if (userId.isEmpty) {
      log('syncAllData: Invalid userId (empty)');
      return;
    }
    if (await _isOnline()) {
      try {
        await Future.wait([
          getUser(userId),
          getPreferences(),
          getUserPreference(userId),
          getCategories(),
          getTips(includePremium: true),
          getFavorites(userId),
          getReminders(userId),
          getNotifications(userId),
          getSubscription(userId),
          getTransactions(userId),
          syncPendingOperations(),
        ]);
        log('Data synced and cached for user $userId');
      } catch (e) {
        log('Error syncing data for user $userId: $e');
        await Future.delayed(Duration(seconds: 1));
        try {
          await Future.wait([
            getUser(userId),
            getPreferences(),
            getUserPreference(userId),
            getCategories(),
            getTips(includePremium: true),
            getFavorites(userId),
            getReminders(userId),
            getNotifications(userId),
            getSubscription(userId),
            getTransactions(userId),
            syncPendingOperations(),
          ]);
          log('Data sync retry successful for user $userId');
        } catch (retryError) {
          log('Data sync retry failed for user $userId: $retryError');
          rethrow;
        }
      }
    } else {
      log('Offline: Skipping Firestore sync, using cached data for user $userId');
    }
  }

  Future<void> syncPendingOperations() async {
    if (await _isOnline()) {
      final priorities = ['transaction', 'subscription', 'reminder', 'favorite', 'notification'];
      for (var type in priorities) {
        switch (type) {
          case 'transaction':
            final pendingTransactions = await _dbHelper.getPendingTransactions();
            log('Found ${pendingTransactions.length} pending transactions to sync');
            for (var transaction in pendingTransactions) {
              if (transaction.userId.isEmpty) {
                log('Skipping sync of pending transaction ${transaction.id} with empty userId');
                await _dbHelper.deletePendingTransaction(transaction.id);
                continue;
              }
              try {
                await _firestore
                    .collection(AppConstants.transactionsCollection)
                    .doc(transaction.id)
                    .set(transaction.toFirestore());
                await _dbHelper.deletePendingTransaction(transaction.id);
                _transactionsCache.remove('transactions_${transaction.userId}');
                _dashboardCache.remove('dashboard_${transaction.userId}');
                log('Synced pending transaction to Firestore: ${transaction.id}');
              } catch (e) {
                log('Error syncing pending transaction ${transaction.id}: $e');
              }
            }
            break;
          case 'subscription':
            final pendingSubscriptions = await _dbHelper.getPendingSubscriptions();
            log('Found ${pendingSubscriptions.length} pending subscriptions to sync');
            for (var subscription in pendingSubscriptions) {
              if (subscription.userId.isEmpty) {
                log('Skipping sync of pending subscription ${subscription.userId} with empty userId');
                await _dbHelper.deletePendingSubscription(subscription.userId);
                continue;
              }
              try {
                await _firestore
                    .collection(AppConstants.subscriptionsCollection)
                    .doc(subscription.userId)
                    .set(subscription.toFirestore());
                await _dbHelper.deletePendingSubscription(subscription.userId);
                _subscriptionCache.remove('subscription_${subscription.userId}');
                _dashboardCache.remove('dashboard_${subscription.userId}');
                log('Synced pending subscription to Firestore: ${subscription.userId}');
              } catch (e) {
                log('Error syncing pending subscription ${subscription.userId}: $e');
              }
            }
            break;
          case 'reminder':
            final pendingReminders = await _dbHelper.getPendingReminders();
            log('Found ${pendingReminders.length} pending reminders to sync');
            for (var reminder in pendingReminders) {
              if (reminder.userId.isEmpty) {
                log('Skipping sync of pending reminder ${reminder.id} with empty userId');
                await _dbHelper.deletePendingReminder(reminder.id);
                continue;
              }
              try {
                await _firestore
                    .collection(AppConstants.remindersCollection)
                    .doc(reminder.id)
                    .set(reminder.toFirestore());
                await _dbHelper.deletePendingReminder(reminder.id);
                _remindersCache.remove('reminders_${reminder.userId}');
                _reminderCache.remove('reminder_${reminder.id}');
                _dashboardCache.remove('dashboard_${reminder.userId}');
                log('Synced pending reminder to Firestore: ${reminder.id}');
              } catch (e) {
                log('Error syncing pending reminder ${reminder.id}: $e');
              }
            }
            break;
          case 'favorite':
            final pendingFavorites = await _dbHelper.getPendingFavorites();
            log('Found ${pendingFavorites.length} pending favorites to sync');
            for (var favorite in pendingFavorites) {
              if (favorite.userId.isEmpty) {
                log('Skipping sync of pending favorite ${favorite.id} with empty userId');
                await _dbHelper.deletePendingFavorite(favorite.id);
                continue;
              }
              try {
                await _firestore
                    .collection(AppConstants.favoriteCollection)
                    .doc(favorite.id)
                    .set(favorite.toFirestore());
                await _dbHelper.deletePendingFavorite(favorite.id);
                _favoritesCache.remove('favorites_${favorite.userId}');
                _dashboardCache.remove('dashboard_${favorite.userId}');
                log('Synced pending favorite to Firestore: ${favorite.id}');
              } catch (e) {
                log('Error syncing pending favorite ${favorite.id}: $e');
              }
            }
            break;
          case 'notification':
            final pendingNotifications = await _dbHelper.getPendingNotifications();
            log('Found ${pendingNotifications.length} pending notifications to sync');
            for (var notification in pendingNotifications) {
              if (notification.userId.isEmpty) {
                log('Skipping sync of pending notification ${notification.id} with empty userId');
                await _dbHelper.deletePendingNotification(notification.id);
                continue;
              }
              try {
                await _firestore
                    .collection(AppConstants.notificationsCollection)
                    .doc(notification.id)
                    .set(notification.toFirestore());
                await _dbHelper.deletePendingNotification(notification.id);
                _notificationsCache.remove('notifications_${notification.userId}');
                _dashboardCache.remove('dashboard_${notification.userId}');
                log('Synced pending notification to Firestore: ${notification.id}');
              } catch (e) {
                log('Error syncing pending notification ${notification.id}: $e');
              }
            }
            break;
        }
      }
    } else {
      log('Offline: Skipping pending operations sync');
    }
  }

  Future<void> clearLocalCache() async {
    await _dbHelper.clearDatabase();
    _userCache = LruCache(50);
    _preferencesCache = LruCache(10);
    _preferenceCache = LruCache(50);
    _userPreferenceCache = LruCache(50);
    _categoriesCache = LruCache(20);
    _categoryCache = LruCache(100);
    _tipsCache = LruCache(50);
    _tipCache = LruCache(200);
    _favoritesCache = LruCache(50);
    _remindersCache = LruCache(50);
    _reminderCache = LruCache(100);
    _notificationsCache = LruCache(50);
    _subscriptionCache = LruCache(50);
    _transactionsCache = LruCache(50);
    _dashboardCache = LruCache(50);
    log('Local cache cleared');
  }

  Future<Map<String, dynamic>> getDashboardData(String userId) async {
    if (userId.isEmpty) {
      log('getDashboardData: Invalid userId (empty)');
      return {
        'user': null,
        'preferences': <PreferenceModel>[],
        'userPreference': null,
        'categories': <CategoryModel>[],
        'tips': <TipModel>[],
        'notifications': <NotificationModel>[],
        'reminders': <ReminderModel>[],
        'favorites': <FavoriteModel>[],
        'subscription': null,
        'transactions': <TransactionModel>[],
      };
    }
    final cacheKey = 'dashboard_$userId';
    final cachedDashboard = await _dashboardCache.get(cacheKey);
    if (_isCacheValid(cachedDashboard)) {
      log('Dashboard data fetched from cache for user $userId');
      return cachedDashboard!.data;
    }
    try {
      final userFuture = getUser(userId);
      final preferencesFuture = getPreferences();
      final userPreferenceFuture = getUserPreference(userId);
      final categoriesFuture = getCategories();
      final tipsFuture = getTips(includePremium: true);
      final notificationsFuture = getNotifications(userId);
      final remindersFuture = getReminders(userId);
      final favoritesFuture = getFavorites(userId);
      final subscriptionFuture = getSubscription(userId);
      final transactionsFuture = getTransactions(userId);

      final results = await Future.wait([
        userFuture,
        preferencesFuture,
        userPreferenceFuture,
        categoriesFuture,
        tipsFuture,
        notificationsFuture,
        remindersFuture,
        favoritesFuture,
        subscriptionFuture,
        transactionsFuture,
      ]);

      final data = {
        'user': results[0] as UserModel?,
        'preferences': results[1] as List<PreferenceModel>,
        'userPreference': results[2] as UserPreferenceModel?,
        'categories': results[3] as List<CategoryModel>,
        'tips': results[4] as List<TipModel>,
        'notifications': results[5] as List<NotificationModel>,
        'reminders': results[6] as List<ReminderModel>,
        'favorites': results[7] as List<FavoriteModel>,
        'subscription': results[8] as SubscriptionModel?,
        'transactions': results[9] as List<TransactionModel>,
      };

      _dashboardCache.put(cacheKey, CachedItem(data, DateTime.now()));
      log('Loaded dashboard data and cached for user $userId: '
          'user=${(data['user'] as UserModel?)?.userId ?? "null"}, '
          'tips=${(data['tips'] as List<TipModel>).length}, '
          'categories=${(data['categories'] as List<CategoryModel>).length}, '
          'preferences=${(data['preferences'] as List<PreferenceModel>).length}, '
          'reminders=${(data['reminders'] as List<ReminderModel>).length}, '
          'notifications=${(data['notifications'] as List<NotificationModel>).length}, '
          'favorites=${(data['favorites'] as List<FavoriteModel>).length}, '
          'subscription=${(data['subscription'] as SubscriptionModel?)?.userId ?? "null"}, '
          'transactions=${(data['transactions'] as List<TransactionModel>).length}');

      if (await _isOnline()) {
        // Trigger background sync
        syncAllData(userId).catchError((e) {
          log('Background sync failed for user $userId: $e');
        });
      }

      return data;
    } catch (e) {
      log('Error fetching dashboard data for user $userId: $e');
      return {
        'user': null,
        'preferences': <PreferenceModel>[],
        'userPreference': null,
        'categories': <CategoryModel>[],
        'tips': <TipModel>[],
        'notifications': <NotificationModel>[],
        'reminders': <ReminderModel>[],
        'favorites': <FavoriteModel>[],
        'subscription': null,
        'transactions': <TransactionModel>[],
      };
    }
  }
}