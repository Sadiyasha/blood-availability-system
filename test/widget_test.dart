// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:blood_availability_system/main.dart';

void main() {
  testWidgets('Blood Availability System smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BloodAvailabilityApp());

    // Verify that our login screen is displayed.
    expect(find.text('Blood Availability System'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Verify the register link exists.
    expect(find.text("Don't have an account? Register here"), findsOneWidget);
  });
}
