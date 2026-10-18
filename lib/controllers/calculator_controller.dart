import 'package:flutter/foundation.dart';
import '../models/calculation.dart';
import '../services/calculator_engine.dart';
import '../services/history_service.dart';
import '../widgets/tab_selector.dart';

class CalculatorController extends ChangeNotifier {
  final CalculatorEngine engine;
  final HistoryService historyService;

  String _expression = '';
  String _result = '0';
  bool _hasResult = false;
  bool _isInverseMode = false;
  CalculatorMode _mode = CalculatorMode.standard;
  int _openParenCount = 0;
  bool _justEvaluated = false;
  double _memory = 0.0;

  CalculatorController({
    CalculatorEngine? engine,
    HistoryService? historyService,
  })  : engine = engine ?? CalculatorEngine(),
        historyService = historyService ?? HistoryService();

  // Getters
  String get expression => _expression;
  String get result => _result;
  bool get hasResult => _hasResult;
  bool get isInverseMode => _isInverseMode;
  CalculatorMode get mode => _mode;
  int get openParenCount => _openParenCount;
  bool get justEvaluated => _justEvaluated;
  AngleMode get angleMode => engine.angleMode;
  String get angleModeLabel => engine.angleMode == AngleMode.deg ? 'DEG' : 'RAD';
  List<Calculation> get history => historyService.history;
  double get memory => _memory;
  bool get hasMemory => _memory != 0.0;

  /// Formatted result with thousand grouping separators (e.g., 1,234,567.89).
  String get formattedResult => formatNumber(_result);

  /// Formats numbers with comma separators for clean display readability.
  static String formatNumber(String numStr) {
    if (numStr.isEmpty ||
        numStr == '0' ||
        numStr == 'Error' ||
        numStr == '∞' ||
        numStr == '-∞' ||
        numStr.contains('e')) {
      return numStr;
    }
    bool isNegative = numStr.startsWith('-') || numStr.startsWith('−');
    String cleanStr = isNegative ? numStr.substring(1) : numStr;

    List<String> parts = cleanStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    integerPart = integerPart.replaceAllMapped(reg, (Match m) => '${m[1]},');

    return '${isNegative ? '−' : ''}$integerPart$decimalPart';
  }

  void onInput(String value) {
    if (_justEvaluated) {
      if (_result == 'Error') {
        _expression = '';
        _result = '0';
        _hasResult = false;
        _openParenCount = 0;
      } else {
        if (_isDigit(value) || value == '.' || value == '(' || value == 'π' || value == 'e') {
          _expression = '';
          _result = '0';
          _hasResult = false;
          _openParenCount = 0;
        } else if (_isOperator(value)) {
          _expression = _result;
          _hasResult = false;
        }
      }
      _justEvaluated = false;
    }

    if (_isOperator(value)) {
      _handleOperator(value);
    } else if (value == '.') {
      _handleDecimal();
    } else if (value == '(' || value == ')') {
      _handleParenthesis(value);
    } else if (value == '^') {
      _handlePower();
    } else {
      _handleDigitOrConstant(value);
    }

    _updatePreview();
    notifyListeners();
  }

  void _handleDigitOrConstant(String value) {
    if (_expression.isNotEmpty && _expression.endsWith(')')) {
      _expression += '×';
    }

    if (_expression == '0' && value != '.') {
      _expression = value;
    } else {
      _expression += value;
    }
  }

  void _handleOperator(String op) {
    if (_expression.isEmpty) {
      if (op == '−' || op == '-') {
        _expression = '−';
      }
      return;
    }

    String lastChar = _expression[_expression.length - 1];

    if ((lastChar == '×' || lastChar == '÷' || lastChar == '^' || lastChar == '(') &&
        (op == '−' || op == '-')) {
      _expression += '−';
      return;
    }

    if (_isOperator(lastChar)) {
      if (_expression.length >= 2 && _isOperator(_expression[_expression.length - 2])) {
        _expression = _expression.substring(0, _expression.length - 2) + op;
      } else {
        _expression = _expression.substring(0, _expression.length - 1) + op;
      }
    } else {
      _expression += op;
    }
  }

