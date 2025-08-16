import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wellness_app/core/db/database_helper.dart';

import '../../common/utils/text_sanitizer.dart';

class CacheDataModel {
  final Map<String, dynamic> data;
  final bool hasCacheExpired;

  CacheDataModel({
    required this.data,
    required this.hasCacheExpired,
  });
}

class WellnessCacheService {
  static final WellnessCacheService _instance = WellnessCacheService._privateConstructor();

  factory WellnessCacheService() => _instance;

  final Duration memoryCacheTTL;
  final int? maxMemoryCacheSize;
  final int? maxDiskCacheSize;
  final DatabaseHelper _dbHelper;

  final Map<String, CacheDataModel> _memoryCache = {};
  final Map<String, DateTime> _memoryCacheTimestamps = {};
  final Lock _lock = Lock();
  int _cacheHitsMemory = 0;
  int _cacheHitsDisk = 0;
  int _cacheMisses = 0;

  WellnessCacheService._privateConstructor({
    this.memoryCacheTTL = const Duration(hours: 1),
    this.maxMemoryCacheSize = 100,
    this.maxDiskCacheSize = 500,
    DatabaseHelper? dbHelper,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> initCacheService() async {
    try {
      final db = await _dbHelper.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache (
          cacheKey TEXT PRIMARY KEY,
          data BLOB NOT NULL,
          expiryDate TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cache_expiry ON cache(expiryDate)',
      );
      developer.log('Cache service initialized successfully', name: 'WellnessCacheService');
    } catch (e, st) {
      developer.log(
          'Error initializing cache service: $e',
          name: 'WellnessCacheService',
          stackTrace: st);
      rethrow;
    }
  }

  Future<CacheDataModel> getCacheData({
    required String endpoint,
    required String? param,
    required bool hasInternet,
  }) async {
    try {
      final cacheKey = param != null ? '$endpoint:$param' : endpoint;

      // Check in-memory cache first
      if (_memoryCache.containsKey(cacheKey)) {
        final timestamp = _memoryCacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().toUtc().difference(timestamp) < memoryCacheTTL) {
          _cacheHitsMemory++;
          developer.log('Cache hit: Memory [$cacheKey]', name: 'WellnessCacheService');
          return _memoryCache[cacheKey]!;
        } else {
          _memoryCache.remove(cacheKey);
          _memoryCacheTimestamps.remove(cacheKey);
          developer.log('Memory cache expired for $cacheKey',
              name: 'WellnessCacheService');
        }
      }

      // Offline mode: Prioritize SQLite cache
      if (!hasInternet) {
        final db = await _dbHelper.database;
        final fullKey = _makeFullKey(endpoint, param);
        final maps = await db.query(
          'cache',
          where: 'cacheKey = ?',
          whereArgs: [fullKey],
        );

        if (maps.isNotEmpty) {
          final cachedData = maps.first;
          final jsonString = String.fromCharCodes(cachedData['data'] as List<int>);
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          final sanitizedData = TextSanitizer.sanitizeMap(data); // Sanitize retrieved data
          final cacheDataModel = CacheDataModel(
            data: sanitizedData,
            hasCacheExpired: false,
          );

          _memoryCache[cacheKey] = cacheDataModel;
          _memoryCacheTimestamps[cacheKey] = DateTime.now().toUtc();
          _evictMemoryCacheIfNeeded();

          _cacheHitsDisk++;
          developer.log('Cache hit: SQLite [$cacheKey] (offline mode)',
              name: 'WellnessCacheService');
          return cacheDataModel;
        }
        developer.log('Cache miss: [$cacheKey] (offline mode)',
            name: 'WellnessCacheService');
        _cacheMisses++;
        return CacheDataModel(data: {}, hasCacheExpired: true);
      }

      // Online mode: Check SQLite cache with expiration
      final db = await _dbHelper.database;
      final fullKey = _makeFullKey(endpoint, param);
      final maps = await db.query(
        'cache',
        where: 'cacheKey = ?',
        whereArgs: [fullKey],
      );

      if (maps.isNotEmpty) {
        final cachedData = maps.first;
        final expiryDate = DateTime.parse(cachedData['expiryDate'] as String).toUtc();
        final isExpired = _isExpired(expiryDate);

        if (!isExpired) {
          final jsonString = String.fromCharCodes(cachedData['data'] as List<int>);
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          final sanitizedData = TextSanitizer.sanitizeMap(data); // Sanitize retrieved data
          final cacheDataModel = CacheDataModel(
            data: sanitizedData,
            hasCacheExpired: false,
          );

          _memoryCache[cacheKey] = cacheDataModel;
          _memoryCacheTimestamps[cacheKey] = DateTime.now().toUtc();
          _evictMemoryCacheIfNeeded();

          _cacheHitsDisk++;
          developer.log('Cache hit: SQLite [$cacheKey]', name: 'WellnessCacheService');
          return cacheDataModel;
        } else {
          developer.log('SQLite cache expired for $cacheKey',
              name: 'WellnessCacheService');
        }
      }

      developer.log('Cache miss: [$cacheKey]', name: 'WellnessCacheService');
      _cacheMisses++;
      return CacheDataModel(data: {}, hasCacheExpired: true);
    } catch (e, st) {
      developer.log(
        'Cache retrieval error for $endpoint${param != null ? ':$param' : ''}: $e',
        name: 'WellnessCacheService',
        stackTrace: st,
      );
      _cacheMisses++;
      return CacheDataModel(data: {}, hasCacheExpired: true);
    }
  }

  Future<void> saveDataToCache({
    required String endpoint,
    required String? param,
    required Map<String, dynamic> data,
    required Duration cacheDuration,
    required bool isToRefresh,
  }) async {
    if (data.isEmpty) {
      developer.log(
        'Skipping cache save for empty data: $endpoint${param != null ? ':$param' : ''}',
        name: 'WellnessCacheService',
      );
      return;
    }

    await _lock.synchronized(() async {
      try {
        final fullKey = _makeFullKey(endpoint, param);
        final expiryDate = DateTime.now().toUtc().add(cacheDuration);
        final sanitizedData = TextSanitizer.sanitizeMap(data); // Sanitize before caching
        final jsonString = jsonEncode(sanitizedData);
        final dataBytes = utf8.encode(jsonString);
        final cacheKey = param != null ? '$endpoint:$param' : endpoint;

        _memoryCache[cacheKey] =
            CacheDataModel(data: sanitizedData, hasCacheExpired: false);
        _memoryCacheTimestamps[cacheKey] = DateTime.now().toUtc();
        _evictMemoryCacheIfNeeded();

        final db = await _dbHelper.database;
        await db.insert(
          'cache',
          {
            'cacheKey': fullKey,
            'data': dataBytes,
            'expiryDate': expiryDate.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await _evictDiskCacheIfNeeded();

        developer.log(
          'Saved data to cache: $cacheKey, expiry: $expiryDate',
          name: 'WellnessCacheService',
        );
      } catch (e, st) {
        developer.log(
          'Error saving data to cache for $endpoint${param != null ? ':$param' : ''}: $e',
          name: 'WellnessCacheService',
          stackTrace: st,
        );
        rethrow;
      }
    });
  }

  Future<void> clearCache() async {
    await _lock.synchronized(() async {
      try {
        _memoryCache.clear();
        _memoryCacheTimestamps.clear();
        final db = await _dbHelper.database;
        await db.delete('cache');
        developer.log('Cache cleared successfully', name: 'WellnessCacheService');
      } catch (e, st) {
        developer.log('Error clearing cache: $e', name: 'WellnessCacheService', stackTrace: st);
        rethrow;
      }
    });
  }

  String _makeFullKey(String endpoint, String? param) {
    return param != null ? '$endpoint:$param' : endpoint;
  }

  bool _isExpired(DateTime expiryDate) {
    return DateTime.now().toUtc().isAfter(expiryDate);
  }

  void _evictMemoryCacheIfNeeded() {
    if (_memoryCache.length > (maxMemoryCacheSize ?? double.infinity)) {
      final sortedKeys = _memoryCacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final keysToRemove = sortedKeys
          .sublist(0, (_memoryCache.length - (maxMemoryCacheSize! ~/ 2)).ceil());
      for (final entry in keysToRemove) {
        _memoryCache.remove(entry.key);
        _memoryCacheTimestamps.remove(entry.key);
      }
      developer.log(
        'Evicted ${keysToRemove.length} items from memory cache',
        name: 'WellnessCacheService',
      );
    }
  }

  Future<void> _evictDiskCacheIfNeeded() async {
    final db = await _dbHelper.database;
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM cache');
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count > (maxDiskCacheSize ?? double.infinity)) {
      final maps = await db.query(
        'cache',
        orderBy: 'expiryDate ASC',
        limit: count - (maxDiskCacheSize! ~/ 2),
      );

      final keysToRemove = maps.map((e) => e['cacheKey'] as String).toList();
      await db.delete(
        'cache',
        where: 'cacheKey IN (${keysToRemove.map((_) => '?').join(',')})',
        whereArgs: keysToRemove,
      );

      for (final key in keysToRemove) {
        _memoryCache.remove(key);
        _memoryCacheTimestamps.remove(key);
      }

      developer.log(
        'Evicted ${keysToRemove.length} items from disk cache',
        name: 'WellnessCacheService',
      );
    }

    final expiredMaps = await db.query(
      'cache',
      where: 'expiryDate < ?',
      whereArgs: [DateTime.now().toUtc().toIso8601String()],
    );

    if (expiredMaps.isNotEmpty) {
      final expiredKeys = expiredMaps.map((e) => e['cacheKey'] as String).toList();
      await db.delete(
        'cache',
        where: 'cacheKey IN (${expiredKeys.map((_) => '?').join(',')})',
        whereArgs: expiredKeys,
      );

      for (final key in expiredKeys) {
        _memoryCache.remove(key);
        _memoryCacheTimestamps.remove(key);
      }

      developer.log(
        'Evicted ${expiredKeys.length} expired items from disk cache',
        name: 'WellnessCacheService',
      );
    }
  }

  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCacheSize': _memoryCache.length,
      'cacheHitsMemory': _cacheHitsMemory,
      'cacheHitsDisk': _cacheHitsDisk,
      'cacheMisses': _cacheMisses,
    };
  }
}