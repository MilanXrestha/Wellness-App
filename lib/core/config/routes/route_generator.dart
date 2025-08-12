import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:wellness_app/features/admin/presentation/add_category_screen.dart';
import 'package:wellness_app/features/admin/presentation/add_health_tips_screen.dart';
import 'package:wellness_app/features/admin/presentation/add_preference_screen.dart';
import 'package:wellness_app/features/admin/presentation/add_quote_screen.dart';
import 'package:wellness_app/features/admin/presentation/add_tips_screen.dart';
import 'package:wellness_app/features/admin/presentation/manage_categories_screen.dart';
import 'package:wellness_app/features/admin/presentation/manage_preferences_screen.dart';
import 'package:wellness_app/features/admin/presentation/manage_tips_screen.dart';
import 'package:wellness_app/features/admin/presentation/manage_users_screen.dart';
import 'package:wellness_app/features/admin/presentation/send_notification_screen.dart';
import 'package:wellness_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:wellness_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:wellness_app/features/auth/presentation/screens/login_screen.dart';
import 'package:wellness_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:wellness_app/features/categories/presentation/screens/category_detail_screen.dart';
import 'package:wellness_app/features/categories/presentation/screens/category_screen.dart';
import 'package:wellness_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:wellness_app/features/favorites/presentation/screens/favorite_screen.dart';
import 'package:wellness_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:wellness_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:wellness_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:wellness_app/features/preferences/presentation/screens/user_prefs.dart';
import 'package:wellness_app/features/tips/presentation/screens/tips_detail_screen.dart';
import 'package:wellness_app/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:wellness_app/features/subscription/presentation/screens/transaction_history_screen.dart';
import 'package:wellness_app/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/reminders/data/models/reminder_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';
import 'package:wellness_app/features/notifications/presentation/screens/notification_screen.dart';
import 'package:wellness_app/features/reminders/presentation/screens/reminder_history_screen.dart';
import 'package:wellness_app/features/reminders/presentation/screens/reminder_screen.dart';
import 'package:wellness_app/core/config/routes/route_name.dart';

import '../../../features/main/presentation/screens/main_screen.dart';
import '../../../features/onboarding/presentation/screens/onboarding_screen.dart';

class RouteConfig {
  RouteConfig._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? screenName = settings.name;
    final args = settings.arguments;

    switch (screenName) {
      case RoutesName.mainScreen:
      case RoutesName.dashboardScreen:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );

      case RoutesName.splashScreen:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case RoutesName.onboardScreen:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case RoutesName.exploreScreen:
        return MaterialPageRoute(
          builder: (_) => const ExploreScreen(),
          settings: settings,
        );

      case RoutesName.categoryScreen:
        if (args is CategoryModel?) {
          return MaterialPageRoute(
            builder: (_) => CategoryScreen(selectedCategory: args),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const CategoryScreen(),
          settings: settings,
        );

      case RoutesName.categoryDetailScreen:
        if (args is CategoryModel) {
          return MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(category: args),
            settings: settings,
          );
        }
        return _errorRoute('Invalid arguments for CategoryDetailScreen: $args');

      case RoutesName.favoritesScreen:
        return MaterialPageRoute(
          builder: (_) => const FavoriteScreen(),
          settings: settings,
        );

