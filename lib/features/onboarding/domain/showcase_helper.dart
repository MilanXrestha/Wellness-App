import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:developer' as dev;

class ShowcaseHelper {
  // Check if showcase has been shown for a specific screen
  static Future<bool> hasShownShowcase(String showcaseKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(showcaseKey) ?? false;
  }

  // Mark showcase as shown for a specific screen
  static Future<void> markShowcaseAsShown(String showcaseKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(showcaseKey, true);
  }

  // Start showcase for first-time users on a specific screen
  static void startShowcase(
      BuildContext context,
      List<GlobalKey> showcaseKeys,
      List<String> titles,
      List<String> descriptions, {
        required String showcaseKey,
      }) async {
    if (await hasShownShowcase(showcaseKey)) {
      dev.log('Showcase already shown for $showcaseKey, skipping...', name: 'ShowcaseHelper');
      return;
    }

    try {
      if (context.mounted) {
        // Validate inputs
        if (showcaseKeys.isEmpty || showcaseKeys.length != titles.length || showcaseKeys.length != descriptions.length) {
          dev.log('Showcase keys, titles, or descriptions are empty or mismatched', name: 'ShowcaseHelper');
          return;
        }

        // Validate that all keys are attached to widgets
        for (var key in showcaseKeys) {
          if (key.currentContext == null) {
            dev.log('Showcase key not attached to widget: $key', name: 'ShowcaseHelper');
            return;
          }
        }
        ShowCaseWidget.of(context).startShowCase(showcaseKeys);
        await markShowcaseAsShown(showcaseKey);
        dev.log('Showcase started and marked as shown for $showcaseKey', name: 'ShowcaseHelper');
      } else {
        dev.log('Context not mounted, skipping showcase for $showcaseKey', name: 'ShowcaseHelper');
      }
    } catch (e, stackTrace) {
      dev.log(
        'Error starting showcase for $showcaseKey: $e',
        name: 'ShowcaseHelper',
        stackTrace: stackTrace,
      );
    }
  }

  // Reset showcase for testing (specific screen or all)
  static Future<void> resetShowcaseForTesting([String? showcaseKey]) async {
    final prefs = await SharedPreferences.getInstance();
    if (showcaseKey != null) {
      await prefs.remove(showcaseKey);
      dev.log('Showcase reset for $showcaseKey', name: 'ShowcaseHelper');
    } else {
      // Reset all known showcase keys
      await prefs.remove('has_shown_showcase');
      await prefs.remove('has_shown_tips_detail_showcase');
      await prefs.remove('has_shown_dashboard_showcase');
      dev.log('All showcases reset for testing', name: 'ShowcaseHelper');
    }
  }
}