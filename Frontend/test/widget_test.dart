// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Login page loads when not logged in', (WidgetTester tester) async {
    // Build the app in not logged in state
    await tester.pumpWidget(const MyApp(
      isLoggedIn: false,
      role: null,
    ));

    // Verify login interface is displayed
    expect(find.text('MyAcademic'), findsWidgets);
  });

  testWidgets('Student homepage loads when logged in as student', (WidgetTester tester) async {
    // Build the app in logged in state as student
    await tester.pumpWidget(const MyApp(
      isLoggedIn: true,
      role: 'student',
    ));

    // Verify homepage loads
    expect(find.byType(Scaffold), findsWidgets);
  });
}
