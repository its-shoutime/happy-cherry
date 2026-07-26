import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_cherry/app/app_theme.dart';
import 'package:happy_cherry/features/hatch/hatch_screen.dart';

void main() {
  testWidgets('HatchScreen shows hatching copy and completes after duration', (
    WidgetTester tester,
  ) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HatchScreen(
          duration: const Duration(milliseconds: 200),
          onComplete: () => completed = true,
        ),
      ),
    );

    expect(find.text('The egg is hatching...'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(completed, isFalse);

    await tester.pump(const Duration(milliseconds: 250));
    expect(completed, isTrue);
  });
}
