// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardingTitle1 => 'Welcome to Wellness';

  @override
  String get onboardingDescription1 =>
      'Start a journey that’s all about you — your emotions, your pace, your wellbeing.';

  @override
  String get onboardingTitle2 => 'Explore Features';

  @override
  String get onboardingDescription2 =>
      'Reflect on your mood, set mindful goals, and discover daily wellness insights.';

  @override
  String get onboardingTitle3 => 'Join the Community';

  @override
  String get onboardingDescription3 =>
      'Connect, share, and grow with a community that cares.';

  @override
  String get onboardingTitle4 => 'Get Started';

  @override
  String get onboardingDescription4 =>
      'Ready to take control of your wellbeing? Your tools, support, and space to grow are just one tap away.';

  @override
  String get nextButton => 'Next';

  @override
  String get startButton => 'Start';

  @override
  String get skipButton => 'Skip';

  @override
  String get loginWelcome => 'Welcome back!';

  @override
  String get loginSubtitle => 'Sign in to continue your wellness journey';

  @override
  String get loginEmailHint => 'Enter your email';

  @override
  String get loginPasswordHint => 'Enter your password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get invalidPassword =>
      'Password must be at least 8 characters long\nand include uppercase, lowercase, number, and special character';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginButton => 'Login';

  @override
  String get loginGoogleButton => 'Sign in with Google';

  @override
  String get loginSuccess => 'Login successful!';

  @override
  String get googleSignInSuccess => 'Google Sign-In successful!';

  @override
  String get googleSignInCanceled => 'Google Sign-In canceled';

  @override
  String get loginAdminDashboard => 'Admin Dashboard';

  @override
  String get loginSignUpPrompt => 'Don\'t have an account?';

  @override
  String get exitAppTitle => 'Exit App';

  @override
  String get exitAppMessage => 'Are you sure you want to exit?';

  @override
  String get cancel => 'Cancel';

  @override
  String get exit => 'Exit';

  @override
  String get or => 'Or Continue with';

  @override
  String get signUpWelcome => 'Create an account';

  @override
  String get signUpSubtitle => 'Join us to start your wellness journey';

  @override
  String get signUpNameHint => 'Enter your name';

  @override
  String get signUpConfirmPasswordHint => 'Confirm your password';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get invalidName => 'Name must be at least 2 characters long';

  @override
  String get confirmPasswordRequired => 'Confirm password is required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get signUpGoogleButton => 'Sign up with Google';

  @override
  String get signUpSuccess => 'Sign-up successful!';

  @override
  String get signUpHaveAccount => 'Already have an account?';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signUpLoginLink => 'CREATE AN ACCOUNT';

  @override
  String get userNotFound => 'No user found with this email.';

  @override
  String get wrongPassword => 'Incorrect password.';

  @override
  String get userDisabled => 'This user account has been disabled.';

  @override
  String get accountExistsWithDifferentCredential =>
      'An account already exists with a different sign-in method.';

  @override
  String get invalidCredential => 'Invalid Google credentials.';

  @override
  String get genericError => 'An unexpected error occurred. Please try again.';

  @override
  String hello(Object name) {
    return 'Hello, $name';
  }

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get goodNight => 'Time to unwind';

  @override
  String get defaultUserName => 'Guest';

  @override
  String get featuredQuotes => 'Featured Quotes';

  @override
  String get setReminder => 'Set Reminder';

  @override
  String get neverMissYourFavoriteQuotes =>
      'Never miss your favorite quotes and tips';

  @override
  String get discoverByCategory => 'Discover by Category';

  @override
  String get viewAll => 'View All';

  @override
  String get noCategoriesAvailable => 'No categories available';

  @override
  String get tipsRegardingHealth => 'Health Tips';

  @override
  String get noHealthTipsAvailable => 'No health tips available';

  @override
  String get yourPreferences => 'My Preferences';

  @override
  String get edit => 'Edit';

  @override
  String get noPreferencesAvailable => 'No preferences available';

  @override
  String get recentlyAddedQuotes => 'Recently Added Quotes';

  @override
  String get noQuotesAvailable => 'No quotes available';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get type => 'Type';

  @override
  String get category => 'Category';

  @override
  String get frequency => 'Frequency';

  @override
  String time(Object time) {
    return 'Time: $time';
  }

  @override
  String get add => 'Add';

  @override
  String get reminderAddedSuccessfully => 'Reminder added successfully';

  @override
  String get noContentAvailable => 'No content available';

  @override
  String get searchContent => 'Search content...';

  @override
  String get search => 'Search';

  @override
  String get filterContent => 'Filter Content';

  @override
  String get filterByType => 'Filter by Type';

  @override
  String get all => 'All';

  @override
  String get quote => 'Quote';

  @override
  String get healthTips => 'Health Tips';

  @override
  String get clearFilter => 'Clear Filter';

  @override
  String get explore => 'Explore';

  @override
  String error(Object message) {
    return 'Error: $message';
  }

  @override
  String get noRemindersSet => 'No reminders have been set yet';

  @override
  String get noRemindersToday => 'No reminders scheduled for today';

  @override
  String get errorLoadingData => 'An error occurred while loading data';

  @override
  String get retry => 'Retry';

  @override
  String get noDataAvailable => 'No data available';
}
