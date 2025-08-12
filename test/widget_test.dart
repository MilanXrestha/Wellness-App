import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/wellness_app.dart';

void main() {
  testWidgets('Smoke test: WellnessApp loads correctly', (WidgetTester tester) async {
    // Build the app with onboarding completed set to false
    await tester.pumpWidget(const WellnessApp());

    // Wait for the frame to settle
    await tester.pumpAndSettle();

    // Add any expectations or verifications here.
    // For now, just verify if the widget tree builds successfully.
    expect(find.byType(WellnessApp), findsOneWidget);
  });
}
