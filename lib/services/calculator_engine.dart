import 'dart:math' as math;

enum AngleMode { deg, rad }

class CalculatorEngine {
  AngleMode angleMode = AngleMode.deg;

  String evaluate(String expression) {
    try {
      // Pre-process the expression
      String processed = _preProcess(expression);
      // Tokenize
      List<String> tokens = _tokenize(processed);
      // Parse and evaluate using recursive descent parser
      _Parser parser = _Parser(tokens, angleMode);
      double result = parser.parseExpression();
      if (parser.position < tokens.length) {
        return 'Error';
      }
      return _formatResult(result);
    } catch (e) {
      return 'Error';
    }
  }

  String _preProcess(String expr) {
    return expr.trim();
  }

  List<String> _tokenize(String expr) {
    List<String> tokens = [];
    int i = 0;
    while (i < expr.length) {
      if (expr[i] == ' ') {
        i++;
        continue;
      }
      // Numbers (including decimals)
      if (_isDigit(expr[i]) || (expr[i] == '.' && i + 1 < expr.length && _isDigit(expr[i + 1]))) {
        String num = '';
        while (i < expr.length && (_isDigit(expr[i]) || expr[i] == '.')) {
          num += expr[i];
          i++;
        }
        tokens.add(num);
        continue;
      }
      // Functions and constants
      if (_isAlpha(expr[i])) {
        String word = '';
        while (i < expr.length && _isAlpha(expr[i]) && !_isOperator(expr[i])) {
          word += expr[i];
          i++;
        }
        // Check for inverse trig with superscript
        tokens.add(word);
        continue;
      }
      // Operators and parentheses
      String ch = expr[i];
      if (ch == '×') ch = '*';
      if (ch == '÷') ch = '/';
      if (ch == '−') ch = '-';
      tokens.add(ch);
      i++;
    }
    return tokens;
  }

  bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
  bool _isAlpha(String ch) {
    int code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || ch == 'π';
  }
  bool _isOperator(String ch) => '+-*/×÷−^%'.contains(ch);

  String _formatResult(double value) {
    if (value.isNaN) return 'Error';
    if (value.isInfinite) return value.isNegative ? '-∞' : '∞';

    // Check if it's an integer value
    if (value == value.truncateToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }

    // Format with reasonable precision
    String formatted = value.toStringAsPrecision(10);
    // Remove trailing zeros
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }

    // Use scientific notation for very large/small numbers
    if (value.abs() >= 1e15 || (value != 0 && value.abs() < 1e-10)) {
      formatted = value.toStringAsExponential(6);
      // Clean up exponent notation
      formatted = formatted.replaceAll(RegExp(r'0+e'), 'e');
      formatted = formatted.replaceAll(RegExp(r'\.e'), 'e');
    }

    return formatted;
  }
}

/// Recursive descent parser implementing proper operator precedence:
/// Expression = Term (('+' | '-') Term)*
/// Term = Power (('*' | '/') Power)*
/// Power = Unary ('^' Unary)*
/// Unary = ('-' Unary) | Postfix
/// Postfix = Primary ('!' | '%')*
/// Primary = Number | '(' Expression ')' | Function '(' Expression ')' | Constant
class _Parser {
  final List<String> tokens;
  final AngleMode angleMode;
  int position = 0;

  _Parser(this.tokens, this.angleMode);

  String? _peek() {
    if (position < tokens.length) return tokens[position];
    return null;
  }

  String _consume() {
    return tokens[position++];
  }

  bool _match(String expected) {
    if (_peek() == expected) {
      position++;
      return true;
    }
    return false;
  }

  bool _isNumber(String? token) {
    if (token == null) return false;
    return double.tryParse(token) != null;
  }

  double parseExpression() {
    double result = _parseTerm();
    while (_peek() == '+' || _peek() == '-') {
      String op = _consume();
      int beforeTerm = position;
      double right = _parseTerm();
      bool isRightPercent = position > beforeTerm && tokens[position - 1] == '%';
      if (isRightPercent) {
        double delta = result * right;
        if (op == '+') {
          result += delta;
        } else {
          result -= delta;
        }
      } else {
        if (op == '+') {
          result += right;
        } else {
          result -= right;
        }
      }
    }
    return result;
  }

  double _parseTerm() {
    double result = _parsePower();
    while (_peek() == '*' || _peek() == '/') {
      String op = _consume();
      double right = _parsePower();
      if (op == '*') {
        result *= right;
      } else {
        if (right == 0) {
          throw Exception('Division by zero');
        }
        result /= right;
      }
    }
    return result;
  }

  double _parsePower() {
    double base = _parseUnary();
    if (_peek() == '^') {
      _consume();
      double exponent = _parsePower(); // Right-associative
      return math.pow(base, exponent).toDouble();
    }
    return base;
  }

  double _parseUnary() {
    if (_peek() == '-') {
      _consume();
      return -_parseUnary();
    }
    if (_peek() == '+') {
      _consume();
      return _parseUnary();
    }
    return _parsePostfix();
  }

  double _parsePostfix() {
    double result = _parsePrimary();
    while (_peek() == '!' || _peek() == '%') {
      String op = _consume();
      if (op == '!') {
        result = _factorial(result);
      } else if (op == '%') {
        result = result / 100.0;
      }
    }
    return result;
  }

