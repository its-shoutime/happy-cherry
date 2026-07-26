// Login UI smoke test — avoids Firebase by pumping LoginPage directly.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_cherry/app/app_theme.dart';
import 'package:happy_cherry/features/auth/login.dart';

void main() {
  testWidgets('Login page shows owner login controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const LoginPage(),
      ),
    );

    expect(find.text('Owner login'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Email or username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