  void _handleDecimal() {
    if (_expression.isEmpty) {
      _expression = '0.';
      return;
    }

    String lastNumber = _getLastNumber();
    if (!lastNumber.contains('.')) {
      if (_expression.isEmpty ||
          _isOperator(_expression[_expression.length - 1]) ||
          _expression.endsWith('(')) {
        _expression += '0.';
      } else {
        _expression += '.';
      }
    }
  }

  void _handleParenthesis(String paren) {
    if (paren == '(') {
      if (_expression.isNotEmpty) {
        String lastChar = _expression[_expression.length - 1];
        if (_isDigit(lastChar) ||
            lastChar == ')' ||
            lastChar == 'π' ||
            lastChar == 'e' ||
            lastChar == '!') {
          _expression += '×';
        }
      }
      _expression += '(';
      _openParenCount++;
    } else if (paren == ')' && _openParenCount > 0) {
      _expression += ')';
      _openParenCount--;
    }
  }

  void _handlePower() {
    if (_expression.isNotEmpty && !_isOperator(_expression[_expression.length - 1])) {
      _expression += '^';
    }
  }

  void handleFunction(String func) {
    if (_justEvaluated) {
      if (_result == 'Error') {
        _expression = '';
        _result = '0';
        _hasResult = false;
        _openParenCount = 0;
      }
      _justEvaluated = false;
    }

    switch (func) {
      case 'sin':
      case 'cos':
      case 'tan':
      case 'asin':
      case 'acos':
      case 'atan':
      case 'sinh':
      case 'cosh':
      case 'tanh':
      case 'log':
      case 'ln':
      case 'sqrt':
        if (_expression.isNotEmpty) {
          String lastChar = _expression[_expression.length - 1];
          if (_isDigit(lastChar) || lastChar == ')' || lastChar == 'π' || lastChar == 'e') {
            _expression += '×';
          }
        }
        _expression += '$func(';
        _openParenCount++;
        break;
      case 'square':
        if (_expression.isNotEmpty && !_isOperator(_expression[_expression.length - 1])) {
          _expression += '^2';
        }
        break;
      case 'factorial':
        if (_expression.isNotEmpty &&
            (_isDigit(_expression[_expression.length - 1]) ||
                _expression[_expression.length - 1] == ')')) {
          _expression += '!';
        }
        break;
      case 'reciprocal':
        if (_expression.isNotEmpty) {
          String currentExpr = _expression;
          _expression = '1÷($currentExpr)';
        } else {
          _expression = '1÷(';
          _openParenCount++;
        }
        break;
      case 'parenthesis':
        _handleAutoParenthesis();
        break;
    }

    _updatePreview();
    notifyListeners();
  }

  void _handleAutoParenthesis() {
    if (_expression.isEmpty ||
        _isOperator(_expression[_expression.length - 1]) ||
        _expression.endsWith('(')) {
      if (_expression.isNotEmpty) {
        String lastChar = _expression[_expression.length - 1];
        if (_isDigit(lastChar) || lastChar == ')') {
          _expression += '×';
        }
      }
      _expression += '(';
      _openParenCount++;
    } else if (_openParenCount > 0) {
      _expression += ')';
      _openParenCount--;
    } else {
      String lastChar = _expression[_expression.length - 1];
      if (_isDigit(lastChar) || lastChar == ')') {
        _expression += '×';
      }
      _expression += '(';
      _openParenCount++;
    }
  }

  void handleConstant(String constant) {
    if (_justEvaluated) {
      _expression = '';
      _result = '0';
      _hasResult = false;
      _openParenCount = 0;
      _justEvaluated = false;
    }

    if (_expression.isNotEmpty) {
      String lastChar = _expression[_expression.length - 1];
      if (_isDigit(lastChar) || lastChar == ')' || lastChar == 'π' || lastChar == 'e') {
        _expression += '×';
      }
    }
    _expression += constant;
    _updatePreview();
    notifyListeners();
  }

