import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightDisplay = Color(0xFFFFFFFF);
  static const Color lightNumberButton = Color(0xFFEEF0F4);
  static const Color lightPrimaryText = Color(0xFF202938);
  static const Color lightOperatorButton = Color(0xFFDCE7F5);
  static const Color lightEqualsButton = Color(0xFF347D78);
  static const Color lightSecondaryText = Color(0xFF778196);
  static const Color lightFunctionButton = Color(0xFFE5E8EE);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkDisplay = Color(0xFF2C2C2E);
  static const Color darkNumberButton = Color(0xFF3A3A3C);
  static const Color darkPrimaryText = Color(0xFFF2F2F7);
  static const Color darkOperatorButton = Color(0xFF2A3A52);
  static const Color darkEqualsButton = Color(0xFF347D78);
  static const Color darkSecondaryText = Color(0xFF98989D);
  static const Color darkFunctionButton = Color(0xFF48484A);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightBackground,
        primary: AppColors.lightEqualsButton,
        onPrimary: Colors.white,
        secondary: AppColors.lightOperatorButton,
        onSecondary: AppColors.lightPrimaryText,
        onSurface: AppColors.lightPrimaryText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.lightPrimaryText,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        iconTheme: IconThemeData(color: AppColors.lightPrimaryText),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        CalculatorTheme(
          backgroundColor: AppColors.lightBackground,
          displayColor: AppColors.lightDisplay,
          numberButtonColor: AppColors.lightNumberButton,
          operatorButtonColor: AppColors.lightOperatorButton,
          equalsButtonColor: AppColors.lightEqualsButton,
          functionButtonColor: AppColors.lightFunctionButton,
          primaryTextColor: AppColors.lightPrimaryText,
          secondaryTextColor: AppColors.lightSecondaryText,
          equalsTextColor: Colors.white,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkBackground,
        primary: AppColors.darkEqualsButton,
        onPrimary: Colors.white,
        secondary: AppColors.darkOperatorButton,
        onSecondary: AppColors.darkPrimaryText,
        onSurface: AppColors.darkPrimaryText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.darkPrimaryText,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        iconTheme: IconThemeData(color: AppColors.darkPrimaryText),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        CalculatorTheme(
          backgroundColor: AppColors.darkBackground,
          displayColor: AppColors.darkDisplay,
          numberButtonColor: AppColors.darkNumberButton,
          operatorButtonColor: AppColors.darkOperatorButton,
          equalsButtonColor: AppColors.darkEqualsButton,
          functionButtonColor: AppColors.darkFunctionButton,
          primaryTextColor: AppColors.darkPrimaryText,
          secondaryTextColor: AppColors.darkSecondaryText,
          equalsTextColor: Colors.white,
        ),
      ],
    );
  }
}

class CalculatorTheme extends ThemeExtension<CalculatorTheme> {
  final Color backgroundColor;
  final Color displayColor;
  final Color numberButtonColor;
  final Color operatorButtonColor;
  final Color equalsButtonColor;
  final Color functionButtonColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color equalsTextColor;

  const CalculatorTheme({
    required this.backgroundColor,
    required this.displayColor,
    required this.numberButtonColor,
    required this.operatorButtonColor,
    required this.equalsButtonColor,
    required this.functionButtonColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.equalsTextColor,
  });

  @override
  CalculatorTheme copyWith({
    Color? backgroundColor,
    Color? displayColor,
    Color? numberButtonColor,
    Color? operatorButtonColor,
    Color? equalsButtonColor,
    Color? functionButtonColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? equalsTextColor,
  }) {
    return CalculatorTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      displayColor: displayColor ?? this.displayColor,
      numberButtonColor: numberButtonColor ?? this.numberButtonColor,
      operatorButtonColor: operatorButtonColor ?? this.operatorButtonColor,
      equalsButtonColor: equalsButtonColor ?? this.equalsButtonColor,
      functionButtonColor: functionButtonColor ?? this.functionButtonColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      equalsTextColor: equalsTextColor ?? this.equalsTextColor,
    );
  }

  @override
  CalculatorTheme lerp(CalculatorTheme? other, double t) {
    if (other is! CalculatorTheme) return this;
    return CalculatorTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      displayColor: Color.lerp(displayColor, other.displayColor, t)!,
      numberButtonColor: Color.lerp(numberButtonColor, other.numberButtonColor, t)!,
      operatorButtonColor: Color.lerp(operatorButtonColor, other.operatorButtonColor, t)!,
      equalsButtonColor: Color.lerp(equalsButtonColor, other.equalsButtonColor, t)!,
      functionButtonColor: Color.lerp(functionButtonColor, other.functionButtonColor, t)!,
      primaryTextColor: Color.lerp(primaryTextColor, other.primaryTextColor, t)!,
      secondaryTextColor: Color.lerp(secondaryTextColor, other.secondaryTextColor, t)!,
      equalsTextColor: Color.lerp(equalsTextColor, other.equalsTextColor, t)!,
    );
  }
}
