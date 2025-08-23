// tab_switch_notification.dart
import 'package:flutter/material.dart';

class TabSwitchNotification extends Notification {
  final int tabIndex;
  final String tipId;

  TabSwitchNotification({required this.tabIndex, required this.tipId});
}