      case RoutesName.profileScreen:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case RoutesName.editProfileScreen:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );

      case RoutesName.loginScreen:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case RoutesName.signUpScreen:
        return MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
          settings: settings,
        );

      case RoutesName.forgotPasswordScreen:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );

      case RoutesName.changePasswordScreen:
        return MaterialPageRoute(
          builder: (_) => const ChangePasswordScreen(),
          settings: settings,
        );

      case RoutesName.subscriptionScreen:
        return MaterialPageRoute(
          builder: (_) => const SubscriptionScreen(),
          settings: settings,
        );

      case RoutesName.transactionHistoryScreen:
        return MaterialPageRoute(
          builder: (_) => const TransactionHistoryScreen(),
          settings: settings,
        );

      case RoutesName.userPrefsScreen:
        return MaterialPageRoute(
          builder: (_) => UserPreferenceScreen(
            fromProfile: args as bool? ?? false,
          ),
          settings: settings,
        );

      case RoutesName.tipsDetailScreen:
        if (args is Map<String, dynamic>) {
          try {
            List<TipModel>? featuredTips;
            if (args['featuredTips'] != null) {
              if (args['featuredTips'] is List<TipModel>) {
                featuredTips = args['featuredTips'] as List<TipModel>;
              } else if (args['featuredTips'] is List<dynamic>) {
                featuredTips = (args['featuredTips'] as List<dynamic>)
                    .whereType<TipModel>()
                    .toList();
                log(
                  'Warning: featuredTips was List<dynamic>, converted to List<TipModel>: ${featuredTips.map((t) => t.tipsTitle).toList()}',
                  name: 'RouteConfig',
                );
              } else {
                log(
                  'Error: featuredTips is invalid type: ${args['featuredTips'].runtimeType}',
                  name: 'RouteConfig',
                );
                featuredTips = [];
              }
            }

            return MaterialPageRoute(
              builder: (_) => TipsDetailScreen(
                tip: args['tip'] as TipModel?,
                categoryName: args['categoryName']?.toString() ?? '',
                userId: args['userId']?.toString() ?? '',
                featuredTips: featuredTips,
                allHealthTips: args['allHealthTips'] as bool? ?? false,
                allQuotes: args['allQuotes'] as bool? ?? false,
              ),
              settings: settings,
            );
          } catch (e, stackTrace) {
            log(
              'Error parsing TipsDetailScreen arguments: $e',
              name: 'RouteConfig',
              stackTrace: stackTrace,
            );
            return _errorRoute(
              'Invalid arguments format for TipsDetailScreen: $args',
            );
          }
        }
        return _errorRoute('Invalid arguments for TipsDetailScreen: $args');

      case RoutesName.adminDashboardScreen:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
          settings: settings,
        );

      case RoutesName.manageUserScreen:
        return MaterialPageRoute(
          builder: (_) => const ManageUsersScreen(),
          settings: settings,
        );

      case RoutesName.manageCategoryScreen:
        return MaterialPageRoute(
          builder: (_) => const ManageCategoriesScreen(),
          settings: settings,
        );

      case RoutesName.managePreferenceScreen:
        return MaterialPageRoute(
          builder: (_) => const ManagePreferencesScreen(),
          settings: settings,
        );

      case RoutesName.addPreferenceScreen:
        return MaterialPageRoute(
          builder: (_) => const AddPreferenceScreen(),
          settings: settings,
        );

      case RoutesName.addTipsScreen:
        return MaterialPageRoute(
          builder: (_) => const AddTipScreen(),
          settings: settings,
        );

      case RoutesName.manageTipsScreen:
        return MaterialPageRoute(
          builder: (_) => const ManageTipsScreen(),
          settings: settings,
        );

      case RoutesName.addCategoryScreen:
        return MaterialPageRoute(
          builder: (_) => const AddCategoryScreen(),
          settings: settings,
        );

      case RoutesName.addQuoteScreen:
        return MaterialPageRoute(
          builder: (_) => const AddQuoteScreen(),
          settings: settings,
        );

      case RoutesName.addHealthTipsScreen:
        return MaterialPageRoute(
          builder: (_) => const AddHealthTipsScreen(),
          settings: settings,
        );

      case RoutesName.notificationScreen:
        return MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
          settings: settings,
        );

      case RoutesName.reminderScreen:
        final args = settings.arguments as ReminderModel?;
        return MaterialPageRoute(
          builder: (_) => ReminderScreen(reminder: args),
          settings: settings,
        );

      case RoutesName.reminderHistoryScreen:
        return MaterialPageRoute(
          builder: (_) => const ReminderHistoryScreen(),
          settings: settings,
        );

      case RoutesName.sendNotificationScreen:
        final userIds = args is List<String>
            ? args
            : args is List<dynamic>
            ? args.cast<String>()
            : <String>[];
        return MaterialPageRoute(
          builder: (_) => SendNotificationScreen(selectedUserIds: userIds),
          settings: settings,
        );

      default:
        return _errorRoute('No route defined for $screenName');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(
            'Error: $message',
            style: const TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      ),
    );
  }
}