import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/core/config/firebase/firebase_options.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';
import 'package:wellness_app/features/auth/data/services/auth_service.dart';

class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();

  factory AppInitializer() => _instance;

  AppInitializer._internal();

  static AppInitializer get instance => _instance;

  // Cache the SharedPreferences instance
  SharedPreferences? _prefs;
  bool _isFirebaseInitialized = false;

  // Cache for route determination
  String? _cachedRoute;

  // Determine where to navigate based on app state
  Future<String> determineInitialRoute() async {
    // Return cached result if available
    if (_cachedRoute != null) {
      log('Navigation: Returning cached route: $_cachedRoute');
      return _cachedRoute!;
    }

    try {
      // Start Firebase initialization and onboarding check in parallel
      final prefsTask = _getSharedPreferences();
      final firebaseTask = _initializeFirebase();

      // First check if this is a first launch (doesn't need Firebase)
      final prefs = await prefsTask;
      final hasCompletedOnboarding =
          prefs.getBool('onboarding_completed') ?? false;
      if (!hasCompletedOnboarding) {
        final route = RoutesName.onboardScreen;
        log('Navigation: First launch, going to onboarding');
        _cachedRoute = route;
        return route;
      }

      // Wait for Firebase to be ready before checking auth
      await firebaseTask;

      // Now check authentication status
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        final route = RoutesName.loginScreen;
        log('Navigation: No user, going to login');
        _cachedRoute = route;
        return route;
      }

      // Then check session validity
      final lastLoginTimestamp = prefs.getInt('last_login_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const sessionThreshold = 7 * 24 * 60 * 60 * 1000;

      if (now - lastLoginTimestamp > sessionThreshold) {
        await FirebaseAuth.instance.signOut();
        final route = RoutesName.loginScreen;
        log('Navigation: Session expired, going to login');
        _cachedRoute = route;
        return route;
      }

      // Then check cached user data
      final cachedRole = prefs.getString('userRole');
      final cachedPreferenceCompleted = prefs.getBool('preferenceCompleted');

      if (cachedRole != null && cachedPreferenceCompleted != null) {
        String route;
        if (cachedRole == 'admin') {
          route = RoutesName.adminDashboardScreen;
          log('Navigation: Admin user, going to admin dashboard');
        } else {
          route = cachedPreferenceCompleted
              ? RoutesName.mainScreen
              : RoutesName.userPrefsScreen;
          log('Navigation: Regular user, going to $route');
        }
        _cachedRoute = route;
        return route;
      }

      // If no cached data, fetch from server
      try {
        final route = await AuthService()
            .getUserNavigationRoute(currentUser.uid)
            .timeout(
              const Duration(seconds: 2),
              onTimeout: () {
                log('Navigation: Server timeout, going to login');
                return RoutesName.loginScreen;
              },
            );

        log('Navigation: Server returned route: $route');
        _cachedRoute = route;
        return route;
      } catch (e) {
        final route = RoutesName.loginScreen;
        log('Navigation: Error getting route from server: $e');
        _cachedRoute = route;
        return route;
      }
    } catch (e) {
      final route = RoutesName.loginScreen;
      log('Navigation: General error in route determination: $e');
      _cachedRoute = route;
      return route;
    }
  }

  // Reset the cached route (useful if you need to force recalculation)
  void resetCachedRoute() {
    _cachedRoute = null;
  }

  // Get or initialize SharedPreferences
  Future<SharedPreferences> _getSharedPreferences() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Initialize Firebase if not already initialized
  Future<void> _initializeFirebase() async {
    if (_isFirebaseInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        log('Firebase initialized by AppInitializer');
      }
      _isFirebaseInitialized = true;
    } catch (e) {
      log('Firebase initialization error: $e');
      rethrow; // Re-throw to let caller handle it
    }
  }
}