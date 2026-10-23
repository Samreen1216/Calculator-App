import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calculator/app.dart';
import 'package:calculator/controllers/calculator_controller.dart';
import 'package:calculator/models/calculation.dart';
import 'package:calculator/models/unit_converter.dart';
import 'package:calculator/services/calculator_engine.dart';
import 'package:calculator/screens/splash_screen.dart';
import 'package:calculator/widgets/calculator_button.dart';
import 'package:calculator/widgets/history_sheet.dart';
import 'package:calculator/widgets/tab_selector.dart';

void main() {
  group('CalculatorEngine Tests', () {
    late CalculatorEngine engine;

    setUp(() {
      engine = CalculatorEngine();
    });

    test('Basic Arithmetic & PEMDAS', () {
      expect(engine.evaluate('2+3×4'), equals('14'));
      expect(engine.evaluate('(2+3)×4'), equals('20'));
      expect(engine.evaluate('10-2×3'), equals('4'));
      expect(engine.evaluate('15÷3+2'), equals('7'));
    });

    test('Decimals & Trailing Zero cleanup', () {
      expect(engine.evaluate('0.1+0.2'), equals('0.3'));
      expect(engine.evaluate('5.5×2'), equals('11'));
      expect(engine.evaluate('10÷4'), equals('2.5'));
    });

    test('Percentages - Standard & Relative', () {
      expect(engine.evaluate('50%'), equals('0.5'));
      expect(engine.evaluate('200×10%'), equals('20'));
      expect(engine.evaluate('100+10%'), equals('110'));
      expect(engine.evaluate('100-20%'), equals('80'));
      expect(engine.evaluate('(50+50)%'), equals('1'));
    });

    test('Division by zero & Errors', () {
      expect(engine.evaluate('5÷0'), equals('Error'));
    });

    test('Scientific Powers and Roots', () {
      expect(engine.evaluate('2^3'), equals('8'));
      expect(engine.evaluate('sqrt(16)'), equals('4'));
      expect(engine.evaluate('sqrt(2)^2'), equals('2'));
      expect(engine.evaluate('2^3^2'), equals('512')); // 2^(3^2) = 2^9 = 512
    });

    test('Hyperbolic Functions & Rounding', () {
      expect(engine.evaluate('sinh(0)'), equals('0'));
      expect(engine.evaluate('cosh(0)'), equals('1'));
      expect(engine.evaluate('tanh(0)'), equals('0'));
      expect(engine.evaluate('ceil(3.2)'), equals('4'));
      expect(engine.evaluate('floor(3.8)'), equals('3'));
    });

    test('Implicit Multiplication', () {
      expect(engine.evaluate('2(3+4)'), equals('14'));
      expect(engine.evaluate('(2)(3)'), equals('6'));
      expect(engine.evaluate('(2)3'), equals('6'));
      expect(engine.evaluate('(2+3)(4+5)'), equals('45'));
    });

    test('Unary Minus and Negative Operands', () {
      expect(engine.evaluate('5×-3'), equals('-15'));
      expect(engine.evaluate('5×−3'), equals('-15'));
      expect(engine.evaluate('10÷-2'), equals('-5'));
      expect(engine.evaluate('10÷−2'), equals('-5'));
      expect(engine.evaluate('5+(-3)'), equals('2'));
      expect(engine.evaluate('5+(−3)'), equals('2'));
    });

    test('Trigonometry in DEG mode', () {
      engine.angleMode = AngleMode.deg;
      expect(engine.evaluate('sin(90)'), equals('1'));
      expect(engine.evaluate('cos(0)'), equals('1'));
      expect(engine.evaluate('tan(45)'), equals('1'));
      expect(engine.evaluate('asin(1)'), equals('90'));
    });

    test('Trigonometry in RAD mode', () {
      engine.angleMode = AngleMode.rad;
      expect(engine.evaluate('cos(0)'), equals('1'));
      expect(engine.evaluate('sin(0)'), equals('0'));
    });

    test('Factorials', () {
      expect(engine.evaluate('5!'), equals('120'));
      expect(engine.evaluate('0!'), equals('1'));
      expect(engine.evaluate('1!'), equals('1'));
      expect(engine.evaluate('171!'), equals('Error')); // boundary limit
    });

    test('Constants', () {
      final piResult = double.parse(engine.evaluate('π'));
      expect((piResult - 3.14159265).abs() < 1e-4, isTrue);

      final eResult = double.parse(engine.evaluate('e'));
      expect((eResult - 2.7182818).abs() < 1e-4, isTrue);
    });
  });

  group('CalculatorController Tests (Phase 2)', () {
    late CalculatorController controller;

    setUp(() {
      controller = CalculatorController();
    });

    test('Thousand separators formatting', () {
      expect(CalculatorController.formatNumber('1234567'), equals('1,234,567'));
      expect(CalculatorController.formatNumber('1234567.89'), equals('1,234,567.89'));
      expect(CalculatorController.formatNumber('-5000'), equals('−5,000'));
      expect(CalculatorController.formatNumber('0'), equals('0'));
      expect(CalculatorController.formatNumber('Error'), equals('Error'));
    });

    test('Controller evaluation and history tracking', () {
      controller.onInput('1');
      controller.onInput('0');
      controller.onInput('+');
      controller.onInput('5');
      controller.onEquals();

      expect(controller.result, equals('15'));
      expect(controller.history.length, equals(1));
      expect(controller.history.first.expression, equals('10+5'));
      expect(controller.history.first.result, equals('15'));

      controller.onClear();
      expect(controller.expression, equals(''));
      controller.selectHistory(controller.history.first);
      expect(controller.expression, equals('10+5'));
      expect(controller.result, equals('15'));
    });

    test('Controller paste feature', () {
      controller.paste('25 * 4');
      controller.onEquals();
      expect(controller.result, equals('100'));
    });

    test('Calculation model serialization', () {
      final now = DateTime.now();
      final calc = Calculation(expression: '5+5', result: '10', timestamp: now);
      final json = calc.toJson();
      final restored = Calculation.fromJson(json);

      expect(restored.expression, equals('5+5'));
      expect(restored.result, equals('10'));
      expect(restored.timestamp.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });
  });

  group('Phase 3 Features: Memory & Unit Converter Tests', () {
    late CalculatorController controller;

    setUp(() {
      controller = CalculatorController();
    });

    test('Memory operations (MC, MR, M+, M-)', () {
      expect(controller.hasMemory, isFalse);
      expect(controller.memory, equals(0.0));

      // Calculate 50 and add to memory
      controller.onInput('5');
      controller.onInput('0');
      controller.onEquals();
      controller.memoryAdd();

      expect(controller.hasMemory, isTrue);
      expect(controller.memory, equals(50.0));

      // Subtract 20 from memory
      controller.onClear();
      controller.onInput('2');
      controller.onInput('0');
      controller.onEquals();
      controller.memorySubtract();

      expect(controller.memory, equals(30.0));

      // Clear expression and recall memory
      controller.onClear();
      expect(controller.expression, equals(''));
      controller.memoryRecall();
      expect(controller.expression, equals('30'));

      // Clear memory
      controller.memoryClear();
      expect(controller.hasMemory, isFalse);
      expect(controller.memory, equals(0.0));
    });

    test('Unit Converter Service: Length conversions', () {
      final lengthUnits = UnitConverterService.unitsByCategory[UnitCategory.length]!;
      final meters = lengthUnits.firstWhere((u) => u.id == 'm');
      final km = lengthUnits.firstWhere((u) => u.id == 'km');
      final inches = lengthUnits.firstWhere((u) => u.id == 'in');
      final feet = lengthUnits.firstWhere((u) => u.id == 'ft');

      expect(UnitConverterService.convert(1000, meters, km, UnitCategory.length), equals(1.0));
      expect(UnitConverterService.convert(1, km, meters, UnitCategory.length), equals(1000.0));
      expect(UnitConverterService.convert(12, inches, feet, UnitCategory.length), closeTo(1.0, 1e-4));
    });

    test('Unit Converter Service: Temperature conversions', () {
      final tempUnits = UnitConverterService.unitsByCategory[UnitCategory.temperature]!;
      final c = tempUnits.firstWhere((u) => u.id == 'c');
      final f = tempUnits.firstWhere((u) => u.id == 'f');
      final k = tempUnits.firstWhere((u) => u.id == 'k');

      expect(UnitConverterService.convert(0, c, f, UnitCategory.temperature), equals(32.0));
      expect(UnitConverterService.convert(100, c, f, UnitCategory.temperature), equals(212.0));
      expect(UnitConverterService.convert(32, f, c, UnitCategory.temperature), equals(0.0));
      expect(UnitConverterService.convert(0, c, k, UnitCategory.temperature), equals(273.15));
    });
  });

  group('Widget & UI Interaction Tests', () {
    testWidgets('Renders all 3 tabs: Standard, Scientific, Converter', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Scientific'), findsOneWidget);
      expect(find.text('Converter'), findsOneWidget);
      expect(find.text('MC'), findsOneWidget);
      expect(find.text('MR'), findsOneWidget);
      expect(find.text('M+'), findsOneWidget);
      expect(find.text('M−'), findsOneWidget);
    });

    testWidgets('Switches to Converter tab and converts units', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      // Tap on Converter tab
      await tester.tap(find.text('Converter'));
      await tester.pumpAndSettle();

      expect(find.text('Length'), findsOneWidget);
      expect(find.text('Mass'), findsOneWidget);
      expect(find.text('Temperature'), findsOneWidget);
    });

    testWidgets('Renders in landscape mode without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2400, 1080);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      expect(find.text('Calculator'), findsOneWidget);
      await tester.tap(find.text('Scientific'));
      await tester.pumpAndSettle();

      expect(find.text('sin'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Physical keyboard input handles numbers and equals', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      // Simulate keyboard strokes: 8, *, 5, Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.digit8, character: '8');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadMultiply);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5, character: '5');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('40'), findsOneWidget);
    });

    testWidgets('Sign toggle button inverts number back and forth', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsWidgets);

      await tester.tap(find.text('+/−'));
      await tester.pumpAndSettle();
      expect(find.text('(−5)'), findsOneWidget);

      await tester.tap(find.text('+/−'));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsWidgets);
      expect(find.text('(−5)'), findsNothing);
    });

    testWidgets('Allows entering negative operand after multiply', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('×'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('−'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(find.text('5×−3'), findsOneWidget);

      await tester.tap(find.text('='));
      await tester.pumpAndSettle();

      expect(find.text('−15'), findsOneWidget);
    });

    testWidgets('Error state recovers cleanly on next digit input', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('÷'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);

      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsNothing);
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('ThemeMode persists across sessions via SharedPreferences', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'calculator_theme_mode': true});

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      final darkApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(darkApp.themeMode, equals(ThemeMode.dark));

      // Toggle to light mode
      await tester.tap(find.byTooltip('Toggle theme'));
      await tester.pumpAndSettle();

      final lightApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(lightApp.themeMode, equals(ThemeMode.light));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('calculator_theme_mode'), isFalse);
    });

    testWidgets('HistorySheet requires confirmation before clearing', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      // Calculate 1 + 2 = 3 to populate history
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();

      // Open history sheet
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      expect(find.text('1+2'), findsWidgets);

      // Tap clear all in header
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.text('Clear All History?'), findsOneWidget);

      // Tap Cancel -> history remains
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('1+2'), findsWidgets);

      // Tap clear all again, then confirm Clear All in dialog
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Clear All').last);
      await tester.pumpAndSettle();

      // Dialog and sheet should be dismissed
      expect(find.text('Clear All History?'), findsNothing);
    });

    testWidgets('HistorySheet close button dismisses bottom sheet cleanly without swiping', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      // Open history sheet
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      // Verify history sheet is open with title & Close button
      expect(find.text('History'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      // Tap Close button
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      // History sheet is cleanly dismissed
      expect(find.text('History'), findsNothing);
    });

    testWidgets('HistorySheet supports copy result and delete with undo', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      // Calculate 4 × 5 = 20
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('×'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();

      // Open history sheet
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      expect(find.text('4×5'), findsWidgets);
      expect(find.byTooltip('Copy result'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);

      // Tap copy result
      await tester.tap(find.byTooltip('Copy result'));
      await tester.pumpAndSettle();
      expect(find.text('Copied: 20'), findsOneWidget);

      // Dismiss SnackBar before tapping delete
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Calculation deleted'), findsOneWidget);

      // Tap Undo in SnackBar
      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('4×5'), findsWidgets);
    });

    testWidgets('Converter saves conversion history and shows it when history icon is clicked', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      // Switch to Converter mode
      await tester.tap(find.text('Converter'));
      await tester.pumpAndSettle();

      // Clear initial '1'
      await tester.tap(find.widgetWithText(CalculatorButton, 'AC'));
      await tester.pumpAndSettle();

      // Type 5 in Converter (5 m -> ft)
      await tester.tap(find.widgetWithText(CalculatorButton, '5'));
      await tester.pumpAndSettle();

      // Open history from Converter screen
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      // Conversion history should be visible
      expect(find.text('5 m'), findsWidgets);
      expect(find.text('Length'), findsWidgets);

      // Close history
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping calculation from history while on Converter screen switches to calculator and displays it', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      // Calculate 7 × 8 = 56 in Standard mode
      await tester.tap(find.widgetWithText(CalculatorButton, '7'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CalculatorButton, '×'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CalculatorButton, '8'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CalculatorButton, '='));
      await tester.pumpAndSettle();

      // Switch to Converter mode
      await tester.tap(find.text('Converter'));
      await tester.pumpAndSettle();

      // Open history from Converter screen
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      // Tap the calculation '7×8'
      await tester.tap(find.text('7×8'));
      await tester.pumpAndSettle();

      // The app should switch back to calculator display showing '7×8' and '56'
      expect(find.text('7×8'), findsOneWidget);
      expect(find.text('56'), findsOneWidget);
    });

    testWidgets('Delete icon removes item immediately from bottom sheet', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      // Calculate 3 + 4 = 7
      await tester.tap(find.widgetWithText(CalculatorButton, '3'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CalculatorButton, '+'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CalculatorButton, '4'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CalculatorButton, '='));
      await tester.pumpAndSettle();

      // Open history sheet
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      expect(find.text('3+4'), findsWidgets);

      // Tap Delete icon on the card
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      // The card is removed immediately from HistorySheet and 'No history yet' is shown
      expect(
        find.descendant(
          of: find.byType(HistorySheet),
          matching: find.text('3+4'),
        ),
        findsNothing,
      );
      expect(find.text('No history yet'), findsOneWidget);
    });

    testWidgets('Converter routes physical keyboard input', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Converter'));
      await tester.pumpAndSettle();

      // Clear initial '1' via Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('0'), findsWidgets);

      // Type 4, 5
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4, character: '4');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5, character: '5');
      await tester.pumpAndSettle();

      expect(find.text('45'), findsWidgets);

      // Backspace
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(find.text('4'), findsWidgets);

      // Clear (Escape)
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('Converter renders in landscape mode without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Converter'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Length'), findsOneWidget);
    });
  });

  group('SplashScreen Tests', () {
    testWidgets('SplashScreen renders title, icon, and mode badges', (WidgetTester tester) async {
      bool finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(seconds: 1),
            onFinish: () => finished = true,
          ),
        ),
      );

      // Verify splash elements are present
      expect(find.text('Calculator'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Scientific'), findsOneWidget);
      expect(find.text('Converter'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Advance time by 1 second to complete splash
      await tester.pump(const Duration(seconds: 1));
      expect(finished, isTrue);
    });

    testWidgets('CalculatorApp with showSplash: true shows splash then transitions to calculator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CalculatorApp(
          showSplash: true,
          splashDuration: Duration(milliseconds: 200),
        ),
      );

      // Immediately after first pump, splash should be visible
      expect(find.byKey(const ValueKey('splash_view')), findsOneWidget);

      // Advance through splash animation and crossfade transition
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Calculator screen should now be visible
      expect(find.byKey(const ValueKey('calculator_view')), findsOneWidget);
      expect(find.text('Calculator'), findsOneWidget);
    });

    testWidgets('SplashScreen interactive mode chips switch modes and update description', (WidgetTester tester) async {
      CalculatorMode selectedMode = CalculatorMode.standard;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(seconds: 10),
            onFinish: () {},
            onModeSelected: (mode) => selectedMode = mode,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Initial tagline is for Standard
      expect(find.text('Clean arithmetic • Instant percentage'), findsOneWidget);

      // Tap Scientific chip
      await tester.tap(find.text('Scientific'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selectedMode, equals(CalculatorMode.scientific));
      expect(find.text('Trigonometry • Powers • Logarithms'), findsOneWidget);

      // Tap Converter chip
      await tester.tap(find.text('Converter'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selectedMode, equals(CalculatorMode.converter));
      expect(find.text('Length • Weight • Speed • Temperature'), findsOneWidget);

      // Tap Standard chip back
      await tester.tap(find.text('Standard'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selectedMode, equals(CalculatorMode.standard));
      expect(find.text('Clean arithmetic • Instant percentage'), findsOneWidget);
    });

    testWidgets('SplashScreen Skip button finishes immediately without waiting for duration', (WidgetTester tester) async {
      bool finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(seconds: 30),
            onFinish: () => finished = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(finished, isFalse);
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(finished, isTrue);
    });

    testWidgets('SplashScreen Tap to start calculating finishes immediately', (WidgetTester tester) async {
      bool finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(seconds: 30),
            onFinish: () => finished = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(finished, isFalse);
      expect(find.text('Tap to start calculating'), findsOneWidget);

      await tester.tap(find.text('Tap to start calculating'));
      await tester.pump();
      expect(finished, isTrue);
    });

    testWidgets('SplashScreen tapping app icon triggers easter egg reaction bubble', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(seconds: 10),
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Tap icon
      await tester.tap(find.byType(Image));
      await tester.pump(const Duration(milliseconds: 150));

      // Easter egg popup should be revealed
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            (widget.data == 'π ≈ 3.14159' ||
             widget.data == '= 42' ||
             widget.data == 'e ≈ 2.71828' ||
             widget.data == 'φ ≈ 1.618')),
        findsOneWidget,
      );
    });

    testWidgets('SplashScreen math trivia card rotates trivia fact on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(seconds: 10),
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Initial trivia is Euler's identity
      expect(find.text("Euler's identity: e^(iπ) + 1 = 0"), findsOneWidget);

      // Tap the trivia card
      await tester.tap(find.text("Euler's identity: e^(iπ) + 1 = 0"));
      await tester.pump(const Duration(milliseconds: 300));

      // Next trivia fact appears
      expect(find.text('2520 is divisible by all numbers 1 through 10'), findsOneWidget);
    });

    testWidgets('SplashScreen screen tap and drag spawns touch bursts cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(seconds: 10),
            onFinish: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Tap screen at arbitrary location
      await tester.tapAt(const Offset(150, 200));
      await tester.pump(const Duration(milliseconds: 50));

      // Drag across screen
      final gesture = await tester.startGesture(const Offset(100, 300));
      await gesture.moveBy(const Offset(50, 50));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    });

    testWidgets('CalculatorApp opens directly in selected mode from splash screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CalculatorApp(
          showSplash: true,
          splashDuration: Duration(seconds: 10),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Tap Scientific chip on splash
      await tester.tap(find.text('Scientific'));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Skip to enter immediately
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Should now be on Calculator screen in scientific mode (sin function visible)
      expect(find.byKey(const ValueKey('calculator_view')), findsOneWidget);
      expect(find.text('sin'), findsOneWidget);
    });

    testWidgets('SplashScreen default duration does not disappear within 1 second and waits 5s', (WidgetTester tester) async {
      bool finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            onFinish: () => finished = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Advance by 1 second - should NOT disappear
      await tester.pump(const Duration(seconds: 1));
      expect(finished, isFalse);

      // Advance by another 2 seconds (total 3s) - still active
      await tester.pump(const Duration(seconds: 2));
      expect(finished, isFalse);

      // Advance by another 1.5 seconds (total 4.5s) - still active
      await tester.pump(const Duration(milliseconds: 1500));
      expect(finished, isFalse);

      // Advance past 5s total duration
      await tester.pump(const Duration(milliseconds: 700));
      expect(finished, isTrue);
    });

    testWidgets('SplashScreen user interaction extends timer to prevent premature disappearance', (WidgetTester tester) async {
      bool finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(seconds: 5),
            onFinish: () => finished = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Advance 4 seconds (almost finished if duration is 5s)
      await tester.pump(const Duration(seconds: 4));
      expect(finished, isFalse);

      // User interacts: tap mode chip
      await tester.tap(find.text('Scientific'));
      await tester.pump(const Duration(milliseconds: 100));

      // Advance another 3 seconds (total 7.1s from start)
      // Without interaction extension, it would have already vanished at 5s!
      await tester.pump(const Duration(seconds: 3));
      expect(finished, isFalse);

      // Advance past the 5s extension timeout
      await tester.pump(const Duration(seconds: 2));
      expect(finished, isTrue);
    });
  });
}
