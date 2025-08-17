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

  Map<String, dynamic> toJson() => {
    'user': user?.toJson(),
    'preferences': preferences.map((e) => e.toJson()).toList(),
    'userPreference': userPreference?.toJson(),
    'categories': categories.map((e) => e.toJson()).toList(),
    'tips': tips.map((e) => e.toJson()).toList(),
    'notifications': notifications.map((e) => e.toJson()).toList(),
    'reminders': reminders.map((e) => e.toJson()).toList(),
    'favorites': favorites.map((e) => e.toJson()).toList(),
    'subscription': subscription?.toJson(),
    'transactions': transactions.map((e) => e.toJson()).toList(),
  };

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    user: json['user'] != null
        ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
        : null,
    preferences: (json['preferences'] as List<dynamic>)
        .map((e) => PreferenceModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    userPreference: json['userPreference'] != null
        ? UserPreferenceModel.fromJson(
            json['userPreference'] as Map<String, dynamic>,
          )
        : null,
    categories: (json['categories'] as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    tips: (json['tips'] as List<dynamic>)
        .map((e) => TipModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    notifications: (json['notifications'] as List<dynamic>)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    reminders: (json['reminders'] as List<dynamic>)
        .map((e) => ReminderModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    favorites: (json['favorites'] as List<dynamic>)
        .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    subscription: json['subscription'] != null
        ? SubscriptionModel.fromJson(
            json['subscription'] as Map<String, dynamic>,
          )
        : null,
    transactions: (json['transactions'] as List<dynamic>)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
