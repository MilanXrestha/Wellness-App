import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/common/widgets/worm_indicator.dart';

import '../../../../core/config/routes/route_name.dart';
import '../../../../common/widgets/action_buttons.dart';
import '../../../../generated/app_localizations.dart';
import '../widgets/onboarding_content.dart';
import '../../data/models/onboarding_model.dart';

/// A screen that displays the onboarding flow to introduce app features to new users.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Controls page transitions within the onboarding flow.
  final PageController _pageController = PageController();

  /// Tracks the currently visible onboarding page index.
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Handles page index updates when the user swipes.
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  /// Marks onboarding as completed in persistent storage.
  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  /// Navigates to the next onboarding page or proceeds to the login screen if on the last page.
  void _nextPage() {
    if (_currentPage < onboardingData(context).length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _markOnboardingComplete();
      Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
    }
  }

  /// Skips the remaining onboarding steps and navigates directly to the login screen.
  void _skip() {
    _markOnboardingComplete();
    Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// Displays the onboarding pages.
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: onboardingData(context).length,
                itemBuilder: (context, index) {
                  return OnboardingContent(
                    model: onboardingData(context)[index],
                  );
                },
              ),
            ),

            /// Shows the current page indicator.
            WormIndicator(
              currentPage: _currentPage,
              pageCount: onboardingData(context).length,
            ),

            /// Action buttons for progressing or skipping onboarding.
            ActionButtons(
              onPrimary: _nextPage,
              onSecondary: _skip,
              primaryLabel: _currentPage == onboardingData(context).length - 1
                  ? l10n.startButton
                  : l10n.nextButton,
              secondaryLabel: l10n.skipButton,
              showSecondary: true,
              buttonType: 'elevated',
            ),

            /// Extra spacing at the bottom for layout balance.
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