  void onClear() {
    _expression = '';
    _result = '0';
    _hasResult = false;
    _justEvaluated = false;
    _openParenCount = 0;
    notifyListeners();
  }

  void onBackspace() {
    if (_expression.isEmpty) return;

    if (_justEvaluated) {
      _justEvaluated = false;
      _hasResult = false;
      notifyListeners();
      return;
    }

    final funcPatterns = [
      'asin(', 'acos(', 'atan(', 'sinh(', 'cosh(', 'tanh(',
      'sqrt(', 'sin(', 'cos(', 'tan(', 'log(', 'ln('
    ];
    for (String pattern in funcPatterns) {
      if (_expression.endsWith(pattern)) {
        _expression = _expression.substring(0, _expression.length - pattern.length);
        if (_openParenCount > 0) _openParenCount--;
        _updatePreview();
        notifyListeners();
        return;
      }
    }

    String removed = _expression[_expression.length - 1];
    _expression = _expression.substring(0, _expression.length - 1);

    if (removed == '(') {
      if (_openParenCount > 0) _openParenCount--;
    } else if (removed == ')') {
      _openParenCount++;
    }

    _updatePreview();
    notifyListeners();
  }

  void onEquals() {
    if (_expression.isEmpty) return;

    String evalExpr = _expression;
    for (int i = 0; i < _openParenCount; i++) {
      evalExpr += ')';
    }

    String calculated = engine.evaluate(evalExpr);

    if (calculated != 'Error') {
      historyService.addCalculation(Calculation(
        expression: _expression,
        result: calculated,
        timestamp: DateTime.now(),
      ));
    }

    _result = calculated;
    _hasResult = true;
    _justEvaluated = true;
    _openParenCount = 0;
    notifyListeners();
  }

  void onToggleSign() {
    if (_justEvaluated && _result != '0' && _result != 'Error') {
      if (_result.startsWith('-') || _result.startsWith('−')) {
        _result = _result.substring(1);
      } else {
        _result = '−$_result';
      }
      _expression = _result;
      _justEvaluated = false;
      _hasResult = false;
      notifyListeners();
      return;
    }

    if (_expression.isEmpty) {
      _expression = '−';
      notifyListeners();
      return;
    }

    if (_expression == '−' || _expression == '-') {
      _expression = '';
      _updatePreview();
      notifyListeners();
      return;
    }

    final parenNegMatch = RegExp(r'\([−\-](\d+\.?\d*)\)$').firstMatch(_expression);
    if (parenNegMatch != null) {
      String num = parenNegMatch.group(1)!;
      _expression = _expression.substring(0, parenNegMatch.start) + num;
      _updatePreview();
      notifyListeners();
      return;
    }

    final opUnaryMatch = RegExp(r'([×÷+\−\^\(])([−\-])(\d+\.?\d*)$').firstMatch(_expression);
    if (opUnaryMatch != null) {
      String op = opUnaryMatch.group(1)!;
      String num = opUnaryMatch.group(3)!;
      _expression = _expression.substring(0, opUnaryMatch.start) + op + num;
      _updatePreview();
      notifyListeners();
      return;
    }

    final leadingNegMatch = RegExp(r'^[−\-](\d+\.?\d*)$').firstMatch(_expression);
    if (leadingNegMatch != null) {
      _expression = leadingNegMatch.group(1)!;
      _updatePreview();
      notifyListeners();
      return;
    }

    String lastNum = _getLastNumber();
    if (lastNum.isNotEmpty) {
      int startIdx = _expression.length - lastNum.length;
      if (startIdx == 0) {
        _expression = '(−$lastNum)';
      } else {
        _expression = '${_expression.substring(0, startIdx)}(−$lastNum)';
      }
    }

    _updatePreview();
    notifyListeners();
  }

  void onPercent() {
    if (_expression.isEmpty) return;
    if (_justEvaluated) {
      if (_result == 'Error') {
        _expression = '';
        _result = '0';
        _hasResult = false;
        _openParenCount = 0;
        _justEvaluated = false;
        notifyListeners();
        return;
      }
      _expression = _result;
      _justEvaluated = false;
    }
    _expression += '%';
    _updatePreview();
    notifyListeners();
  }

