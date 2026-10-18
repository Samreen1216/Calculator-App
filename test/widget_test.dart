import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calculator/app.dart';
import 'package:calculator/controllers/calculator_controller.dart';
import 'package:calculator/models/calculation.dart';
import 'package:calculator/models/unit_converter.dart';
import 'package:calculator/services/calculator_engine.dart';

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
}
