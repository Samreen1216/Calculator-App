import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculator/app.dart';
import 'package:calculator/screens/splash_screen.dart';

void main() {
  group('Screen Size Responsiveness Tests', () {
    final testSizes = [
      ('iPhone SE 1st gen', const Size(320, 568)),
      ('iPhone SE 2nd gen', const Size(375, 667)),
      ('iPhone 13/14', const Size(390, 844)),
      ('Phone Landscape Short', const Size(640, 360)),
      ('Phone Landscape 375', const Size(667, 375)),
      ('Phone Landscape Modern', const Size(844, 390)),
      ('Tablet Portrait', const Size(768, 1024)),
      ('Tablet Landscape', const Size(1024, 768)),
      ('Desktop Window', const Size(1280, 800)),
      ('Small Desktop Window', const Size(600, 500)),
    ];

    for (final (name, size) in testSizes) {
      testWidgets('Standard, Scientific, and Converter on $name ($size)', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(const CalculatorApp(showSplash: false));
        await tester.pumpAndSettle();

        // 1. Standard mode
        expect(tester.takeException(), isNull, reason: 'Overflow in Standard mode on $name');

        // 2. Scientific mode
        await tester.tap(find.text('Scientific'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in Scientific mode on $name');

        // 3. Converter mode
        await tester.tap(find.text('Converter'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in Converter mode on $name');
      });
    }

    testWidgets('Desktop / Tablet (width >= 800) toggles Side History Panel without modal', (tester) async {
      tester.view.physicalSize = const Size(2048, 1536);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp(showSplash: false));
      await tester.pumpAndSettle();

      // Compute 9 * 8 = 72
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('×'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();

      // Initially, no side panel history
      expect(find.byType(VerticalDivider), findsNothing);

      // Tap history button in header -> opens side panel
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      // Side panel is now present side-by-side with vertical divider
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('9×8'), findsWidgets);

      // Close button inside side panel closes it
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('SplashScreen renders without overflow on ultra-short landscape screen', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(milliseconds: 100),
            onFinish: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Calculator'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
