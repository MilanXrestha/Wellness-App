import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wellness.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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

    // Users table
    await db.execute('''
      CREATE TABLE users (
        userId TEXT PRIMARY KEY,
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
  }

  // CategoryModel CRUD
  Future<void> insertCategory(CategoryModel category) async {
    final db = await database;
    await db.insert(
      'categories',
      {'categoryId': category.categoryId, 'data': category.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    if (maps.isNotEmpty) {
      return CategoryModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((map) => CategoryModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
  }

  // FavoriteModel CRUD
  Future<void> insertFavorite(FavoriteModel favorite) async {
    final db = await database;
    await db.insert(
      'favorites',
      {'id': favorite.id, 'userId': favorite.userId, 'data': favorite.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FavoriteModel?> getFavorite(String id) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return FavoriteModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<List<FavoriteModel>> getFavoritesByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => FavoriteModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deleteFavorite(String id) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // NotificationModel CRUD
  Future<void> insertNotification(NotificationModel notification) async {
    final db = await database;
    await db.insert(
      'notifications',
      {'id': notification.id, 'userId': notification.userId, 'data': notification.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<NotificationModel?> getNotification(String id) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return NotificationModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<List<NotificationModel>> getNotificationsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => NotificationModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deleteNotification(String id) async {
    final db = await database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // PreferenceModel CRUD
  Future<void> insertPreference(PreferenceModel preference) async {
    final db = await database;
    await db.insert(
      'preferences',
      {'preferenceId': preference.preferenceId, 'data': preference.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
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
      return PreferenceModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<List<PreferenceModel>> getAllPreferences() async {
    final db = await database;
    final maps = await db.query('preferences');
    return maps.map((map) => PreferenceModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deletePreference(String preferenceId) async {
    final db = await database;
    await db.delete(
      'preferences',
      where: 'preferenceId = ?',
      whereArgs: [preferenceId],
    );
  }

  // ReminderModel CRUD
  Future<void> insertReminder(ReminderModel reminder) async {
    final db = await database;
    await db.insert(
      'reminders',
      {'id': reminder.id, 'userId': reminder.userId, 'data': reminder.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ReminderModel?> getReminder(String id) async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ReminderModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<List<ReminderModel>> getRemindersByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'reminders',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => ReminderModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // SubscriptionModel CRUD
  Future<void> insertSubscription(SubscriptionModel subscription) async {
    final db = await database;
    await db.insert(
      'subscriptions',
      {'userId': subscription.userId, 'data': subscription.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
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
      return SubscriptionModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<void> deleteSubscription(String userId) async {
    final db = await database;
    await db.delete(
      'subscriptions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // TipModel CRUD
  Future<void> insertTip(TipModel tip) async {
    final db = await database;
    await db.insert(
      'tips',
      {'tipsId': tip.tipsId, 'categoryId': tip.categoryId, 'data': tip.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TipModel?> getTip(String tipsId) async {
    final db = await database;
    final maps = await db.query(
      'tips',
      where: 'tipsId = ?',
      whereArgs: [tipsId],
    );
    if (maps.isNotEmpty) {
      return TipModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<List<TipModel>> getAllTips() async {
    final db = await database;
    final maps = await db.query('tips');
    return maps.map((map) => TipModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<List<TipModel>> getTipsByCategory(String categoryId) async {
    final db = await database;
    final maps = await db.query(
      'tips',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    return maps.map((map) => TipModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deleteTip(String tipsId) async {
    final db = await database;
    await db.delete(
      'tips',
      where: 'tipsId = ?',
      whereArgs: [tipsId],
    );
  }

  // UserModel CRUD
  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      {'userId': user.userId, 'data': user.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // UserPreferenceModel CRUD
  Future<void> insertUserPreference(UserPreferenceModel preference) async {
    final db = await database;
    await db.insert(
      'user_preferences',
      {'userId': preference.userId, 'data': preference.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
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
      return UserPreferenceModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<void> deleteUserPreference(String userId) async {
    final db = await database;
    await db.delete(
      'user_preferences',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // TransactionModel CRUD
  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      {'id': transaction.id, 'userId': transaction.userId, 'data': transaction.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<TransactionModel?> getTransaction(String id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TransactionModel.fromProto(maps.first['data'] as List<int>);
    }
    return null;
  }

  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => TransactionModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Pending Operations
  Future<void> insertPendingFavorite(FavoriteModel favorite) async {
    final db = await database;
    await db.insert(
      'pending_operations',
      {'id': favorite.id, 'type': 'favorite', 'data': favorite.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FavoriteModel>> getPendingFavorites() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['favorite'],
    );
    return maps.map((map) => FavoriteModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deletePendingFavorite(String id) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'favorite'],
    );
  }

  Future<void> insertPendingReminder(ReminderModel reminder) async {
    final db = await database;
    await db.insert(
      'pending_operations',
      {'id': reminder.id, 'type': 'reminder', 'data': reminder.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReminderModel>> getPendingReminders() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['reminder'],
    );
    return maps.map((map) => ReminderModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deletePendingReminder(String id) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'reminder'],
    );
  }

  Future<void> insertPendingNotification(NotificationModel notification) async {
    final db = await database;
    await db.insert(
      'pending_operations',
      {'id': notification.id, 'type': 'notification', 'data': notification.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationModel>> getPendingNotifications() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['notification'],
    );
    return maps.map((map) => NotificationModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deletePendingNotification(String id) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'notification'],
    );
  }

  Future<void> insertPendingSubscription(SubscriptionModel subscription) async {
    final db = await database;
    await db.insert(
      'pending_operations',
      {'id': subscription.userId, 'type': 'subscription', 'data': subscription.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SubscriptionModel>> getPendingSubscriptions() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['subscription'],
    );
    return maps.map((map) => SubscriptionModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deletePendingSubscription(String id) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'subscription'],
    );
  }

  Future<void> insertPendingTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert(
      'pending_operations',
      {'id': transaction.id, 'type': 'transaction', 'data': transaction.toProto()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getPendingTransactions() async {
    final db = await database;
    final maps = await db.query(
      'pending_operations',
      where: 'type = ?',
      whereArgs: ['transaction'],
    );
    return maps.map((map) => TransactionModel.fromProto(map['data'] as List<int>)).toList();
  }

  Future<void> deletePendingTransaction(String id) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'id = ? AND type = ?',
      whereArgs: [id, 'transaction'],
    );
  }

  // Clear database
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('categories');
    await db.delete('favorites');
    await db.delete('notifications');
    await db.delete('preferences');
    await db.delete('reminders');
    await db.delete('subscriptions');
    await db.delete('tips');
    await db.delete('users');
    await db.delete('user_preferences');
    await db.delete('transactions');
    await db.delete('pending_operations');
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}