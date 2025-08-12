import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/favorites/data/models/favorite_model.dart';
import 'package:wellness_app/features/notifications/data/models/notification_model.dart';
import 'package:wellness_app/features/preferences/data/models/preference_model.dart';
import 'package:wellness_app/features/preferences/data/models/user_preference_model.dart';
import 'package:wellness_app/features/profile/data/user_model.dart';
import 'package:wellness_app/features/reminders/data/models/reminder_model.dart';
import 'package:wellness_app/features/subscription/data/models/subscription_model.dart';
import 'package:wellness_app/features/subscription/data/models/transaction_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';

class DashboardData {
  final UserModel? user;
  final List<PreferenceModel> preferences;
  final UserPreferenceModel? userPreference;
  final List<CategoryModel> categories;
  final List<TipModel> tips;
  final List<NotificationModel> notifications;
  final List<ReminderModel> reminders;
  final List<FavoriteModel> favorites;
  final SubscriptionModel? subscription;
  final List<TransactionModel> transactions;

  DashboardData({
    required this.user,
    required this.preferences,
    required this.userPreference,
    required this.categories,
    required this.tips,
    required this.notifications,
    required this.reminders,
    required this.favorites,
    required this.subscription,
    required this.transactions,
  });
}
