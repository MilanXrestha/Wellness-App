import 'package:flutter/material.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/core/services/data_repository.dart';
import 'dart:developer';

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
    } else {
      _canAccessPremium = false;
      _isLoading = false;
      notifyListeners();
      log('No user ID found during initialization', name: 'PremiumStatusProvider');
    }
  }

  Future<void> _refreshPremiumStatus(String userId) async {
    if (userId.isEmpty) {
      _canAccessPremium = false;
      _isLoading = false;
      notifyListeners();
      log('Empty user ID, setting premium status to false', name: 'PremiumStatusProvider');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch subscription data
      final subscription = await _dataRepository.getSubscription(userId);
      _canAccessPremium = subscription != null &&
          subscription.status == 'active' &&
          (subscription.endDate == null || subscription.endDate!.isAfter(DateTime.now()));
      log('Premium status refreshed for user $userId: $_canAccessPremium', name: 'PremiumStatusProvider');
    } catch (e) {
      log('Error checking premium status: $e', name: 'PremiumStatusProvider');
      _canAccessPremium = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePremiumStatus() async {
    final userId = _authService.getCurrentUser()?.uid ?? '';
    await _refreshPremiumStatus(userId);
  }

  void setPremiumStatus(bool status) {
    _canAccessPremium = status;
    _isLoading = false;
    notifyListeners();
    log('Premium status set for user ${_authService.getCurrentUser()?.uid ?? "unknown"}: $status', name: 'PremiumStatusProvider');
  }

  void resetPremiumStatus() {
    _canAccessPremium = false;
    _isLoading = false;
    notifyListeners();
    log('Premium status reset', name: 'PremiumStatusProvider');
  }
}