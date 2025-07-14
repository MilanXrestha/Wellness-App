import 'package:flutter/material.dart';
import 'package:wellness_app/admin/add_category_screen.dart';
import 'package:wellness_app/admin/add_health_tips_screen.dart';
import 'package:wellness_app/admin/add_quote_screen.dart';
import 'package:wellness_app/admin/admin_dashboard_screen.dart';
import 'package:wellness_app/auth/change_password_screen.dart';
import 'package:wellness_app/core/route_config/route_config.dart';
import 'package:wellness_app/product/product_screen.dart';
import 'package:wellness_app/screens/dashboard_screen.dart';
import 'package:wellness_app/screens/user_prefs.dart';
import 'package:wellness_app/screens/profile_screen.dart';
import 'package:wellness_app/screens/quotes_detail_screen.dart';

import '../../auth/forgot_password_screen.dart';
import '../../auth/login_screen.dart';
import '../../auth/sign_up_screen.dart';

class RouteConfig {
  RouteConfig._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? screenName = settings.name;
    final dynamic arg = settings.arguments;

    switch (screenName) {
      case RoutesName.dashboardScreen:
        return MaterialPageRoute(
          builder: (_) =>
              DashboardScreen(dashboardViewModel: arg as DashboardViewModel),
        );
      case RoutesName.loginScreen:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case RoutesName.userPrefsScreen:
        return MaterialPageRoute(builder: (_) => UserPreferenceScreen());
      case RoutesName.signUpScreen:
        return MaterialPageRoute(builder: (_) => SignUpScreenScreen());
      case RoutesName.profileScreen:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case RoutesName.quotesDetailScreen:
        return MaterialPageRoute(builder: (_) => QuotesDetailScreen());

      case RoutesName.productScreen:
        return MaterialPageRoute(builder: (_) => ProductScreen());

      case RoutesName.forgotPasswordScreen:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());

      case RoutesName.changePasswordScreen:
        return MaterialPageRoute(builder: (_) => ChangePasswordScreen());

        // Admin Dashboard
      case RoutesName.adminDashboardScreen:
        return MaterialPageRoute(builder: (_) => AdminDashboardScreen());

      case RoutesName.addCategoryScreen:
        return MaterialPageRoute(builder: (_) => AddCategoryScreen());

      case RoutesName.addQuoteScreen:
        return MaterialPageRoute(builder: (_) => AddQuoteScreen());

      case RoutesName.addHealthTipsScreen:
        return MaterialPageRoute(builder: (_) => AddHealthTipsScreen());


      case RoutesName.defaultScreen:
      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}
