import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer';
import 'package:sqflite/sqflite.dart';
import 'package:wellness_app/core/constants/app_constants.dart';
import 'package:wellness_app/core/db/database_helper.dart';
import 'package:wellness_app/core/services/wellness_cache_service.dart';
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

class DataRepository {
  static final DataRepository instance = DataRepository._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WellnessCacheService _cacheService = WellnessCacheService();

  DataRepository._internal();

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;
    log('Network status: ${isOnline ? 'Online' : 'Offline'}');
    return isOnline;
  }

  Future<bool> isOnline() async {
    return await _isOnline();
  }

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

  Future<UserModel?> getUser(String userId) async {
    if (userId.isEmpty) {
      log('getUser: Invalid userId (empty)');
      return null;
    }
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'users',
      param: userId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('User fetched from cache: $userId');
      return UserModel.fromJson(_sanitizeMap(cacheData.data));
    }
    if (isOnline) {
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .get();
        if (doc.exists) {
          final sanitizedData = _sanitizeMap(doc.data()!);
          final user = UserModel.fromFirestore(sanitizedData, userId);
          await _dbHelper.insertUser(user);
          await _cacheService.saveDataToCache(
            endpoint: 'users',
            param: userId,
            data: user.toJson(),
            cacheDuration: const Duration(minutes: 10),
            isToRefresh: false,
          );
          log('User fetched from Firestore: ${user.userId}');
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
      await _cacheService.saveDataToCache(
        endpoint: 'users',
        param: userId,
        data: user.toJson(),
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );
      log('User fetched from local database: ${user.userId}');
    }
    return user;
  }

  Future<void> updateUser(UserModel user) async {
    if (user.userId.isEmpty) {
      log('updateUser: Invalid userId (empty)');
      return;
    }
    await _dbHelper.insertUser(user);
    if (await _isOnline()) {
      try {
        final sanitizedData = _sanitizeMap(user.toFirestore());
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.userId)
            .set(sanitizedData);
        await _cacheService.saveDataToCache(
          endpoint: 'users',
          param: user.userId,
          data: user.toJson(),
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: true,
        );
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
    await _cacheService.clearCache();
  }

  Future<List<PreferenceModel>> getPreferences() async {
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'preferences',
      param: null,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Preferences fetched from cache');
      return (cacheData.data['preferences'] as List<dynamic>)
          .map(
            (e) => PreferenceModel.fromJson(
              _sanitizeMap(e as Map<String, dynamic>),
            ),
          )
          .toList();
    }
    if (isOnline) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.preferencesCollection)
            .get();
        final preferences = snapshot.docs
            .map(
              (doc) => PreferenceModel.fromFirestore(
                _sanitizeMap(doc.data()),
                doc.id,
              ),
            )
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var preference in preferences) {
          batch.insert('preferences', {
            'preferenceId': preference.preferenceId,
            'data': preference.toProto(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit();
        await _cacheService.saveDataToCache(
          endpoint: 'preferences',
          param: null,
          data: {'preferences': preferences.map((e) => e.toJson()).toList()},
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: false,
        );
        log('Fetched ${preferences.length} preferences from Firestore');
        return preferences;
      } catch (e) {
        log('Error fetching preferences from Firestore: $e');
      }
    }
    final preferences = await _dbHelper.getAllPreferences();
    await _cacheService.saveDataToCache(
      endpoint: 'preferences',
      param: null,
      data: {'preferences': preferences.map((e) => e.toJson()).toList()},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: false,
    );
    log('Fetched ${preferences.length} preferences from local database');
    return preferences;
  }

  Future<PreferenceModel?> getPreference(String preferenceId) async {
    if (preferenceId.isEmpty) {
      log('getPreference: Invalid preferenceId (empty)');
      return null;
    }
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'preferences',
      param: preferenceId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Preference fetched from cache: $preferenceId');
      return PreferenceModel.fromJson(_sanitizeMap(cacheData.data));
    }
    if (isOnline) {
      try {
        final doc = await _firestore
            .collection(AppConstants.preferencesCollection)
            .doc(preferenceId)
            .get();
        if (doc.exists) {
          final preference = PreferenceModel.fromFirestore(
            _sanitizeMap(doc.data()!),
            preferenceId,
          );
          await _dbHelper.insertPreference(preference);
          await _cacheService.saveDataToCache(
            endpoint: 'preferences',
            param: preferenceId,
            data: preference.toJson(),
            cacheDuration: const Duration(minutes: 10),
            isToRefresh: false,
          );
          log('Preference fetched from Firestore: $preferenceId');
          return preference;
        }
      } catch (e) {
        log('Error fetching preference from Firestore: $e');
      }
    }
    final preference = await _dbHelper.getPreference(preferenceId);
    if (preference != null) {
      await _cacheService.saveDataToCache(
        endpoint: 'preferences',
        param: preferenceId,
        data: preference.toJson(),
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );
      log('Preference fetched from local database: $preferenceId');
    }
    return preference;
  }

  Future<UserPreferenceModel?> getUserPreference(String userId) async {
    if (userId.isEmpty) {
      log('getUserPreference: Invalid userId (empty)');
      return null;
    }
    await getPreferences();
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'user_preferences',
      param: userId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('User preference fetched from cache: $userId');
      return UserPreferenceModel.fromJson(_sanitizeMap(cacheData.data));
    }
    if (isOnline) {
      try {
        final doc = await _firestore
            .collection(AppConstants.userPreferencesCollection)
            .doc(userId)
            .get();
        if (doc.exists) {
          final userPreference = UserPreferenceModel.fromFirestore(
            _sanitizeMap(doc.data()!),
            userId,
          );
          await _dbHelper.insertUserPreference(userPreference);
          await _cacheService.saveDataToCache(
            endpoint: 'user_preferences',
            param: userId,
            data: userPreference.toJson(),
            cacheDuration: const Duration(minutes: 10),
            isToRefresh: false,
          );
          log('User preference fetched from Firestore: $userId');
          return userPreference;
        }
      } catch (e) {
        log('Error fetching user preference from Firestore: $e');
      }
    }
    final userPreference = await _dbHelper.getUserPreference(userId);
    if (userPreference != null) {
      await _cacheService.saveDataToCache(
        endpoint: 'user_preferences',
        param: userId,
        data: userPreference.toJson(),
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );
      log('User preference fetched from local database: $userId');
    }
    return userPreference;
  }

  Future<void> updateUserPreference(UserPreferenceModel userPreference) async {
    if (userPreference.userId.isEmpty) {
      log('updateUserPreference: Invalid userId (empty)');
      return;
    }
    await _dbHelper.insertUserPreference(userPreference);
    if (await _isOnline()) {
      try {
        final sanitizedData = _sanitizeMap(userPreference.toFirestore());
        await _firestore
            .collection(AppConstants.userPreferencesCollection)
            .doc(userPreference.userId)
            .set(sanitizedData);
        await _cacheService.saveDataToCache(
          endpoint: 'user_preferences',
          param: userPreference.userId,
          data: userPreference.toJson(),
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: true,
        );
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
    await _cacheService.clearCache();
  }

  Future<List<CategoryModel>> getCategories() async {
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'categories',
      param: null,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Categories fetched from cache');
      return (cacheData.data['categories'] as List<dynamic>)
          .map(
            (e) =>
                CategoryModel.fromJson(_sanitizeMap(e as Map<String, dynamic>)),
          )
          .toList();
    }
    if (isOnline) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.categoriesCollection)
            .get();
        final categories = snapshot.docs
            .map(
              (doc) =>
                  CategoryModel.fromFirestore(_sanitizeMap(doc.data()), doc.id),
            )
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var category in categories) {
          batch.insert('categories', {
            'categoryId': category.categoryId,
            'data': category.toProto(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit();
        await _cacheService.saveDataToCache(
          endpoint: 'categories',
          param: null,
          data: {'categories': categories.map((e) => e.toJson()).toList()},
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: false,
        );
        log('Fetched ${categories.length} categories from Firestore');
        return categories;
      } catch (e) {
        log('Error fetching categories from Firestore: $e');
      }
    }
    final categories = await _dbHelper.getAllCategories();
    await _cacheService.saveDataToCache(
      endpoint: 'categories',
      param: null,
      data: {'categories': categories.map((e) => e.toJson()).toList()},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: false,
    );
    log('Fetched ${categories.length} categories from local database');
    return categories;
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    if (categoryId.isEmpty) {
      log('getCategory: Invalid categoryId (empty)');
      return null;
    }
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'categories',
      param: categoryId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Category fetched from cache: $categoryId');
      return CategoryModel.fromJson(_sanitizeMap(cacheData.data));
    }
    if (isOnline) {
      try {
        final doc = await _firestore
            .collection(AppConstants.categoriesCollection)
            .doc(categoryId)
            .get();
        if (doc.exists) {
          final category = CategoryModel.fromFirestore(
            _sanitizeMap(doc.data()!),
            categoryId,
          );
          await _dbHelper.insertCategory(category);
          await _cacheService.saveDataToCache(
            endpoint: 'categories',
            param: categoryId,
            data: category.toJson(),
            cacheDuration: const Duration(minutes: 10),
            isToRefresh: false,
          );
          log('Category fetched from Firestore: $categoryId');
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
      await _cacheService.saveDataToCache(
        endpoint: 'categories',
        param: categoryId,
        data: category.toJson(),
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );
      log('Category fetched from local database: $categoryId');
    }
    return category;
  }

  Future<List<TipModel>> getTips({bool includePremium = false}) async {
    final isOnline = await _isOnline();
    final cacheKeySuffix = includePremium ? '_premium' : '';
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'tips$cacheKeySuffix',
      param: null,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Tips fetched from cache (includePremium: $includePremium)');
      return (cacheData.data['tips'] as List<dynamic>)
          .map(
            (e) => TipModel.fromJson(_sanitizeMap(e as Map<String, dynamic>)),
          )
          .toList();
    }
    if (isOnline) {
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
          final tip = TipModel.fromFirestore(_sanitizeMap(doc.data()), doc.id);
          if ((includePremium || !tip.isPremium) &&
              categoryIds.contains(tip.categoryId)) {
            batch.insert('tips', {
              'tipsId': tip.tipsId,
              'categoryId': tip.categoryId,
              'data': tip.toProto(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            tips.add(tip);
          }
        }
        await batch.commit();
        await _cacheService.saveDataToCache(
          endpoint: 'tips$cacheKeySuffix',
          param: null,
          data: {'tips': tips.map((e) => e.toJson()).toList()},
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: false,
        );
        log(
          'Fetched ${tips.length} tips from Firestore (includePremium: $includePremium)',
        );
        return tips;
      } catch (e) {
        log('Error fetching tips from Firestore: $e');
      }
    }
    final tips = await _dbHelper.getAllTips();
    final filteredTips = tips
        .where((tip) => includePremium || !tip.isPremium)
        .toList();
    await _cacheService.saveDataToCache(
      endpoint: 'tips$cacheKeySuffix',
      param: null,
      data: {'tips': filteredTips.map((e) => e.toJson()).toList()},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: false,
    );
    log(
      'Fetched ${filteredTips.length} tips from local database (includePremium: $includePremium)',
    );
    return filteredTips;
  }

  Future<List<TipModel>> getTipsByCategory(
    String categoryId, {
    bool includePremium = false,
  }) async {
    if (categoryId.isEmpty) {
      log('getTipsByCategory: Invalid categoryId (empty)');
      return [];
    }
    final isOnline = await _isOnline();
    final cacheKeySuffix = includePremium ? '_premium' : '';
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'tips_by_category$cacheKeySuffix',
      param: categoryId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log(
        'Tips fetched from cache for category $categoryId (includePremium: $includePremium)',
      );
      return (cacheData.data['tips'] as List<dynamic>)
          .map(
            (e) => TipModel.fromJson(_sanitizeMap(e as Map<String, dynamic>)),
          )
          .toList();
    }
    if (isOnline) {
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
          final tip = TipModel.fromFirestore(_sanitizeMap(doc.data()), doc.id);
          if (includePremium || !tip.isPremium) {
            batch.insert('tips', {
              'tipsId': tip.tipsId,
              'categoryId': tip.categoryId,
              'data': tip.toProto(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            tips.add(tip);
          }
        }
        await batch.commit();
        await _cacheService.saveDataToCache(
          endpoint: 'tips_by_category$cacheKeySuffix',
          param: categoryId,
          data: {'tips': tips.map((e) => e.toJson()).toList()},
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: false,
        );
        log(
          'Fetched ${tips.length} tips for category $categoryId from Firestore (includePremium: $includePremium)',
        );
        return tips;
      } catch (e) {
        log('Error fetching tips by category from Firestore: $e');
      }
    }
    final tips = await _dbHelper.getTipsByCategory(categoryId);
    final filteredTips = tips
        .where((tip) => includePremium || !tip.isPremium)
        .toList();
    await _cacheService.saveDataToCache(
      endpoint: 'tips_by_category$cacheKeySuffix',
      param: categoryId,
      data: {'tips': filteredTips.map((e) => e.toJson()).toList()},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: false,
    );
    log(
      'Fetched ${filteredTips.length} tips for category $categoryId from local database (includePremium: $includePremium)',
    );
    return filteredTips;
  }

  Future<TipModel?> getTip(String tipsId) async {
    if (tipsId.isEmpty) {
      log('getTip: Invalid tipsId (empty)');
      return null;
    }
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'tips',
      param: tipsId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Tip fetched from cache: $tipsId');
      return TipModel.fromJson(_sanitizeMap(cacheData.data));
    }
    if (isOnline) {
      try {
        final doc = await _firestore
            .collection(AppConstants.tipsCollection)
            .doc(tipsId)
            .get();
        if (doc.exists) {
          final tip = TipModel.fromFirestore(_sanitizeMap(doc.data()!), tipsId);
          if (await _dbHelper.getCategory(tip.categoryId) != null) {
            await _dbHelper.insertTip(tip);
            await _cacheService.saveDataToCache(
              endpoint: 'tips',
              param: tipsId,
              data: tip.toJson(),
              cacheDuration: const Duration(minutes: 10),
              isToRefresh: false,
            );
            log('Tip fetched from Firestore: $tipsId');
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
      await _cacheService.saveDataToCache(
        endpoint: 'tips',
        param: tipsId,
        data: tip.toJson(),
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );
      log('Tip fetched from local database: $tipsId');
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
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'favorites',
      param: userId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Favorites fetched from cache for userId: $userId');
      return (cacheData.data['favorites'] as List<dynamic>)
          .map(
            (e) =>
                FavoriteModel.fromJson(_sanitizeMap(e as Map<String, dynamic>)),
          )
          .toList();
    }
    if (isOnline) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.favoriteCollection)
            .where('userId', isEqualTo: userId)
            .get();
        final firestoreFavorites = snapshot.docs
            .map(
              (doc) =>
                  FavoriteModel.fromFirestore(_sanitizeMap(doc.data()), doc.id),
            )
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var favorite in firestoreFavorites) {
          if (favorite.userId.isEmpty) {
            log('Skipping invalid favorite ${favorite.id} with empty userId');
            continue;
          }
          batch.insert('favorites', {
            'id': favorite.id,
            'userId': favorite.userId,
            'data': favorite.toProto(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit();
        await _cacheService.saveDataToCache(
          endpoint: 'favorites',
          param: userId,
          data: {
            'favorites': firestoreFavorites.map((e) => e.toJson()).toList(),
          },
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: false,
        );
        log(
          'Synced ${firestoreFavorites.length} favorites from Firestore for userId: $userId',
        );
        return firestoreFavorites;
      } catch (e) {
        log(
          'Error fetching favorites from Firestore for userId: $userId, error: $e',
        );
      }
    }
    final localFavorites = await _dbHelper.getFavoritesByUser(userId);
    await _cacheService.saveDataToCache(
      endpoint: 'favorites',
      param: userId,
      data: {'favorites': localFavorites.map((e) => e.toJson()).toList()},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: false,
    );
    log(
      'Fetched ${localFavorites.length} favorites from local database for userId: $userId',
    );
    return localFavorites;
  }

  Future<FavoriteModel> addFavorite(FavoriteModel favorite) async {
    if (favorite.userId.isEmpty) {
      log('addFavorite: Invalid userId (empty)');
      throw Exception('Cannot add favorite with empty userId');
    }
    await _dbHelper.insertFavorite(favorite);
    await _cacheService.saveDataToCache(
      endpoint: 'favorites',
      param: favorite.userId,
      data: {},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: true,
    );
    log('Favorite added to local database: ${favorite.id}');
    if (await _isOnline()) {
      try {
        final sanitizedData = _sanitizeMap(favorite.toFirestore());
        await _firestore
            .collection(AppConstants.favoriteCollection)
            .doc(favorite.id)
            .set(sanitizedData);
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
    await _dbHelper.deleteFavorite(id);
    await _dbHelper.deletePendingFavorite(id);
    await _cacheService.clearCache();
  }

  Future<List<ReminderModel>> getRemindersByUser(String userId) async {
    return getReminders(userId);
  }

  Future<List<ReminderModel>> getReminders(String userId) async {
    if (userId.isEmpty) {
      log('getReminders: Invalid userId (empty)');
      return [];
    }
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'reminders',
      param: userId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Reminders fetched from cache for userId: $userId');
      return (cacheData.data['reminders'] as List<dynamic>)
          .map(
            (e) =>
                ReminderModel.fromJson(_sanitizeMap(e as Map<String, dynamic>)),
          )
          .toList();
    }
    if (isOnline) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.remindersCollection)
            .where('userId', isEqualTo: userId)
            .get();
        final reminders = snapshot.docs
            .map(
              (doc) =>
                  ReminderModel.fromFirestore(_sanitizeMap(doc.data()), doc.id),
            )
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var reminder in reminders) {
          batch.insert('reminders', {
            'id': reminder.id,
            'userId': reminder.userId,
            'data': reminder.toProto(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit();
        await _cacheService.saveDataToCache(
          endpoint: 'reminders',
          param: userId,
          data: {'reminders': reminders.map((e) => e.toJson()).toList()},
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: false,
        );
        log(
          'Fetched ${reminders.length} reminders from Firestore for userId: $userId',
        );
        return reminders;
      } catch (e) {
        log('Error fetching reminders from Firestore: $e');
      }
    }
    final reminders = await _dbHelper.getRemindersByUser(userId);
    await _cacheService.saveDataToCache(
      endpoint: 'reminders',
      param: userId,
      data: {'reminders': reminders.map((e) => e.toJson()).toList()},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: false,
    );
    log(
      'Fetched ${reminders.length} reminders from local database for userId: $userId',
    );
    return reminders;
  }

  Future<ReminderModel?> getReminderById(String reminderId) async {
    if (reminderId.isEmpty) {
      log('getReminderById: Invalid reminderId (empty)');
      return null;
    }
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'reminders',
      param: reminderId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Reminder fetched from cache: $reminderId');
      return ReminderModel.fromJson(_sanitizeMap(cacheData.data));
    }
    if (isOnline) {
      try {
        final doc = await _firestore
            .collection(AppConstants.remindersCollection)
            .doc(reminderId)
            .get();
        if (doc.exists) {
          final reminder = ReminderModel.fromFirestore(
            _sanitizeMap(doc.data()!),
            doc.id,
          );
          await _dbHelper.insertReminder(reminder);
          await _cacheService.saveDataToCache(
            endpoint: 'reminders',
            param: reminderId,
            data: reminder.toJson(),
            cacheDuration: const Duration(minutes: 10),
            isToRefresh: false,
          );
          log('Reminder fetched from Firestore: $reminderId');
          return reminder;
        }
      } catch (e) {
        log('Error fetching reminder $reminderId: $e');
      }
    }
    final reminder = await _dbHelper.getReminder(reminderId);
    if (reminder != null) {
      await _cacheService.saveDataToCache(
        endpoint: 'reminders',
        param: reminderId,
        data: reminder.toJson(),
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );
      log('Reminder fetched from local database: $reminderId');
    }
    return reminder;
  }

  Future<void> addReminder(ReminderModel reminder) async {
    if (reminder.userId.isEmpty) {
      log('addReminder: Invalid userId (empty)');
      throw Exception('Cannot add reminder with empty userId');
    }
    await _dbHelper.insertReminder(reminder);
    await _cacheService.saveDataToCache(
      endpoint: 'reminders',
      param: reminder.userId,
      data: {},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: true,
    );
    log('Reminder added to local database: ${reminder.id}');
    if (await _isOnline()) {
      try {
        final sanitizedData = _sanitizeMap(reminder.toFirestore());
        await _firestore
            .collection(AppConstants.remindersCollection)
            .doc(reminder.id)
            .set(sanitizedData);
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
    await _cacheService.saveDataToCache(
      endpoint: 'reminders',
      param: reminder.userId,
      data: {},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: true,
    );
    log('Reminder updated in local database: ${reminder.id}');
    if (await _isOnline()) {
      try {
        final sanitizedData = _sanitizeMap(reminder.toFirestore());
        await _firestore
            .collection(AppConstants.remindersCollection)
            .doc(reminder.id)
            .set(sanitizedData);
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
    await _dbHelper.deleteReminder(id);
    await _dbHelper.deletePendingReminder(id);
    await _cacheService.clearCache();
  }

  Future<List<NotificationModel>> getNotifications(
    String userId, {
    int limit = 50,
  }) async {
    if (userId.isEmpty) {
      log('getNotifications: Invalid userId (empty)');
      return [];
    }
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'notifications',
      param: userId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Notifications fetched from cache for userId: $userId');
      return (cacheData.data['notifications'] as List<dynamic>)
          .map(
            (e) => NotificationModel.fromJson(
              _sanitizeMap(e as Map<String, dynamic>),
            ),
          )
          .toList();
    }
    if (isOnline) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();
        final notifications = snapshot.docs
            .map(
              (doc) => NotificationModel.fromFirestore(
                _sanitizeMap(doc.data()),
                doc.id,
              ),
            )
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var notification in notifications) {
          batch.insert('notifications', {
            'id': notification.id,
            'userId': notification.userId,
            'data': notification.toProto(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit();
        await _cacheService.saveDataToCache(
          endpoint: 'notifications',
          param: userId,
          data: {
            'notifications': notifications.map((e) => e.toJson()).toList(),
          },
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: false,
        );
        log(
          'Fetched ${notifications.length} notifications from Firestore for userId: $userId',
        );
        return notifications;
      } catch (e) {
        log('Error fetching notifications from Firestore: $e');
      }
    }
    final notifications = await _dbHelper.getNotificationsByUser(userId);
    await _cacheService.saveDataToCache(
      endpoint: 'notifications',
      param: userId,
      data: {'notifications': notifications.map((e) => e.toJson()).toList()},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: false,
    );
    log(
      'Fetched ${notifications.length} notifications from SQLite for userId: $userId',
    );
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
      title: _sanitizeText(notification.title),
      body: _sanitizeText(notification.body),
      type: notification.type,
      isRead: true,
      payload: _sanitizeMap(notification.payload),
      timestamp: notification.timestamp,
    );
    await _dbHelper.insertNotification(updated);
    await _cacheService.saveDataToCache(
      endpoint: 'notifications',
      param: notification.userId,
      data: {},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: true,
    );
    log('Notification marked as read in local database: $id');
    if (await _isOnline()) {
      try {
        final sanitizedData = _sanitizeMap(updated.toFirestore());
        await _firestore
            .collection(AppConstants.notificationsCollection)
            .doc(id)
            .set(sanitizedData);
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
    await _dbHelper.deleteNotification(id);
    await _dbHelper.deletePendingNotification(id);
    await _cacheService.clearCache();
  }

  Future<SubscriptionModel?> getSubscription(String userId) async {
    if (userId.isEmpty) {
      log('getSubscription: Invalid userId (empty)');
      return null;
    }
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'subscriptions',
      param: userId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Subscription fetched from cache: $userId');
      return SubscriptionModel.fromJson(_sanitizeMap(cacheData.data));
    }
    if (isOnline) {
      try {
        final doc = await _firestore
            .collection(AppConstants.subscriptionsCollection)
            .doc(userId)
            .get();
        if (doc.exists) {
          final subscription = SubscriptionModel.fromFirestore(
            _sanitizeMap(doc.data()!),
            userId,
          );
          await _dbHelper.insertSubscription(subscription);
          await _cacheService.saveDataToCache(
            endpoint: 'subscriptions',
            param: userId,
            data: subscription.toJson(),
            cacheDuration: const Duration(minutes: 10),
            isToRefresh: false,
          );
          log('Subscription fetched from Firestore: $userId');
          return subscription;
        }
      } catch (e) {
        log('Error fetching subscription from Firestore: $e');
      }
    }
    final subscription = await _dbHelper.getSubscription(userId);
    if (subscription != null) {
      await _cacheService.saveDataToCache(
        endpoint: 'subscriptions',
        param: userId,
        data: subscription.toJson(),
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );
      log('Subscription fetched from local database: $userId');
    }
    return subscription;
  }

  Future<void> updateSubscription(SubscriptionModel subscription) async {
    if (subscription.userId.isEmpty) {
      log('updateSubscription: Invalid userId (empty)');
      return;
    }
    await _dbHelper.insertSubscription(subscription);
    await _cacheService.saveDataToCache(
      endpoint: 'subscriptions',
      param: subscription.userId,
      data: subscription.toJson(),
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: true,
    );
    log('Subscription updated in local database: ${subscription.userId}');
    if (await _isOnline()) {
      try {
        final sanitizedData = _sanitizeMap(subscription.toFirestore());
        await _firestore
            .collection(AppConstants.subscriptionsCollection)
            .doc(subscription.userId)
            .set(sanitizedData);
        log('Subscription updated in Firestore: ${subscription.userId}');
      } catch (e) {
        log('Error updating subscription to Firestore: $e');
        await _dbHelper.insertPendingSubscription(subscription);
        log(
          'Subscription stored in pending_operations: ${subscription.userId}',
        );
      }
    } else {
      await _dbHelper.insertPendingSubscription(subscription);
      log(
        'Offline: Subscription stored in pending_operations: ${subscription.userId}',
      );
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
    await _cacheService.clearCache();
  }

  Future<List<TransactionModel>> getTransactions(String userId) async {
    if (userId.isEmpty) {
      log('getTransactions: Invalid userId (empty)');
      return [];
    }
    final isOnline = await _isOnline();
    final cacheData = await _cacheService.getCacheData(
      endpoint: 'transactions',
      param: userId,
      hasInternet: isOnline,
    );
    if (!cacheData.hasCacheExpired) {
      log('Transactions fetched from cache for userId: $userId');
      return (cacheData.data['transactions'] as List<dynamic>)
          .map(
            (e) => TransactionModel.fromJson(
              _sanitizeMap(e as Map<String, dynamic>),
            ),
          )
          .toList();
    }
    if (isOnline) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.transactionsCollection)
            .where('userId', isEqualTo: userId)
            .get();
        final transactions = snapshot.docs
            .map(
              (doc) => TransactionModel.fromFirestore(
                _sanitizeMap(doc.data()),
                doc.id,
              ),
            )
            .toList();
        final db = await _dbHelper.database;
        final batch = db.batch();
        for (var transaction in transactions) {
          batch.insert('transactions', {
            'id': transaction.id,
            'userId': transaction.userId,
            'data': transaction.toProto(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit();
        await _cacheService.saveDataToCache(
          endpoint: 'transactions',
          param: userId,
          data: {'transactions': transactions.map((e) => e.toJson()).toList()},
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: false,
        );
        log(
          'Fetched ${transactions.length} transactions from Firestore for userId: $userId',
        );
        return transactions;
      } catch (e) {
        log('Error fetching transactions from Firestore: $e');
      }
    }
    final transactions = await _dbHelper.getTransactionsByUser(userId);
    await _cacheService.saveDataToCache(
      endpoint: 'transactions',
      param: userId,
      data: {'transactions': transactions.map((e) => e.toJson()).toList()},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: false,
    );
    log(
      'Fetched ${transactions.length} transactions from local database for userId: $userId',
    );
    return transactions;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    if (transaction.userId.isEmpty) {
      log('addTransaction: Invalid userId (empty)');
      throw Exception('Cannot add transaction with empty userId');
    }
    await _dbHelper.insertTransaction(transaction);
    await _cacheService.saveDataToCache(
      endpoint: 'transactions',
      param: transaction.userId,
      data: {},
      cacheDuration: const Duration(minutes: 10),
      isToRefresh: true,
    );
    log('Transaction added to local database: ${transaction.id}');
    if (await _isOnline()) {
      try {
        final sanitizedData = _sanitizeMap(transaction.toFirestore());
        await _firestore
            .collection(AppConstants.transactionsCollection)
            .doc(transaction.id)
            .set(sanitizedData);
        log('Transaction added to Firestore: ${transaction.id}');
      } catch (e) {
        log('Error adding transaction to Firestore: $e');
        await _dbHelper.insertPendingTransaction(transaction);
        log('Transaction stored in pending_operations: ${transaction.id}');
      }
    } else {
      await _dbHelper.insertPendingTransaction(transaction);
      log(
        'Offline: Transaction stored in pending_operations: ${transaction.id}',
      );
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
    await _dbHelper.deleteTransaction(id);
    await _dbHelper.deletePendingTransaction(id);
    await _cacheService.clearCache();
  }

  Future<bool> canAccessPremiumContent(String userId) async {
    if (userId.isEmpty) {
      log('canAccessPremiumContent: Invalid userId (empty)');
      return false;
    }
    final subscription = await getSubscription(userId);
    if (subscription != null) {
      final canAccess =
          subscription.status == 'active' &&
          subscription.endDate != null &&
          subscription.endDate!.isAfter(DateTime.now());
      log('Premium access for user $userId: $canAccess');
      return canAccess;
    }
    log('No subscription found for user $userId, premium access denied');
    return false;
  }

  Future<Map<String, dynamic>> getDashboardData(String userId) async {
    if (userId.isEmpty) {
      log('getDashboardData: Invalid userId (empty)', name: 'DataRepository');
      return _emptyDashboardData();
    }

    try {
      final isOnline = await _isOnline();
      final canAccessPremium = await canAccessPremiumContent(userId);

      // Offline mode: Try cache first, then SQLite
      if (!isOnline) {
        final cacheData = await _cacheService.getCacheData(
          endpoint: 'dashboard',
          param: userId,
          hasInternet: false,
        );
        if (!cacheData.hasCacheExpired && cacheData.data.isNotEmpty) {
          log(
            'Returning cached dashboard data for user $userId (offline)',
            name: 'DataRepository',
          );
          return _sanitizeMap(cacheData.data);
        }

        // Fetch from SQLite
        final results = await Future.wait([
          _dbHelper.getUser(userId),
          _dbHelper.getAllPreferences(),
          _dbHelper.getUserPreference(userId),
          _dbHelper.getAllCategories(),
          _dbHelper.getAllTips(),
          _dbHelper.getNotificationsByUser(userId),
          _dbHelper.getRemindersByUser(userId),
          _dbHelper.getFavoritesByUser(userId),
          _dbHelper.getSubscription(userId),
          _dbHelper.getTransactionsByUser(userId),
        ]);

        final UserModel? user = results[0] as UserModel?;
        final List<PreferenceModel> preferences =
            results[1] as List<PreferenceModel>;
        final UserPreferenceModel? userPreference =
            results[2] as UserPreferenceModel?;
        final List<CategoryModel> categories =
            results[3] as List<CategoryModel>;
        final List<TipModel> tips = results[4] as List<TipModel>;
        final List<NotificationModel> notifications =
            results[5] as List<NotificationModel>;
        final List<ReminderModel> reminders = results[6] as List<ReminderModel>;
        final List<FavoriteModel> favorites = results[7] as List<FavoriteModel>;
        final SubscriptionModel? subscription =
            results[8] as SubscriptionModel?;
        final List<TransactionModel> transactions =
            results[9] as List<TransactionModel>;

        final dashboardData = {
          'user': user?.toJson(),
          'preferences': preferences.map((e) => e.toJson()).toList(),
          'userPreference': userPreference?.toJson(),
          'categories': categories.map((e) => e.toJson()).toList(),
          'tips': tips.map((e) => e.toJson()).toList(),
          'notifications': notifications.map((e) => e.toJson()).toList(),
          'reminders': reminders.map((e) => e.toJson()).toList(),
          'favorites': favorites.map((e) => e.toJson()).toList(),
          'subscription': subscription?.toJson(),
          'transactions': transactions.map((e) => e.toJson()).toList(),
        };

        await _cacheService.saveDataToCache(
          endpoint: 'dashboard',
          param: userId,
          data: dashboardData,
          cacheDuration: const Duration(minutes: 10),
          isToRefresh: false,
        );

        log(
          'Fetched dashboard data from SQLite for user $userId: '
          'user=${user?.userId ?? "null"}, '
          'tips=${tips.length}, '
          'categories=${categories.length}, '
          'preferences=${preferences.length}, '
          'reminders=${reminders.length}, '
          'notifications=${notifications.length}, '
          'favorites=${favorites.length}, '
          'subscription=${subscription?.userId ?? "null"}, '
          'transactions=${transactions.length}',
          name: 'DataRepository',
        );

        return _sanitizeMap(dashboardData);
      }

      // Online mode: Try cache first
      final cacheData = await _cacheService.getCacheData(
        endpoint: 'dashboard',
        param: userId,
        hasInternet: true,
      );
      if (!cacheData.hasCacheExpired && cacheData.data.isNotEmpty) {
        log(
          'Returning cached dashboard data for user $userId',
          name: 'DataRepository',
        );
        // Trigger background sync
        syncAllData(userId).catchError((e, stackTrace) {
          log(
            'Background sync failed: $e',
            name: 'DataRepository',
            stackTrace: stackTrace,
          );
        });
        return _sanitizeMap(cacheData.data);
      }

      // Fetch fresh data
      final results = await Future.wait([
        getUser(userId),
        getPreferences(),
        getUserPreference(userId),
        getCategories(),
        getTips(includePremium: true), // Always include premium tips
        getNotifications(userId),
        getReminders(userId),
        getFavorites(userId),
        getSubscription(userId),
        getTransactions(userId),
      ]);

      final UserModel? user = results[0] as UserModel?;
      final List<PreferenceModel> preferences =
          results[1] as List<PreferenceModel>;
      final UserPreferenceModel? userPreference =
          results[2] as UserPreferenceModel?;
      final List<CategoryModel> categories = results[3] as List<CategoryModel>;
      final List<TipModel> tips = results[4] as List<TipModel>;
      final List<NotificationModel> notifications =
          results[5] as List<NotificationModel>;
      final List<ReminderModel> reminders = results[6] as List<ReminderModel>;
      final List<FavoriteModel> favorites = results[7] as List<FavoriteModel>;
      final SubscriptionModel? subscription = results[8] as SubscriptionModel?;
      final List<TransactionModel> transactions =
          results[9] as List<TransactionModel>;

      final dashboardData = {
        'user': user?.toJson(),
        'preferences': preferences.map((e) => e.toJson()).toList(),
        'userPreference': userPreference?.toJson(),
        'categories': categories.map((e) => e.toJson()).toList(),
        'tips': tips.map((e) => e.toJson()).toList(),
        'notifications': notifications.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((e) => e.toJson()).toList(),
        'favorites': favorites.map((e) => e.toJson()).toList(),
        'subscription': subscription?.toJson(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
      };

      await _cacheService.saveDataToCache(
        endpoint: 'dashboard',
        param: userId,
        data: dashboardData,
        cacheDuration: const Duration(minutes: 10),
        isToRefresh: false,
      );

      log(
        'Fetched dashboard data for user $userId: '
        'user=${user?.userId ?? "null"}, '
        'tips=${tips.length}, '
        'categories=${categories.length}, '
        'preferences=${preferences.length}, '
        'reminders=${reminders.length}, '
        'notifications=${notifications.length}, '
        'favorites=${favorites.length}, '
        'subscription=${subscription?.userId ?? "null"}, '
        'transactions=${transactions.length}',
        name: 'DataRepository',
      );

      return _sanitizeMap(dashboardData);
    } catch (e, stackTrace) {
      log(
        'Error fetching dashboard data for user $userId: $e',
        name: 'DataRepository',
        stackTrace: stackTrace,
      );
      return _sanitizeMap(_emptyDashboardData());
    }
  }

  Map<String, dynamic> _emptyDashboardData() {
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
        log('Data synced for user $userId');
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
      log(
        'Offline: Skipping Firestore sync, using local data for user $userId',
      );
    }
  }

  Future<void> syncPendingOperations() async {
    if (await _isOnline()) {
      final db = await _dbHelper.database;
      final batch = _firestore.batch();

      // Process pending favorites
      final pendingFavorites = await _dbHelper.getPendingFavorites();
      for (var favorite in pendingFavorites) {
        batch.set(
          _firestore
              .collection(AppConstants.favoriteCollection)
              .doc(favorite.id),
          _sanitizeMap(favorite.toFirestore()),
        );
      }

      // Process pending reminders
      final pendingReminders = await _dbHelper.getPendingReminders();
      for (var reminder in pendingReminders) {
        batch.set(
          _firestore
              .collection(AppConstants.remindersCollection)
              .doc(reminder.id),
          _sanitizeMap(reminder.toFirestore()),
        );
      }

      // Process pending notifications
      final pendingNotifications = await _dbHelper.getPendingNotifications();
      for (var notification in pendingNotifications) {
        batch.set(
          _firestore
              .collection(AppConstants.notificationsCollection)
              .doc(notification.id),
          _sanitizeMap(notification.toFirestore()),
        );
      }

      // Process pending subscriptions
      final pendingSubscriptions = await _dbHelper.getPendingSubscriptions();
      for (var subscription in pendingSubscriptions) {
        batch.set(
          _firestore
              .collection(AppConstants.subscriptionsCollection)
              .doc(subscription.userId),
          _sanitizeMap(subscription.toFirestore()),
        );
      }

      // Process pending transactions
      final pendingTransactions = await _dbHelper.getPendingTransactions();
      for (var transaction in pendingTransactions) {
        try {
          await _firestore
              .collection(AppConstants.transactionsCollection)
              .doc(transaction.id)
              .set(transaction.toFirestore());
          await _dbHelper.deletePendingTransaction(transaction.id);
          log('Synced pending transaction: ${transaction.id}');
        } catch (e) {
          log('Error syncing pending transaction ${transaction.id}: $e');
        }
      }

      log('Completed syncing pending operations');
    } else {
      log('Offline: Skipping pending operations sync');
    }
  }

  Future<void> clearLocalCache() async {
    await _dbHelper.clearDatabase();
    await _cacheService.clearCache();
    log('Local cache cleared');
  }
}
