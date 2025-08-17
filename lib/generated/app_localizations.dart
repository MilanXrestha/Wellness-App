import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Title for the first onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Wellness'**
  String get onboardingTitle1;

  /// Description for the first onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Start a journey that’s all about you — your emotions, your pace, your wellbeing.'**
  String get onboardingDescription1;

  /// Title for the second onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Explore Features'**
  String get onboardingTitle2;

  /// Description for the second onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Reflect on your mood, set mindful goals, and discover daily wellness insights.'**
  String get onboardingDescription2;

  /// Title for the third onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Join the Community'**
  String get onboardingTitle3;

  /// Description for the third onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Connect, share, and grow with a community that cares.'**
  String get onboardingDescription3;

  /// Title for the fourth onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingTitle4;

  /// Description for the fourth onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Ready to take control of your wellbeing? Your tools, support, and space to grow are just one tap away.'**
  String get onboardingDescription4;

  /// Label for the next button in onboarding flow
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Label for the start button to begin using the app
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// Label for the skip button to bypass onboarding
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// Greeting message on the login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginWelcome;

  /// Subtitle text on the login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your wellness journey'**
  String get loginSubtitle;

  /// Hint text for the email input field
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get loginEmailHint;

  /// Hint text for the password input field
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// Error message for empty email field
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Error message for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// Error message for empty password field
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Error message for invalid password format
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long\nand include uppercase, lowercase, number, and special character'**
  String get invalidPassword;

  /// Label for the remember me checkbox
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// Label for forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// Label for the login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// Label for Google sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginGoogleButton;

  /// Success message for login
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

  /// Success message for Google sign-in
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In successful!'**
  String get googleSignInSuccess;

  /// Message for canceled Google sign-in
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In canceled'**
  String get googleSignInCanceled;

  /// Label for admin dashboard navigation
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get loginAdminDashboard;

  /// Prompt to navigate to sign-up screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginSignUpPrompt;

  /// Title for the exit app confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitAppTitle;

  /// Message for the exit app confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get exitAppMessage;

  /// Button text to cancel dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button text to confirm exit
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Text indicating alternate sign-in options
  ///
  /// In en, this message translates to:
  /// **'Or Continue with'**
  String get or;

  /// Greeting message on the sign-up screen
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get signUpWelcome;

  /// Subtitle text on the sign-up screen
  ///
  /// In en, this message translates to:
  /// **'Join us to start your wellness journey'**
  String get signUpSubtitle;

  /// Hint text for the name input field
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get signUpNameHint;

  /// Hint text for the confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get signUpConfirmPasswordHint;

  /// Error message for empty name field
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// Error message for invalid name format
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters long'**
  String get invalidName;

  /// Error message for empty confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required'**
  String get confirmPasswordRequired;

  /// Error message for non-matching passwords
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Label for the sign-up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// Label for Google sign-up button
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpGoogleButton;

  /// Success message for sign-up
  ///
  /// In en, this message translates to:
  /// **'Sign-up successful!'**
  String get signUpSuccess;

  /// Prompt to navigate to login screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signUpHaveAccount;

  /// Label for the sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// Link text to navigate to login screen
  ///
  /// In en, this message translates to:
  /// **'CREATE AN ACCOUNT'**
  String get signUpLoginLink;

  /// Error message when no user is found for a given email
  ///
  /// In en, this message translates to:
  /// **'No user found with this email.'**
  String get userNotFound;

  /// Error message for wrong password entry
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get wrongPassword;

  /// Error message when the user account is disabled
  ///
  /// In en, this message translates to:
  /// **'This user account has been disabled.'**
  String get userDisabled;

  /// Error message for account linked with different credentials
  ///
  /// In en, this message translates to:
  /// **'An account already exists with a different sign-in method.'**
  String get accountExistsWithDifferentCredential;

  /// Error message for invalid Google authentication credentials
  ///
  /// In en, this message translates to:
  /// **'Invalid Google credentials.'**
  String get invalidCredential;

  /// Generic error message for unexpected failures
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get genericError;

  /// Greeting with user's first name
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String hello(Object name);

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// Night greeting
  ///
  /// In en, this message translates to:
  /// **'Time to unwind'**
  String get goodNight;

  /// Default name for unauthenticated users
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get defaultUserName;

  /// Title for featured quotes section
  ///
  /// In en, this message translates to:
  /// **'Featured Quotes'**
  String get featuredQuotes;

  /// Text for setting a reminder
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @neverMissYourFavoriteQuotes.
  ///
  /// In en, this message translates to:
  /// **'Never miss your favorite quotes and tips'**
  String get neverMissYourFavoriteQuotes;

  /// Title for category section
  ///
  /// In en, this message translates to:
  /// **'Discover by Category'**
  String get discoverByCategory;

  /// Button text to view all items
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Message when no categories are available
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// Title for health tips section
  ///
  /// In en, this message translates to:
  /// **'Health Tips'**
  String get tipsRegardingHealth;

  /// Message when no health tips are available
  ///
  /// In en, this message translates to:
  /// **'No health tips available'**
  String get noHealthTipsAvailable;

  /// Title for preferences section
  ///
  /// In en, this message translates to:
  /// **'My Preferences'**
  String get yourPreferences;

  /// Button text to edit preferences
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Message when no preferences are available
  ///
  /// In en, this message translates to:
  /// **'No preferences available'**
  String get noPreferencesAvailable;

  /// Title for recently added quotes section
  ///
  /// In en, this message translates to:
  /// **'Recently Added Quotes'**
  String get recentlyAddedQuotes;

  /// Message when no quotes are available
  ///
  /// In en, this message translates to:
  /// **'No quotes available'**
  String get noQuotesAvailable;

  /// Title for add reminder dialog
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// Label for reminder type dropdown
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Label for category dropdown
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Label for frequency dropdown
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// Label for selected time
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String time(Object time);

  /// Button text to add reminder
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Success message for adding reminder
  ///
  /// In en, this message translates to:
  /// **'Reminder added successfully'**
  String get reminderAddedSuccessfully;

  /// Message when no content is available after filtering
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// Hint text for search input
  ///
  /// In en, this message translates to:
  /// **'Search content...'**
  String get searchContent;

  /// Tooltip for search icon
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Tooltip for filter icon
  ///
  /// In en, this message translates to:
  /// **'Filter Content'**
  String get filterContent;

  /// Title for filter dialog
  ///
  /// In en, this message translates to:
  /// **'Filter by Type'**
  String get filterByType;

  /// Label for selecting all content types
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Label for quote content type
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// Label for health tips content type
  ///
  /// In en, this message translates to:
  /// **'Health Tips'**
  String get healthTips;

  /// Text for clearing filters
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// Title for explore screen
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// Error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(Object message);

  /// Message when user has not set any reminders
  ///
  /// In en, this message translates to:
  /// **'No reminders have been set yet'**
  String get noRemindersSet;

  /// Message when there are no reminders for the current day
  ///
  /// In en, this message translates to:
  /// **'No reminders scheduled for today'**
  String get noRemindersToday;

  /// Message shown when data fails to load
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading data'**
  String get errorLoadingData;

  /// Button label to retry loading or fetching data
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Fallback message when no content or data is available
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @premiumAudio.
  ///
  /// In en, this message translates to:
  /// **'Premium Audio'**
  String get premiumAudio;

  /// No description provided for @premiumContent.
  ///
  /// In en, this message translates to:
  /// **'Premium Content'**
  String get premiumContent;

  /// No description provided for @subscribeToUnlockAudio.
  ///
  /// In en, this message translates to:
  /// **'Subscribe now to unlock this inspiring audio content!'**
  String get subscribeToUnlockAudio;

  /// No description provided for @unlockPremiumAudio.
  ///
  /// In en, this message translates to:
  /// **'Unlock this premium audio to inspire your day!'**
  String get unlockPremiumAudio;

  /// No description provided for @errorLoadingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error loading audio. Please try again.'**
  String get errorLoadingAudio;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @pleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in to add to favorites.'**
  String get pleaseLogIn;

  /// No description provided for @unlockPremiumBenefits.
  ///
  /// In en, this message translates to:
  /// **'Unlock exclusive benefits with a premium subscription!'**
  String get unlockPremiumBenefits;

  /// No description provided for @premiumAudioAccess.
  ///
  /// In en, this message translates to:
  /// **'Access to premium audio tracks'**
  String get premiumAudioAccess;

  /// No description provided for @exclusiveContent.
  ///
  /// In en, this message translates to:
  /// **'Exclusive wellness content'**
  String get exclusiveContent;

  /// No description provided for @offlineAccess.
  ///
  /// In en, this message translates to:
  /// **'Offline access to content'**
  String get offlineAccess;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @tracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracks;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
