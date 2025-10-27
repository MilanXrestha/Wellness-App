import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import '../../../../core/config/routes/route_name.dart';
import '../../../favorites/data/models/favorite_model.dart';
import '../../data/models/tips_model.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../../core/services/data_repository.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

class TipsService {
  final AuthService _authService = AuthService();
  final DataRepository _dataRepository = DataRepository.instance;

  Future<List<TipModel>> fetchTipsInCategory(String categoryId) async {
    try {
      final tips = await _dataRepository.getTipsByCategory(categoryId);
      dev.log('Fetched ${tips.length} tips for category $categoryId');
      return tips;
    } catch (e) {
      dev.log('Error fetching tips: $e');
      rethrow;
    }
  }

  Future<List<TipModel>> fetchAllHealthTips() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tips')
          .where('tipsType', isEqualTo: 'healthTips')
          .get();
      final tips = snapshot.docs
          .map((doc) => TipModel.fromFirestore(doc.data(), doc.id))
          .toList();
      dev.log('Fetched ${tips.length} health tips');
      return tips;
    } catch (e) {
      dev.log('Error fetching health tips: $e');
      rethrow;
    }
  }

  Future<List<TipModel>> fetchAllQuotes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tips')
          .where('tipsType', isEqualTo: 'quote')
          .get();
      final tips = snapshot.docs
          .map((doc) => TipModel.fromFirestore(doc.data(), doc.id))
          .toList();
      dev.log('Fetched ${tips.length} quotes');
      return tips;
    } catch (e) {
      dev.log('Error fetching quotes: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(
    String userId,
    String tipId,
    FavoritesProvider provider,
    bool wasFavorite,
  ) async {
    try {
      if (!wasFavorite) {
        // Create favorite model
        final favorite = FavoriteModel(
          id: const Uuid().v4(),
          userId: userId,
          tipId: tipId,
          createdAt: DateTime.now(),
        );

        // Fetch the tip model first - we need this for the updated provider
        final tip = await _dataRepository.getTip(tipId);

        if (tip == null) {
          dev.log('Could not find tip with ID $tipId');
          throw Exception('Tip not found');
        }

        // Pass both the favorite model and tip model to addFavorite
        await provider.addFavorite(favorite, tip);
        dev.log('Added favorite: ${favorite.id} for user $userId, tip $tipId');
      } else {
        final favorite = provider.favorites.firstWhere(
          (f) => f.tipId == tipId && f.userId == userId,
          orElse: () => FavoriteModel(id: '', tipId: tipId, userId: userId),
        );

        if (favorite.id.isEmpty) {
          dev.log('Could not find favorite for tip $tipId');
          return;
        }

        await provider.deleteFavorite(favorite.id);
        dev.log(
          'Removed favorite: ${favorite.id} for user $userId, tip $tipId',
        );
      }
    } catch (e) {
      dev.log('Error updating favorite for user $userId, tip $tipId: $e');
      rethrow;
    }
  }

  Future<bool> checkUserAuthentication(BuildContext context) async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      dev.log('No authenticated user found, redirecting to login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add favorites')),
      );
      Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
      return false;
    }
    return true;
  }
}