  double _parsePrimary() {
    String? token = _peek();
    if (token == null) throw Exception('Unexpected end of expression');

    // Number
    double? number = double.tryParse(token);
    if (number != null) {
      _consume();
      // Handle implicit multiplication: 2π, 2(3+4), 2sqrt(4)
      if (_peek() == '(' || _peek() == 'π' || _peek() == 'pi' || _peek() == 'e' || _isFunction(_peek())) {
        double right = _parsePrimary();
        return number * right;
      }
      return number;
    }

    // Parenthesized expression
    if (token == '(') {
      _consume();
      double result = parseExpression();
      if (!_match(')')) {
        // Auto-close parenthesis
      }
      // Handle implicit multiplication: (2+3)(4+5), (2)3, (2)π, (2)sqrt(4)
      if (_peek() == '(' || _peek() == 'π' || _peek() == 'pi' || _peek() == 'e' || _isFunction(_peek()) || _isNumber(_peek())) {
        double right = _parsePrimary();
        return result * right;
      }
      return result;
    }

    // Constants
    if (token == 'π' || token == 'pi') {
      _consume();
      if (_peek() == '(' || _peek() == 'e' || _isFunction(_peek()) || _isNumber(_peek())) {
        double right = _parsePrimary();
        return math.pi * right;
      }
      return math.pi;
    }
    // Only match standalone 'e', not as part of function names
    if (token == 'e' && !_isFunction(token)) {
      _consume();
      if (_peek() == '(' || _peek() == 'π' || _peek() == 'pi' || _isFunction(_peek()) || _isNumber(_peek())) {
        double right = _parsePrimary();
        return math.e * right;
      }
      return math.e;
    }

    // Functions
    if (_isFunction(token)) {
      _consume();
      // Expect '(' after function name
      double arg;
      if (_peek() == '(') {
        _consume();
        arg = parseExpression();
        _match(')'); // consume closing paren
      } else {
        arg = _parsePrimary();
      }
      return _evaluateFunction(token, arg);
    }

    throw Exception('Unexpected token: $token');
  }

  bool _isFunction(String? token) {
    if (token == null) return false;
    const functions = [
      'sin', 'cos', 'tan',
      'asin', 'acos', 'atan',
      'sinh', 'cosh', 'tanh',
      'log', 'ln', 'sqrt',
      'abs', 'ceil', 'floor',
      'exp',
    ];
    return functions.contains(token);
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;
  double _toDegrees(double radians) => radians * 180.0 / math.pi;

  double _evaluateFunction(String func, double arg) {
    switch (func) {
      case 'sin':
        double radArg = angleMode == AngleMode.deg ? _toRadians(arg) : arg;
        double result = math.sin(radArg);
        // Clean up near-zero results (e.g., sin(180°))
        if (result.abs() < 1e-14) return 0;
        return result;
      case 'cos':
        double radArg = angleMode == AngleMode.deg ? _toRadians(arg) : arg;
        double result = math.cos(radArg);
        if (result.abs() < 1e-14) return 0;
        return result;
      case 'tan':
        double radArg = angleMode == AngleMode.deg ? _toRadians(arg) : arg;
        double cosVal = math.cos(radArg);
        if (cosVal.abs() < 1e-14) throw Exception('Undefined: tan at 90°');
        double result = math.sin(radArg) / cosVal;
        if (result.abs() < 1e-14) return 0;
        return result;
      case 'asin':
        if (arg < -1 || arg > 1) throw Exception('Domain error: asin');
        double result = math.asin(arg);
        return angleMode == AngleMode.deg ? _toDegrees(result) : result;
      case 'acos':
        if (arg < -1 || arg > 1) throw Exception('Domain error: acos');
        double result = math.acos(arg);
        return angleMode == AngleMode.deg ? _toDegrees(result) : result;
      case 'atan':
        double result = math.atan(arg);
        return angleMode == AngleMode.deg ? _toDegrees(result) : result;
      case 'sinh':
        return (math.exp(arg) - math.exp(-arg)) / 2.0;
      case 'cosh':
        return (math.exp(arg) + math.exp(-arg)) / 2.0;
      case 'tanh':
        double ep = math.exp(arg);
        double em = math.exp(-arg);
        return (ep - em) / (ep + em);
      case 'ceil':
        return arg.ceilToDouble();
      case 'floor':
        return arg.floorToDouble();
      case 'log':
        if (arg <= 0) throw Exception('Domain error: log');
        return math.log(arg) / math.ln10;
      case 'ln':
        if (arg <= 0) throw Exception('Domain error: ln');
        return math.log(arg);
      case 'sqrt':
        if (arg < 0) throw Exception('Domain error: sqrt');
        return math.sqrt(arg);
      case 'abs':
        return arg.abs();
      case 'exp':
        return math.exp(arg);
      default:
        throw Exception('Unknown function: $func');
    }
  }

  double _factorial(double n) {
    if (n < 0) throw Exception('Factorial of negative number');
    if (n != n.truncateToDouble()) throw Exception('Factorial of non-integer');
    int intN = n.toInt();
    if (intN > 170) throw Exception('Factorial overflow');
    if (intN == 0 || intN == 1) return 1;
    double result = 1;
    for (int i = 2; i <= intN; i++) {
      result *= i;
    }
    return result;
  }
}
