import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';

import '../../features/categories/data/models/category_model.dart';
import '../../features/favorites/data/models/favorite_model.dart';
import '../../features/notifications/data/models/notification_model.dart';
import '../../features/preferences/data/models/preference_model.dart';
import '../../features/preferences/data/models/user_preference_model.dart';
import '../../features/profile/data/user_model.dart';
import '../../features/reminders/data/models/reminder_model.dart';
import '../../features/subscription/data/models/subscription_model.dart';
import '../../features/subscription/data/models/transaction_model.dart';
import '../../features/tips/data/models/tips_model.dart';
import '../../features/videoPlayer/data/models/comments_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      log('Returning existing database instance', name: 'DatabaseHelper');
      return _database!;
    }
    log('Initializing new database instance', name: 'DatabaseHelper');
    _database = await _initDB('wellness.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    log('Database path: $path', name: 'DatabaseHelper');
    return await openDatabase(
      path,
      version: 4, // Incremented for comments and queued tables
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        userId TEXT PRIMARY KEY,
        data BLOB NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        categoryId TEXT PRIMARY KEY,
        data BLOB NOT NULL
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        data BLOB NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(userId)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        data BLOB NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(userId)
      )
    ''');

    // Preferences table
    await db.execute('''
      CREATE TABLE preferences (
        preferenceId TEXT PRIMARY KEY,
        data BLOB NOT NULL
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        data BLOB NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(userId)
      )
    ''');

    // Subscriptions table
    await db.execute('''
      CREATE TABLE subscriptions (
        userId TEXT PRIMARY KEY,
        data BLOB NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(userId)
      )
    ''');

    // Tips table
    await db.execute('''
      CREATE TABLE tips (
        tipsId TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        data BLOB NOT NULL
      )
    ''');

    // User Preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        userId TEXT PRIMARY KEY,
        data BLOB NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(userId)
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        data BLOB NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(userId)
      )
    ''');

    // Pending Operations table
    await db.execute('''
      CREATE TABLE pending_operations (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data BLOB NOT NULL
      )
    ''');

    // Cache table
    await db.execute('''
      CREATE TABLE cache (
        cacheKey TEXT PRIMARY KEY,
        expiryDate TEXT NOT NULL,
        data BLOB NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cache_expiry ON cache(expiryDate)',
    );

    // Comments table
    await db.execute('''
      CREATE TABLE comments (
        id TEXT PRIMARY KEY,
        tipsId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userPhotoUrl TEXT,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        likeCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Queued Comments table
    await db.execute('''
      CREATE TABLE queued_comments (
        id TEXT PRIMARY KEY,
        tipsId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userPhotoUrl TEXT,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Queued Interactions table
    await db.execute('''
      CREATE TABLE queued_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        tipsId TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    log(
      'Database created with all tables, version: $version',
      name: 'DatabaseHelper',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    log(
      'Upgrading database from version $oldVersion to $newVersion',
      name: 'DatabaseHelper',
    );
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache (
          cacheKey TEXT PRIMARY KEY,
          expiryDate TEXT NOT NULL,
          data BLOB NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cache_key ON cache(cacheKey)',
      );
      log(
        'Added cache table in migration to version 2',
        name: 'DatabaseHelper',
      );
    }
    if (oldVersion < 3) {
      try {
        await db.execute('DROP INDEX IF EXISTS idx_cache_key');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_cache_expiry ON cache(expiryDate)',
        );
        log(
          'Updated cache table index to idx_cache_expiry in migration to version 3',
          name: 'DatabaseHelper',
        );
      } catch (e) {
        log(
          'Error updating cache index in migration: $e',
          name: 'DatabaseHelper',
          error: e,
        );
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS comments (
          id TEXT PRIMARY KEY,
          tipsId TEXT NOT NULL,
          userId TEXT NOT NULL,
          userName TEXT NOT NULL,
          userPhotoUrl TEXT,
          text TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          likeCount INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS queued_comments (
          id TEXT PRIMARY KEY,
          tipsId TEXT NOT NULL,
          userId TEXT NOT NULL,
          userName TEXT NOT NULL,
          userPhotoUrl TEXT,
          text TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS queued_interactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          tipsId TEXT NOT NULL,
          type TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
      log(
        'Added comments and queued tables in migration to version 4',
        name: 'DatabaseHelper',
      );
    }
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wellness.db');
    await deleteDatabase(path);
    log(
      'Database deleted, will be recreated on next access',
      name: 'DatabaseHelper',
    );
    _database = null;
  }

  // Cache table operations
  Future<void> clearCacheTable() async {
    final db = await database;
    await db.delete('cache');
    log('Cache table cleared', name: 'DatabaseHelper');
  }

  // CommentModel CRUD
  Future<void> insertComment(CommentModel comment) async {
    final db = await database;
    await db.insert(
      'comments',
      comment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log('Inserted comment: ${comment.id}', name: 'DatabaseHelper');
  }

  Future<CommentModel?> getComment(String id) async {
    final db = await database;
    final maps = await db.query('comments', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      log('Retrieved comment: $id', name: 'DatabaseHelper');
      return CommentModel.fromMap(maps.first);
    }
    log('Comment not found: $id', name: 'DatabaseHelper');
    return null;
  }

  Future<List<CommentModel>> getCommentsByTip(String tipsId) async {
    final db = await database;
    final maps = await db.query(
      'comments',
      where: 'tipsId = ? AND parentId IS NULL',
      whereArgs: [tipsId],
      orderBy: 'createdAt DESC',
    );
    final comments = maps.map((map) => CommentModel.fromMap(map)).toList();
    log(
      'Retrieved ${comments.length} comments for tip: $tipsId',
      name: 'DatabaseHelper',
    );
    return comments;
  }

  Future<void> deleteComment(String id) async {
    final db = await database;
    final rows = await db.delete('comments', where: 'id = ?', whereArgs: [id]);
    log('Deleted comment: $id, rows affected: $rows', name: 'DatabaseHelper');
  }

  // Queued Comments CRUD
  Future<void> insertQueuedComment(Map<String, dynamic> comment) async {
    final db = await database;
    await db.insert(
      'queued_comments',
      comment,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log('Inserted queued comment: ${comment['id']}', name: 'DatabaseHelper');
  }

  Future<List<Map<String, dynamic>>> getQueuedComments() async {
    final db = await database;
    final maps = await db.query('queued_comments');
    log('Retrieved ${maps.length} queued comments', name: 'DatabaseHelper');
    return maps;
  }

  Future<void> deleteQueuedComment(String id) async {
    final db = await database;
    final rows = await db.delete(
      'queued_comments',
      where: 'id = ?',
      whereArgs: [id],
    );
    log(
      'Deleted queued comment: $id, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  // Queued Interactions CRUD
  Future<void> insertQueuedInteraction(Map<String, dynamic> interaction) async {
    final db = await database;
    await db.insert(
      'queued_interactions',
      interaction,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log(
      'Inserted queued interaction for tip: ${interaction['tipsId']}',
      name: 'DatabaseHelper',
    );
  }

  Future<List<Map<String, dynamic>>> getQueuedInteractions() async {
    final db = await database;
    final maps = await db.query('queued_interactions');
    log('Retrieved ${maps.length} queued interactions', name: 'DatabaseHelper');
    return maps;
  }

  Future<void> deleteQueuedInteraction(int id) async {
    final db = await database;
    final rows = await db.delete(
      'queued_interactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    log(
      'Deleted queued interaction: $id, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  // CategoryModel CRUD
  Future<void> insertCategory(CategoryModel category) async {
    final db = await database;
    await db.insert('categories', {
      'categoryId': category.categoryId,
      'data': category.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted category: ${category.categoryId}', name: 'DatabaseHelper');
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    if (maps.isNotEmpty) {
      log('Retrieved category: $categoryId', name: 'DatabaseHelper');
      return CategoryModel.fromProto(maps.first['data'] as List<int>);
    }
    log('Category not found: $categoryId', name: 'DatabaseHelper');
    return null;
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    final categories = maps
        .map((map) => CategoryModel.fromProto(map['data'] as List<int>))
        .toList();
    log('Retrieved ${categories.length} categories', name: 'DatabaseHelper');
    return categories;
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await database;
    final rows = await db.delete(
      'categories',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    log(
      'Deleted category: $categoryId, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  // FavoriteModel CRUD
  Future<void> insertFavorite(FavoriteModel favorite) async {
    final db = await database;
    await db.insert('favorites', {
      'id': favorite.id,
      'userId': favorite.userId,
      'data': favorite.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted favorite: ${favorite.id}', name: 'DatabaseHelper');
  }

  Future<FavoriteModel?> getFavorite(String id) async {
    final db = await database;
    final maps = await db.query('favorites', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      log('Retrieved favorite: $id', name: 'DatabaseHelper');
      return FavoriteModel.fromProto(maps.first['data'] as List<int>);
    }
    log('Favorite not found: $id', name: 'DatabaseHelper');
    return null;
  }

  Future<List<FavoriteModel>> getFavoritesByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    final favorites = maps
        .map((map) => FavoriteModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${favorites.length} favorites for user: $userId',
      name: 'DatabaseHelper',
    );
    return favorites;
  }

  Future<void> deleteFavorite(String id) async {
    final db = await database;
    final rows = await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
    log('Deleted favorite: $id, rows affected: $rows', name: 'DatabaseHelper');
  }

  // NotificationModel CRUD
  Future<void> insertNotification(NotificationModel notification) async {
    final db = await database;
    await db.insert('notifications', {
      'id': notification.id,
      'userId': notification.userId,
      'data': notification.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted notification: ${notification.id}', name: 'DatabaseHelper');
  }

  Future<NotificationModel?> getNotification(String id) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      log('Retrieved notification: $id', name: 'DatabaseHelper');
      return NotificationModel.fromProto(maps.first['data'] as List<int>);
    }
    log('Notification not found: $id', name: 'DatabaseHelper');
    return null;
  }

  Future<List<NotificationModel>> getNotificationsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    final notifications = maps
        .map((map) => NotificationModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${notifications.length} notifications for user: $userId',
      name: 'DatabaseHelper',
    );
    return notifications;
  }

  Future<void> deleteNotification(String id) async {
    final db = await database;
    final rows = await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
    log(
      'Deleted notification: $id, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  // PreferenceModel CRUD
  Future<void> insertPreference(PreferenceModel preference) async {
    final db = await database;
    await db.insert('preferences', {
      'preferenceId': preference.preferenceId,
      'data': preference.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log(
      'Inserted preference: ${preference.preferenceId}',
      name: 'DatabaseHelper',
    );
  }

  Future<PreferenceModel?> getPreference(String preferenceId) async {
    final db = await database;
    final maps = await db.query(
      'preferences',
      where: 'preferenceId = ?',
      whereArgs: [preferenceId],
    );
    if (maps.isNotEmpty) {
      log('Retrieved preference: $preferenceId', name: 'DatabaseHelper');
      return PreferenceModel.fromProto(maps.first['data'] as List<int>);
    }
    log('Preference not found: $preferenceId', name: 'DatabaseHelper');
    return null;
  }

  Future<List<PreferenceModel>> getAllPreferences() async {
    final db = await database;
    final maps = await db.query('preferences');
    final preferences = maps
        .map((map) => PreferenceModel.fromProto(map['data'] as List<int>))
        .toList();
    log('Retrieved ${preferences.length} preferences', name: 'DatabaseHelper');
    return preferences;
  }

  Future<void> deletePreference(String preferenceId) async {
    final db = await database;
    final rows = await db.delete(
      'preferences',
      where: 'preferenceId = ?',
      whereArgs: [preferenceId],
    );
    log(
      'Deleted preference: $preferenceId, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  // ReminderModel CRUD
  Future<void> insertReminder(ReminderModel reminder) async {
    final db = await database;
    await db.insert('reminders', {
      'id': reminder.id,
      'userId': reminder.userId,
      'data': reminder.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted reminder: ${reminder.id}', name: 'DatabaseHelper');
  }

  Future<ReminderModel?> getReminder(String id) async {
    final db = await database;
    final maps = await db.query('reminders', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      log('Retrieved reminder: $id', name: 'DatabaseHelper');
      return ReminderModel.fromProto(maps.first['data'] as List<int>);
    }
    log('Reminder not found: $id', name: 'DatabaseHelper');
    return null;
  }

  Future<List<ReminderModel>> getRemindersByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    final reminders = maps
        .map((map) => ReminderModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${reminders.length} reminders for user: $userId',
      name: 'DatabaseHelper',
    );
    return reminders;
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    final rows = await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    log('Deleted reminder: $id, rows affected: $rows', name: 'DatabaseHelper');
  }

  // SubscriptionModel CRUD
  Future<void> insertSubscription(SubscriptionModel subscription) async {
    final db = await database;
    await db.insert('subscriptions', {
      'userId': subscription.userId,
      'data': subscription.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log(
      'Inserted subscription: ${subscription.userId}',
      name: 'DatabaseHelper',
    );
  }

  Future<SubscriptionModel?> getSubscription(String userId) async {
    final db = await database;
    final maps = await db.query(
      'subscriptions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      log('Retrieved subscription: $userId', name: 'DatabaseHelper');
      return SubscriptionModel.fromProto(maps.first['data'] as List<int>);
    }
    log('Subscription not found: $userId', name: 'DatabaseHelper');
    return null;
  }

  Future<void> deleteSubscription(String userId) async {
    final db = await database;
    final rows = await db.delete(
      'subscriptions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    log(
      'Deleted subscription: $userId, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  // TipModel CRUD
  Future<void> insertTip(TipModel tip) async {
    final db = await database;
    await db.insert('tips', {
      'tipsId': tip.tipsId,
      'categoryId': tip.categoryId,
      'data': tip.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted tip: ${tip.tipsId}', name: 'DatabaseHelper');
  }

  Future<TipModel?> getTip(String tipsId) async {
    final db = await database;
    final maps = await db.query(
      'tips',
      where: 'tipsId = ?',
      whereArgs: [tipsId],
    );
    if (maps.isNotEmpty) {
      log('Retrieved tip: $tipsId', name: 'DatabaseHelper');
      return TipModel.fromProto(maps.first['data'] as List<int>);
    }
    log('Tip not found: $tipsId', name: 'DatabaseHelper');
    return null;
  }

  Future<List<TipModel>> getAllTips() async {
    final db = await database;
    final maps = await db.query('tips');
    final tips = maps
        .map((map) => TipModel.fromProto(map['data'] as List<int>))
        .toList();
    log('Retrieved ${tips.length} tips', name: 'DatabaseHelper');
    return tips;
  }

  Future<List<TipModel>> getTipsByCategory(String categoryId) async {
    final db = await database;
    final maps = await db.query(
      'tips',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    final tips = maps
        .map((map) => TipModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${tips.length} tips for category: $categoryId',
      name: 'DatabaseHelper',
    );
    return tips;
  }

  Future<void> deleteTip(String tipsId) async {
    final db = await database;
    final rows = await db.delete(
      'tips',
      where: 'tipsId = ?',
      whereArgs: [tipsId],
    );
    log('Deleted tip: $tipsId, rows affected: $rows', name: 'DatabaseHelper');
  }

  // UserModel CRUD
  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', {
      'userId': user.userId,
      'data': user.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted user: ${user.userId}', name: 'DatabaseHelper');
  }

  Future<UserModel?> getUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      log('Retrieved user: $userId', name: 'DatabaseHelper');
      return UserModel.fromProto(maps.first['data'] as List<int>);
    }
    log('User not found: $userId', name: 'DatabaseHelper');
    return null;
  }

  Future<void> deleteUser(String userId) async {
    final db = await database;
    final rows = await db.delete(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    log('Deleted user: $userId, rows affected: $rows', name: 'DatabaseHelper');
  }

  // UserPreferenceModel CRUD
  Future<void> insertUserPreference(UserPreferenceModel preference) async {
    final db = await database;
    await db.insert('user_preferences', {
      'userId': preference.userId,
      'data': preference.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log(
      'Inserted user preference: ${preference.userId}',
      name: 'DatabaseHelper',
    );
  }

  Future<UserPreferenceModel?> getUserPreference(String userId) async {
    final db = await database;
    final maps = await db.query(
      'user_preferences',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      log('Retrieved user preference: $userId', name: 'DatabaseHelper');
      return UserPreferenceModel.fromProto(maps.first['data'] as List<int>);
    }
    log('User preference not found: $userId', name: 'DatabaseHelper');
    return null;
  }

  Future<void> deleteUserPreference(String userId) async {
    final db = await database;
    final rows = await db.delete(
      'user_preferences',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    log(
      'Deleted user preference: $userId, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  // TransactionModel CRUD
  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert('transactions', {
      'id': transaction.id,
      'userId': transaction.userId,
      'data': transaction.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted transaction: ${transaction.id}', name: 'DatabaseHelper');
  }

  Future<TransactionModel?> getTransaction(String id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      log('Retrieved transaction: $id', name: 'DatabaseHelper');
      return TransactionModel.fromProto(maps.first['data'] as List<int>);
    }
    log('Transaction not found: $id', name: 'DatabaseHelper');
    return null;
  }

  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    final transactions = maps
        .map((map) => TransactionModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${transactions.length} transactions for user: $userId',
      name: 'DatabaseHelper',
    );
    return transactions;
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    final rows = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    log(
      'Deleted transaction: $id, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  // Pending Operations
  Future<void> insertPendingFavorite(FavoriteModel favorite) async {
    final db = await database;
    await db.insert('pending_operations', {
      'id': favorite.id,
      'type': 'favorite',
      'data': favorite.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted pending favorite: ${favorite.id}', name: 'DatabaseHelper');
  }

  Future<List<FavoriteModel>> getPendingFavorites() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['favorite'],
    );
    final favorites = maps
        .map((map) => FavoriteModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${favorites.length} pending favorites',
      name: 'DatabaseHelper',
    );
    return favorites;
  }

  Future<void> deletePendingFavorite(String id) async {
    final db = await database;
    final rows = await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'favorite'],
    );
    log(
      'Deleted pending favorite: $id, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  Future<void> insertPendingReminder(ReminderModel reminder) async {
    final db = await database;
    await db.insert('pending_operations', {
      'id': reminder.id,
      'type': 'reminder',
      'data': reminder.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log('Inserted pending reminder: ${reminder.id}', name: 'DatabaseHelper');
  }

  Future<List<ReminderModel>> getPendingReminders() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['reminder'],
    );
    final reminders = maps
        .map((map) => ReminderModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${reminders.length} pending reminders',
      name: 'DatabaseHelper',
    );
    return reminders;
  }

  Future<void> deletePendingReminder(String id) async {
    final db = await database;
    final rows = await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'reminder'],
    );
    log(
      'Deleted pending reminder: $id, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  Future<void> insertPendingNotification(NotificationModel notification) async {
    final db = await database;
    await db.insert('pending_operations', {
      'id': notification.id,
      'type': 'notification',
      'data': notification.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log(
      'Inserted pending notification: ${notification.id}',
      name: 'DatabaseHelper',
    );
  }

  Future<List<NotificationModel>> getPendingNotifications() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['notification'],
    );
    final notifications = maps
        .map((map) => NotificationModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${notifications.length} pending notifications',
      name: 'DatabaseHelper',
    );
    return notifications;
  }

  Future<void> deletePendingNotification(String id) async {
    final db = await database;
    final rows = await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'notification'],
    );
    log(
      'Deleted pending notification: $id, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  Future<void> insertPendingSubscription(SubscriptionModel subscription) async {
    final db = await database;
    await db.insert('pending_operations', {
      'id': subscription.userId,
      'type': 'subscription',
      'data': subscription.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log(
      'Inserted pending subscription: ${subscription.userId}',
      name: 'DatabaseHelper',
    );
  }

  Future<List<SubscriptionModel>> getPendingSubscriptions() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['subscription'],
    );
    final subscriptions = maps
        .map((map) => SubscriptionModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${subscriptions.length} pending subscriptions',
      name: 'DatabaseHelper',
    );
    return subscriptions;
  }

  Future<void> deletePendingSubscription(String id) async {
    final db = await database;
    final rows = await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'subscription'],
    );
    log(
      'Deleted pending subscription: $id, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  Future<void> insertPendingTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert('pending_operations', {
      'id': transaction.id,
      'type': 'transaction',
      'data': transaction.toProto(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    log(
      'Inserted pending transaction: ${transaction.id}',
      name: 'DatabaseHelper',
    );
  }

  Future<List<TransactionModel>> getPendingTransactions() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['transaction'],
    );
    final transactions = maps
        .map((map) => TransactionModel.fromProto(map['data'] as List<int>))
        .toList();
    log(
      'Retrieved ${transactions.length} pending transactions',
      name: 'DatabaseHelper',
    );
    return transactions;
  }

  Future<void> deletePendingTransaction(String id) async {
    final db = await database;
    final rows = await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'transaction'],
    );
    log(
      'Deleted pending transaction: $id, rows affected: $rows',
      name: 'DatabaseHelper',
    );
  }

  // Clear database
  Future<void> clearDatabase() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('categories');
    batch.delete('favorites');
    batch.delete('notifications');
    batch.delete('preferences');
    batch.delete('reminders');
    batch.delete('subscriptions');
    batch.delete('tips');
    batch.delete('users');
    batch.delete('user_preferences');
    batch.delete('transactions');
    batch.delete('pending_operations');
    batch.delete('cache');
    batch.delete('comments');
    batch.delete('queued_comments');
    batch.delete('queued_interactions');
    await batch.commit();
    log('Database cleared', name: 'DatabaseHelper');
  }

  Future<void> cleanupCorruptedFavorites() async {
    final db = await database;
    try {
      log('Starting favorites database cleanup', name: 'DatabaseHelper');

      // Get all favorites
      final List<Map<String, dynamic>> maps = await db.query('favorites');
      int fixed = 0;

      for (var map in maps) {
        try {
          // Try to parse the data
          FavoriteModel.fromProto(map['data'] as List<int>);
        } catch (e) {
          // If parsing fails, fix or delete the corrupted entry
          log('Found corrupted favorite with id: ${map['id']}', name: 'DatabaseHelper');

          try {
            // Get basic info
            final id = map['id'] as String;
            final userId = map['userId'] as String;

            // Create a new valid favorite
            final fixedFavorite = FavoriteModel(
              id: id,
              userId: userId,
              tipId: id.replaceAll('${userId}_', ''), // Extract tipId from ID format
              createdAt: DateTime.now(),
            );

            // Replace corrupted data
            await db.update(
                'favorites',
                {'data': fixedFavorite.toProto()},
                where: 'id = ?',
                whereArgs: [id]
            );

            fixed++;
            log('Fixed corrupted favorite: $id', name: 'DatabaseHelper');
          } catch (fixError) {
            // If we can't fix it, delete it
            await db.delete('favorites', where: 'id = ?', whereArgs: [map['id']]);
            log('Deleted unfixable corrupted favorite: ${map['id']}', name: 'DatabaseHelper');
          }
        }
      }

      log('Completed favorites database cleanup. Fixed: $fixed entries', name: 'DatabaseHelper');
    } catch (e) {
      log('Error during favorites cleanup: $e', name: 'DatabaseHelper');
    }
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      log('Database closed', name: 'DatabaseHelper');
    }
  }
}
