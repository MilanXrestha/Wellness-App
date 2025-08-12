import 'package:flutter/material.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';

import '../../../../core/services/data_repository.dart';

class PremiumStatusProvider with ChangeNotifier {
  final DataRepository _dataRepository = DataRepository.instance;
  final AuthService _authService = AuthService();
  bool _canAccessPremium = false;
  bool _isLoading = false;

  bool get canAccessPremium => _canAccessPremium;
  bool get isLoading => _isLoading;

  PremiumStatusProvider() {
    _init();
  }

  Future<void> _init() async {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    if (userId.isNotEmpty) {
      await _refreshPremiumStatus(userId);
    }
  }

  Future<void> _refreshPremiumStatus(String userId) async {
    if (userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      _canAccessPremium = await _dataRepository.canAccessPremiumContent(userId);
    } catch (e) {
      _canAccessPremium = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePremiumStatus() async {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    if (userId.isNotEmpty) {
      await _refreshPremiumStatus(userId);
    }
  }
}