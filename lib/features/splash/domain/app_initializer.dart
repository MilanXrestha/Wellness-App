import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/config/firebase/firebase_options.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';
import 'package:wellness_app/features/dashboard/data/repositories/dashboard_repository.dart';

class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();

  factory AppInitializer() => _instance;

  AppInitializer._internal();

  static AppInitializer get instance => _instance;

  SharedPreferences? _prefs;
  bool _isFirebaseInitialized = false;
  String? _cachedRoute;
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  // Update connectivity status dynamically
  Future<void> updateConnectivityStatus() async {
    try {
      _isOffline = await DashboardRepository.instance.isOffline();
      log('Device is ${_isOffline ? 'offline' : 'online'}', name: 'AppInitializer');
    } catch (e) {
      _isOffline = false; // Default to online if check fails
      log('Error checking connectivity: $e', name: 'AppInitializer');
    }
  }

  Future<String> determineInitialRoute() async {
    if (_cachedRoute != null) {
      log('Navigation: Returning cached route: $_cachedRoute', name: 'AppInitializer');
      return _cachedRoute!;
    }

    try {
      // Check connectivity
      await updateConnectivityStatus();

      final prefsTask = _getSharedPreferences();
      final firebaseTask = _initializeFirebase();
      final prefs = await prefsTask;
      final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
      if (!hasCompletedOnboarding) {
        final route = RoutesName.onboardScreen;
        log('Navigation: First launch, going to onboarding', name: 'AppInitializer');
        _cachedRoute = route;
        return route;
      }

      await firebaseTask;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        final route = RoutesName.loginScreen;
        log('Navigation: No user, going to login', name: 'AppInitializer');
        _cachedRoute = route;
        return route;
      }

      final lastLoginTimestamp = prefs.getInt('last_login_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const sessionThreshold = 7 * 24 * 60 * 60 * 1000;

      if (now - lastLoginTimestamp > sessionThreshold) {
        await FirebaseAuth.instance.signOut();
        final route = RoutesName.loginScreen;
        log('Navigation: Session expired, going to login', name: 'AppInitializer');
        _cachedRoute = route;
        return route;
      }

      final cachedRole = prefs.getString('userRole');
      final cachedPreferenceCompleted = prefs.getBool('preferenceCompleted');

      if (cachedRole != null && cachedPreferenceCompleted != null) {
        String route;
        if (cachedRole == 'admin') {
          route = RoutesName.adminDashboardScreen;
          log('Navigation: Admin user, going to admin dashboard', name: 'AppInitializer');
        } else {
          route = cachedPreferenceCompleted
              ? RoutesName.mainScreen
              : RoutesName.userPrefsScreen;
          log('Navigation: Regular user, going to $route (preferenceCompleted: $cachedPreferenceCompleted)', name: 'AppInitializer');
        }
        _cachedRoute = route;
        return route;
      }

      if (!_isOffline) {
        try {
          final route = await AuthService().getUserNavigationRoute(currentUser.uid).timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              log('Navigation: Server timeout, going to login', name: 'AppInitializer');
              return RoutesName.loginScreen;
            },
          );
          log('Navigation: Server returned route: $route', name: 'AppInitializer');
          _cachedRoute = route;
          return route;
        } catch (e) {
          final route = RoutesName.loginScreen;
          log('Navigation: Error getting route from server: $e', name: 'AppInitializer');
          _cachedRoute = route;
          return route;
        }
      } else {
        final route = RoutesName.mainScreen;
        log('Navigation: Offline mode with no cached data, going to main screen', name: 'AppInitializer');
        _cachedRoute = route;
        return route;
      }
    } catch (e) {
      final route = RoutesName.loginScreen;
      log('Navigation: General error in route determination: $e', name: 'AppInitializer');
      _cachedRoute = route;
      return route;
    }
  }

  void resetCachedRoute() {
    _cachedRoute = null;
  }

  Future<SharedPreferences> _getSharedPreferences() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _initializeFirebase() async {
    if (_isFirebaseInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        log('Firebase initialized by AppInitializer', name: 'AppInitializer');
      }
      _isFirebaseInitialized = true;
    } catch (e) {
      log('Firebase initialization error: $e', name: 'AppInitializer');
      rethrow;
    }
  }
}