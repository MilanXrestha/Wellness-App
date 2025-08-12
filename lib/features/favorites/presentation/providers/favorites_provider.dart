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
      developer.log('loadFavorites: Invalid userId (empty)');
      notifyListeners();
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      developer.log('loadFavorites: Fetching favorites for userId: $userId');
      _favorites = await DataRepository.instance.getFavorites(userId);
      developer.log('loadFavorites: Fetched ${_favorites.length} favorites for userId: $userId');
      _error = null;
    } catch (e) {
      developer.log('Error loading favorites for userId: $userId, error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFavorite(FavoriteModel favorite) async {
    if (favorite.userId.isEmpty) {
      developer.log('addFavorite: Invalid userId (empty)');
      throw Exception('Cannot add favorite with empty userId');
    }
    try {
      _isLoading = true;
      notifyListeners();
      await DataRepository.instance.addFavorite(favorite);
      _favorites.add(favorite);
      developer.log('addFavorite: Added favorite ${favorite.id} for userId: ${favorite.userId}');
      _error = null;
    } catch (e) {
      developer.log('Error adding favorite: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFavorite(String favoriteId) async {
    try {
      _isLoading = true;
      notifyListeners();
      await DataRepository.instance.deleteFavorite(favoriteId);
      _favorites.removeWhere((f) => f.id == favoriteId);
      developer.log('deleteFavorite: Deleted favorite $favoriteId');
      _error = null;
    } catch (e) {
      developer.log('Error deleting favorite: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}