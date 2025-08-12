import 'package:wellness_app/generated/app_localizations.dart';

/// Validation logic for authentication-related inputs.
class AuthValidator {
  static final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _passwordRegExp = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  /// Validates an email address.
  static String? validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.emailRequired;
    }
    if (!_emailRegExp.hasMatch(value)) {
      return l10n.invalidEmail;
    }
    return null;
  }

  /// Validates a password.
  static String? validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (!_passwordRegExp.hasMatch(value)) {
      return l10n.invalidPassword;
    }
    return null;
  }

  /// Validates a name.
  static String? validateName(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.nameRequired;
    }
    if (value.trim().length < 2) {
      return l10n.invalidName;
    }
    return null;
  }

  /// Validates confirm password matches password.
  static String? validateConfirmPassword(
    String? value,
    String password,
    AppLocalizations l10n,
  ) {
    if (value == null || value.isEmpty) {
      return l10n.confirmPasswordRequired;
    }
    if (value != password) {
      return l10n.passwordsDoNotMatch;
    }
    return null;
  }
}
