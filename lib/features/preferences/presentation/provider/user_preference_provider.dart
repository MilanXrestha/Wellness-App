import 'package:flutter/foundation.dart';
import 'package:wellness_app/features/preferences/data/models/user_preference_model.dart';
import 'package:wellness_app/features/preferences/data/services/preference_service.dart';
import 'dart:developer';

class UserPreferenceProvider with ChangeNotifier {
  UserPreferenceModel? _userPreferences;
  final PreferenceService _preferenceService = PreferenceService();
  bool _isLoading = false;
  bool _isRefreshing = false;

  UserPreferenceModel? get userPreferences => _userPreferences;
  bool get isLoading => _isLoading;

  Future<void> loadUserPreferences(String userId) async {
    if (userId.isEmpty || _isLoading) return;
    try {
      _isLoading = true;
      // Avoid notifying here to reduce rebuilds
      final preferences = await _preferenceService.getUserPreferences(userId);
      if (!arePreferencesEqual(_userPreferences, preferences)) {
        _userPreferences = preferences;
        _isLoading = false;
        notifyListeners(); // Notify only after data is loaded
      } else {
        _isLoading = false;
      }
    } catch (e) {
      log('Error loading preferences: $e', name: 'UserPreferenceProvider');
      _userPreferences = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateUserPreferences(UserPreferenceModel? preferences) {
    if (!arePreferencesEqual(_userPreferences, preferences)) {
      _userPreferences = preferences;
      notifyListeners();
    }
  }

  Future<void> refreshUserPreferences(String userId) async {
    if (userId.isEmpty || _isRefreshing) return;
    _isRefreshing = true;
    try {
      await loadUserPreferences(userId);
    } finally {
      _isRefreshing = false;
    }
  }

  bool arePreferencesEqual(UserPreferenceModel? a, UserPreferenceModel? b) {
    if (a == b) return true;
    if (a == null || b == null) return false;
    if (a.preferences.length != b.preferences.length) return false;
    for (int i = 0; i < a.preferences.length; i++) {
      if (a.preferences[i].preferenceId != b.preferences[i].preferenceId ||
          a.preferences[i].selectedAt != b.preferences[i].selectedAt) {
        return false;
      }
    }
    return true;
  }
}