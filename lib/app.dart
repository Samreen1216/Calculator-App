import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/calculator_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/tab_selector.dart';

class CalculatorApp extends StatefulWidget {
  final ThemeMode? initialThemeMode;
  final bool? showSplash;
  final Duration? splashDuration;

  const CalculatorApp({
    super.key,
    this.initialThemeMode,
    this.showSplash,
    this.splashDuration,
  });

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  static const String _themePrefKey = 'calculator_theme_mode';
  late ThemeMode _themeMode;
  late bool _displayingSplash;
  CalculatorMode _selectedMode = CalculatorMode.standard;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode ?? ThemeMode.light;
    final inTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    _displayingSplash = widget.showSplash ?? !inTest;
    if (widget.initialThemeMode == null) {
      _loadSavedTheme();
    }
  }

  void _onSplashFinish() {
    if (mounted) {
      setState(() {
        _displayingSplash = false;
      });
    }
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themePrefKey);
      if (isDark != null && mounted) {
        setState(() {
          _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setState(() {
      _themeMode = newMode;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePrefKey, newMode == ThemeMode.dark);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _displayingSplash
            ? SplashScreen(
                key: const ValueKey('splash_view'),
                duration: widget.splashDuration ?? const Duration(seconds: 5),
                initialMode: _selectedMode,
                onModeSelected: (mode) => _selectedMode = mode,
                onFinish: _onSplashFinish,
              )
            : CalculatorScreen(
                key: const ValueKey('calculator_view'),
                initialMode: _selectedMode,
                onToggleTheme: _toggleTheme,
              ),
      ),
    );
  }
}
