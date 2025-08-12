import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/resources/colors.dart';
import '../../generated/app_localizations.dart';

/// A reusable widget for displaying configurable primary and secondary action buttons.
///
/// Supports different button styles (`elevated`, `outlined`, or `text`), optional
/// localization-based labels, and customizable callbacks for each action.
class ActionButtons extends StatelessWidget {
  /// Callback for the primary action button (e.g., Next, Start, Submit).
  final VoidCallback? onPrimary;

  /// Callback for the secondary action button (e.g., Skip, Cancel).
  final VoidCallback? onSecondary;

  /// Text label for the primary action button.
  final String? primaryLabel;

  /// Text label for the secondary action button.
  final String? secondaryLabel;

  /// Whether the secondary button should be shown.
  final bool showSecondary;

  /// The style of the primary button: `'elevated'`, `'outlined'`, or `'text'`.
  final String buttonType;

  /// Creates an [ActionButtons] widget.
  const ActionButtons({
    super.key,
    required this.onPrimary,
    this.onSecondary,
    this.primaryLabel,
    this.secondaryLabel,
    this.showSecondary = true,
    this.buttonType = 'elevated',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Use provided labels or fallback to localized defaults.
    final effectivePrimaryLabel =
        primaryLabel ??
        (buttonType == 'elevated' && primaryLabel == null
            ? l10n.startButton
            : l10n.nextButton);
    final effectiveSecondaryLabel = secondaryLabel ?? l10n.skipButton;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Secondary button (e.g., Skip, Cancel)
          if (showSecondary && onSecondary != null)
            TextButton(
              onPressed: onSecondary,
              child: Text(
                effectiveSecondaryLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            )
          else
            const SizedBox.shrink(), // Keeps spacing consistent if hidden
          // Primary button (varies based on [buttonType])
          if (buttonType == 'elevated')
            ElevatedButton(
              onPressed: onPrimary,
              style: theme.elevatedButtonTheme.style?.copyWith(
                backgroundColor: WidgetStateProperty.all(
                  isDarkMode ? AppColors.primary : AppColors.lightTextPrimary,
                ),
                foregroundColor: WidgetStateProperty.all(
                  isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightBackground,
                ),
              ),
              child: Text(
                effectivePrimaryLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightBackground,
                ),
              ),
            )
          else if (buttonType == 'outlined')
            OutlinedButton(
              onPressed: onPrimary,
              style: theme.outlinedButtonTheme.style?.copyWith(
                foregroundColor: WidgetStateProperty.all(
                  isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              child: Text(
                effectivePrimaryLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            )
          else
            TextButton(
              onPressed: onPrimary,
              style: theme.textButtonTheme.style,
              child: Text(
                effectivePrimaryLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}