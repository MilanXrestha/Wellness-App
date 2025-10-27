import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../../data/models/favorite_model.dart';
import '../../../../core/services/data_repository.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';

class FavoritesProvider with ChangeNotifier {
  List<FavoriteModel> _favorites = [];
  final Map<String, TipModel> _tipCache = {}; // Cache for tip data
  bool _isLoading = false;
  String? _error;

  List<FavoriteModel> get favorites => _favorites;
  Map<String, TipModel> get tipCache => _tipCache; // Expose cache

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> loadFavorites(String userId) async {
    if (userId.isEmpty) {
      _error = 'Invalid user ID';
      developer.log(
        'loadFavorites: Invalid userId (empty)',
        name: 'FavoritesProvider',
      );
      notifyListeners();
      return;
    }
    if (_isLoading) {
      developer.log(
        'loadFavorites: Already loading, skipping for userId: $userId',
        name: 'FavoritesProvider',
      );
      return;
    }
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      developer.log(
        'loadFavorites: Fetching favorites for userId: $userId',
        name: 'FavoritesProvider',
      );

      final newFavorites = await DataRepository.instance.getFavorites(userId);

      if (!listEquals(_favorites, newFavorites)) {
        _favorites = newFavorites;
        developer.log(
          'loadFavorites: Fetched ${_favorites.length} favorites for userId: $userId',
          name: 'FavoritesProvider',
        );

        // Load tip data for each favorite
        await _loadTipsForFavorites();

        notifyListeners();
      } else {
        developer.log(
          'loadFavorites: No changes in favorites for userId: $userId',
          name: 'FavoritesProvider',
        );
      }
    } catch (e) {
      developer.log(
        'Error loading favorites for userId: $userId, error: $e',
        name: 'FavoritesProvider',
      );
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to load tips for favorites
  Future<void> _loadTipsForFavorites() async {
    for (var favorite in _favorites) {
      if (!_tipCache.containsKey(favorite.tipId)) {
        try {
          final tip = await DataRepository.instance.getTip(favorite.tipId);
          if (tip != null) {
            _tipCache[favorite.tipId] = tip;
          }
        } catch (e) {
          developer.log(
            'Error loading tip ${favorite.tipId}: $e',
            name: 'FavoritesProvider',
          );
        }
      }
    }
  }

  Future<void> addFavorite(FavoriteModel favorite, TipModel tip) async {
    if (favorite.userId.isEmpty) {
      developer.log(
        'addFavorite: Invalid userId (empty)',
        name: 'FavoritesProvider',
      );
      throw Exception('Cannot add favorite with empty userId');
    }

    // Check if already exists in memory
    if (_favorites.any((f) => f.id == favorite.id)) {
      developer.log(
        'addFavorite: Favorite ${favorite.id} already exists for userId: ${favorite.userId}',
        name: 'FavoritesProvider',
      );
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Check network status before operation
      final isOnline = await DataRepository.instance.isOnline();
      developer.log(
        'addFavorite: Network status - ${isOnline ? "Online" : "Offline"}',
        name: 'FavoritesProvider',
      );

      // Add to repository (handles both online and offline cases)
      await DataRepository.instance.addFavorite(favorite);

      // IMPORTANT: Always update local state regardless of network status
      _favorites.add(favorite);

      // Add tip to cache immediately
      _tipCache[favorite.tipId] = tip;

      developer.log(
        'addFavorite: Added favorite ${favorite.id} for userId: ${favorite.userId} ${isOnline ? "(online)" : "(offline)"}',
        name: 'FavoritesProvider',
      );

      _error = null;
      notifyListeners();
    } catch (e) {
      developer.log('Error adding favorite: $e', name: 'FavoritesProvider');
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFavorite(String favoriteId) async {
    // Find the favorite in our local state
    final favoriteIndex = _favorites.indexWhere((f) => f.id == favoriteId);

    if (favoriteIndex == -1) {
      developer.log(
        'deleteFavorite: Favorite $favoriteId not found',
        name: 'FavoritesProvider',
      );
      return;
    }

    // Keep a backup of the favorite for error recovery
    final deletedFavorite = _favorites[favoriteIndex];

    try {
      _isLoading = true;
      notifyListeners();

      // Check network status before operation
      final isOnline = await DataRepository.instance.isOnline();
      developer.log(
        'deleteFavorite: Network status - ${isOnline ? "Online" : "Offline"}',
        name: 'FavoritesProvider',
      );

      // Remove from repository
      await DataRepository.instance.deleteFavorite(favoriteId);

      // IMPORTANT: Always update local state regardless of network status
      _favorites.removeAt(favoriteIndex);

      developer.log(
        'deleteFavorite: Deleted favorite $favoriteId ${isOnline ? "(online)" : "(offline)"}',
        name: 'FavoritesProvider',
      );

      _error = null;
      notifyListeners();
    } catch (e) {
      developer.log('Error deleting favorite: $e', name: 'FavoritesProvider');

      // Restore the deleted favorite in case of error
      if (!_favorites.any((f) => f.id == favoriteId)) {
        _favorites.insert(favoriteIndex, deletedFavorite);
      }

      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get all favorite tips (returns loaded tip models from cache)
  List<TipModel> getFavoriteTips() {
    final result = <TipModel>[];
    for (var favorite in _favorites) {
      if (_tipCache.containsKey(favorite.tipId)) {
        result.add(_tipCache[favorite.tipId]!);
      }
    }
    return result;
  }

  bool isFavorite(String tipId, String userId) {
    return _favorites.any((f) => f.tipId == tipId && f.userId == userId);
  }

  // Helper method to refresh favorites after network reconnection
  Future<void> syncFavorites(String userId) async {
    if (userId.isEmpty) return;

    try {
      // First sync any pending operations to ensure local favorites are pushed to Firestore
      await DataRepository.instance.syncPendingOperations();

      // Then refresh the list
      await loadFavorites(userId);

      developer.log(
        'Favorites synced successfully for user: $userId',
        name: 'FavoritesProvider',
      );
    } catch (e) {
      developer.log(
        'Error syncing favorites: $e',
        name: 'FavoritesProvider',
      );
    }
  }


}