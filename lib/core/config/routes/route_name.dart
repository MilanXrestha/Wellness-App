/// A centralized class to define all named routes used in the application.
class RoutesName {
  // Private constructor to prevent instantiation.
  RoutesName._();

  // Core App Routes
  static const String mainScreen = '/';                           // Root navigation hub
  static const String splashScreen = '/splash';                  // Initial splash screen
  static const String onboardScreen = '/onboard-screen';         // Onboarding flow
  static const String dashboardScreen = '/dashboard-screen';     // Main user dashboard
  static const String exploreScreen = '/explore-screen';         // Explore Screen
  static const String categoryScreen = '/category-screen';       // Category Screen
  static const String categoryDetailScreen = '/category-detail-screen'; // Category Detail Screen
  static const String favoritesScreen = '/favorites-screen';     // Favorites screen
  static const String profileScreen = '/profile-screen';         // User profile screen.
  static const String editProfileScreen = '/edit-profile-screen'; // User profile edit screen

  static const String subscriptionScreen = '/subscription-screen';         // User profile screen
  static const String transactionHistoryScreen = '/transaction-history-screen';         // User profile screen

  // User Authentication & Profile
  static const String loginScreen = '/login-screen';             // Login screen
  static const String signUpScreen = '/sign-up-screen';          // Sign up / registration screen
  static const String forgotPasswordScreen = '/forget-password-screen'; // Forgot password screen
  static const String changePasswordScreen = '/change-password-screen'; // Change password screen
  static const String userPrefsScreen = '/user-prefs-screen';    // User preferences setup

  // Content Detail
  static const String tipsDetailScreen = '/tips-detail-screen';  // Detail view for a quote

  // Admin Panel Routes
  static const String adminDashboardScreen = '/admin-dashboard-screen'; // Admin dashboard
  static const String manageUserScreen = '/manage-user-screen'; // Manage User Screen
  static const String addPreferenceScreen = '/add-preference-screen';   // Add a new preference
  static const String managePreferenceScreen = '/manage-preference-screen'; // Manage Preference Screen
  static const String addCategoryScreen = '/add-category-screen';       // Add a new category
  static const String manageCategoryScreen = '/manage-category-screen'; // Manage Category Screen
  static const String addTipsScreen = '/add-Tips-screen';       // Add a new Tip
  static const String manageTipsScreen = '/manage-Tip-screen';  // Manage Tip Screen
  static const String addQuoteScreen = '/add-quote-screen';     // Add or edit a quote
  static const String addHealthTipsScreen = '/add-health-tips-screen'; // Add a health tip


  static const String notificationScreen = '/notification-screen';

  static const String reminderScreen = '/reminder-screen';
  static const String reminderHistoryScreen = '/reminder-history-screen';

  static const String sendNotificationScreen = '/send-notification-screen';
}