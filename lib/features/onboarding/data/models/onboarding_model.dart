import 'package:flutter/cupertino.dart';

import '../../../../generated/app_localizations.dart';

/// Represents the data model for a single onboarding screen.
///
/// Contains the path to the Lottie animation asset, the localized title,
/// and the localized description text.
class OnboardingModel {
  /// Path to the Lottie animation asset for the onboarding screen.
  final String lottieAsset;

  /// Title text displayed on the onboarding screen.
  final String title;

  /// Description text displayed on the onboarding screen.
  final String description;

  /// Creates an [OnboardingModel] with required animation asset, title, and description.
  OnboardingModel({
    required this.lottieAsset,
    required this.title,
    required this.description,
  });
}

/// Returns a list of onboarding screens' data using localized strings.
///
/// The list contains [OnboardingModel] instances representing each page
/// of the onboarding flow, with localized titles and descriptions.
List<OnboardingModel> onboardingData(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return [
    OnboardingModel(
      lottieAsset: 'assets/animations/welcome.json',
      title: l10n.onboardingTitle1,
      description: l10n.onboardingDescription1,
    ),
    OnboardingModel(
      lottieAsset: 'assets/animations/meditation.json',
      title: l10n.onboardingTitle2,
      description: l10n.onboardingDescription2,
    ),
    OnboardingModel(
      lottieAsset: 'assets/animations/share.json',
      title: l10n.onboardingTitle3,
      description: l10n.onboardingDescription3,
    ),
    OnboardingModel(
      lottieAsset: 'assets/animations/rocket.json',
      title: l10n.onboardingTitle4,
      description: l10n.onboardingDescription4,
    ),
  ];
}