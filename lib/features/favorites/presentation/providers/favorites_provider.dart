import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../../data/models/favorite_model.dart';
import '../../../../core/services/data_repository.dart';

class FavoritesProvider with ChangeNotifier {
  List<FavoriteModel> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<FavoriteModel> get favorites => _favorites;

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

  Future<void> addFavorite(FavoriteModel favorite) async {
    if (favorite.userId.isEmpty) {
      developer.log(
        'addFavorite: Invalid userId (empty)',
        name: 'FavoritesProvider',
      );
      throw Exception('Cannot add favorite with empty userId');
    }
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
      await DataRepository.instance.addFavorite(favorite);
      _favorites.add(favorite);
      developer.log(
        'addFavorite: Added favorite ${favorite.id} for userId: ${favorite.userId}',
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
    if (!_favorites.any((f) => f.id == favoriteId)) {
      developer.log(
        'deleteFavorite: Favorite $favoriteId not found',
        name: 'FavoritesProvider',
      );
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      await DataRepository.instance.deleteFavorite(favoriteId);
      _favorites.removeWhere((f) => f.id == favoriteId);
      developer.log(
        'deleteFavorite: Deleted favorite $favoriteId',
        name: 'FavoritesProvider',
      );
      _error = null;
      notifyListeners();
    } catch (e) {
      developer.log('Error deleting favorite: $e', name: 'FavoritesProvider');
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(String tipId, String userId) {
    return _favorites.any((f) => f.tipId == tipId && f.userId == userId);
  }
}