  void onToggleAngleMode() {
    engine.angleMode =
        engine.angleMode == AngleMode.deg ? AngleMode.rad : AngleMode.deg;
    if (_hasResult && _expression.isNotEmpty) {
      _updatePreview();
    }
    notifyListeners();
  }

  void onToggleInverse() {
    _isInverseMode = !_isInverseMode;
    notifyListeners();
  }

  void onModeChanged(CalculatorMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void paste(String text) {
    final sanitized = text.trim()
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('-', '−');

    final validCharRegex = RegExp(r'^[0-9\.\+\−\×\÷\(\)\^\%\s\π\e]+$');
    if (!validCharRegex.hasMatch(sanitized)) {
      final onlyDigits = sanitized.replaceAll(RegExp(r'[^0-9\.]'), '');
      if (onlyDigits.isNotEmpty) {
        onInput(onlyDigits);
      }
      return;
    }

    if (_justEvaluated || _result == 'Error') {
      _expression = '';
      _result = '0';
      _hasResult = false;
      _justEvaluated = false;
    }
    _expression += sanitized;

    int open = 0;
    for (int i = 0; i < _expression.length; i++) {
      if (_expression[i] == '(') open++;
      if (_expression[i] == ')') open--;
    }
    _openParenCount = open.clamp(0, 100);

    _updatePreview();
    notifyListeners();
  }

  void selectHistory(Calculation calc) {
    _expression = calc.expression;
    _result = calc.result;
    _hasResult = true;
    _justEvaluated = true;
    _openParenCount = 0;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await historyService.clear();
    notifyListeners();
  }

  Future<void> removeHistoryItem(int index) async {
    await historyService.removeAt(index);
    notifyListeners();
  }

  void memoryClear() {
    _memory = 0.0;
    notifyListeners();
  }

  void memoryRecall() {
    if (_memory == 0.0) return;
    String memStr = _memory == _memory.truncateToDouble()
        ? _memory.toInt().toString()
        : _memory.toString();
    onInput(memStr);
  }

  void memoryAdd() {
    double val = _getCurrentValue();
    _memory += val;
    notifyListeners();
  }

  void memorySubtract() {
    double val = _getCurrentValue();
    _memory -= val;
    notifyListeners();
  }

  double _getCurrentValue() {
    if (_hasResult && _result != 'Error') {
      return double.tryParse(_result) ?? 0.0;
    }
    if (_expression.isEmpty) return 0.0;
    String evalExpr = _expression;
    for (int i = 0; i < _openParenCount; i++) {
      evalExpr += ')';
    }
    String calculated = engine.evaluate(evalExpr);
    if (calculated != 'Error') {
      return double.tryParse(calculated) ?? 0.0;
    }
    return 0.0;
  }

  void _updatePreview() {
    if (_expression.isEmpty) {
      _result = '0';
      _hasResult = false;
      return;
    }

    String evalExpr = _expression;
    for (int i = 0; i < _openParenCount; i++) {
      evalExpr += ')';
    }

    String lastChar = evalExpr.isNotEmpty ? evalExpr[evalExpr.length - 1] : '';
    if (_isDigit(lastChar) ||
        lastChar == ')' ||
        lastChar == '!' ||
        lastChar == 'π' ||
        lastChar == 'e' ||
        lastChar == '%') {
      String preview = engine.evaluate(evalExpr);
      if (preview != 'Error') {
        _result = preview;
      }
    }
  }

  bool _isDigit(String ch) {
    if (ch.isEmpty) return false;
    int code = ch.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _isOperator(String ch) => '+-×÷−^'.contains(ch);

  String _getLastNumber() {
    if (_expression.isEmpty) return '';
    String result = '';
    for (int i = _expression.length - 1; i >= 0; i--) {
      String ch = _expression[i];
      if (_isDigit(ch) || ch == '.') {
        result = ch + result;
      } else {
        break;
      }
    }
    return result;
  }
}
