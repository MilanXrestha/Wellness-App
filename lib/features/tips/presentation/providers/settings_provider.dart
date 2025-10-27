import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  int _countdown = 5;
  bool _showFullScreenIcon = true;
  bool _showSwipeIndicator = true;
  bool _slideshowEnabled = true;
  int _tipsScreenVisitCount = 0;

  int get countdown => _countdown;

  bool get showFullScreenIcon => _showFullScreenIcon;

  bool get showSwipeIndicator => _showSwipeIndicator;

  bool get slideshowEnabled => _slideshowEnabled;

  bool get shouldShowSwipeIndicator =>
      _showSwipeIndicator && _tipsScreenVisitCount < 3;

  void updateSettings(
    int countdown,
    bool showFullScreenIcon,
    bool showSwipeIndicator,
    bool slideshowEnabled,
  ) {
    _countdown = countdown;
    _showFullScreenIcon = showFullScreenIcon;
    _showSwipeIndicator = showSwipeIndicator;
    _slideshowEnabled = slideshowEnabled;
    notifyListeners();
  }

  void incrementVisitCount() {
    _tipsScreenVisitCount++;
    notifyListeners();
  }
}
