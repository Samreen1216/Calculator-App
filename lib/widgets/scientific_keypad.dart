import 'package:flutter/material.dart';
import 'calculator_button.dart';

class ScientificKeypad extends StatelessWidget {
  final void Function(String) onInput;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onEquals;
  final VoidCallback onToggleSign;
  final VoidCallback onPercent;
  final void Function(String) onFunction;
  final void Function(String) onConstant;
  final bool isInverseMode;
  final VoidCallback onToggleInverse;
  final String angleMode; // 'DEG' or 'RAD'
  final VoidCallback onToggleAngleMode;

  const ScientificKeypad({
    super.key,
    required this.onInput,
    required this.onClear,
    required this.onBackspace,
    required this.onEquals,
    required this.onToggleSign,
    required this.onPercent,
    required this.onFunction,
    required this.onConstant,
    required this.isInverseMode,
    required this.onToggleInverse,
    required this.angleMode,
    required this.onToggleAngleMode,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useLandscape = constraints.maxWidth >= 560 || isLandscape;
        if (useLandscape) {
          return _buildLandscapeLayout(context);
        } else {
          return _buildPortraitLayout(context);
        }
      },
    );
  }

  /// 8-row layout for portrait orientation:
  /// 3 rows of scientific keys + 5 rows of standard keys, each stretched to share vertical space.
  Widget _buildPortraitLayout(BuildContext context) {
    return Column(
      children: [
        // Scientific Row 1: INV, DEG/RAD, sin, cos, tan
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(
                label: 'INV',
                type: ButtonType.function,
                fontSize: 14,
                backgroundColor: isInverseMode
                    ? const Color(0xFF347D78).withValues(alpha: 0.2)
                    : null,
                onPressed: onToggleInverse,
              ),
              CalculatorButton(
                label: angleMode,
                type: ButtonType.function,
                fontSize: 14,
                onPressed: onToggleAngleMode,
              ),
              CalculatorButton(
                label: isInverseMode ? 'sin⁻¹' : 'sin',
                type: ButtonType.function,
                fontSize: 14,
                onPressed: () => onFunction(isInverseMode ? 'asin' : 'sin'),
              ),
              CalculatorButton(
                label: isInverseMode ? 'cos⁻¹' : 'cos',
                type: ButtonType.function,
                fontSize: 14,
                onPressed: () => onFunction(isInverseMode ? 'acos' : 'cos'),
              ),
              CalculatorButton(
                label: isInverseMode ? 'tan⁻¹' : 'tan',
                type: ButtonType.function,
                fontSize: 14,
                onPressed: () => onFunction(isInverseMode ? 'atan' : 'tan'),
              ),
            ],
          ),
        ),
        // Scientific Row 2: x², xʸ, √, ln, log
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(
                label: 'x²',
                type: ButtonType.function,
                fontSize: 14,
                onPressed: () => onFunction('square'),
              ),
              CalculatorButton(
                label: 'xʸ',
                type: ButtonType.function,
                fontSize: 14,
                onPressed: () => onInput('^'),
              ),
              CalculatorButton(
                label: '√',
                type: ButtonType.function,
                fontSize: 16,
                onPressed: () => onFunction('sqrt'),
              ),
              CalculatorButton(
                label: 'ln',
                type: ButtonType.function,
                fontSize: 14,
                onPressed: () => onFunction('ln'),
              ),
              CalculatorButton(
                label: 'log',
                type: ButtonType.function,
                fontSize: 14,
                onPressed: () => onFunction('log'),
              ),
            ],
          ),
        ),
        // Scientific Row 3: !, 1/x, π, e, ( )
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(
                label: '!',
                type: ButtonType.function,
                fontSize: 16,
                onPressed: () => onFunction('factorial'),
              ),
              CalculatorButton(
                label: '1/x',
                type: ButtonType.function,
                fontSize: 14,
                onPressed: () => onFunction('reciprocal'),
              ),
              CalculatorButton(
                label: 'π',
                type: ButtonType.function,
                fontSize: 16,
                onPressed: () => onConstant('π'),
              ),
              CalculatorButton(
                label: 'e',
                type: ButtonType.function,
                fontSize: 16,
                onPressed: () => onConstant('e'),
              ),
              CalculatorButton(
                label: '( )',
                type: ButtonType.function,
                fontSize: 15,
                onPressed: () => onFunction('parenthesis'),
              ),
            ],
          ),
        ),
        // Standard Row 1: AC, +/-, %, ÷
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(
                label: 'AC',
                type: ButtonType.clear,
                onPressed: onClear,
              ),
              CalculatorButton(
                label: '+/−',
                type: ButtonType.function,
                onPressed: onToggleSign,
              ),
              CalculatorButton(
                label: '%',
                type: ButtonType.function,
                onPressed: onPercent,
              ),
              CalculatorButton(
                label: '÷',
                type: ButtonType.operator,
                onPressed: () => onInput('÷'),
              ),
            ],
          ),
        ),
        // Standard Row 2: 7, 8, 9, ×
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(
                label: '7',
                onPressed: () => onInput('7'),
              ),
              CalculatorButton(
                label: '8',
                onPressed: () => onInput('8'),
              ),
              CalculatorButton(
                label: '9',
                onPressed: () => onInput('9'),
              ),
              CalculatorButton(
                label: '×',
                type: ButtonType.operator,
                onPressed: () => onInput('×'),
              ),
            ],
          ),
        ),
        // Standard Row 3: 4, 5, 6, −
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(
                label: '4',
                onPressed: () => onInput('4'),
              ),
              CalculatorButton(
                label: '5',
                onPressed: () => onInput('5'),
              ),
              CalculatorButton(
                label: '6',
                onPressed: () => onInput('6'),
              ),
              CalculatorButton(
                label: '−',
                type: ButtonType.operator,
                onPressed: () => onInput('−'),
              ),
            ],
          ),
        ),
        // Standard Row 4: 1, 2, 3, +
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(
                label: '1',
                onPressed: () => onInput('1'),
              ),
              CalculatorButton(
                label: '2',
                onPressed: () => onInput('2'),
              ),
              CalculatorButton(
                label: '3',
                onPressed: () => onInput('3'),
              ),
              CalculatorButton(
                label: '+',
                type: ButtonType.operator,
                onPressed: () => onInput('+'),
              ),
            ],
          ),
        ),
        // Standard Row 5: 0, ., ⌫, =
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(
                label: '0',
                flex: 1,
                onPressed: () => onInput('0'),
              ),
              CalculatorButton(
                label: '.',
                onPressed: () => onInput('.'),
              ),
              CalculatorButton(
                label: '⌫',
                type: ButtonType.function,
                fontSize: 20,
                onPressed: onBackspace,
                onLongPress: onClear,
              ),
              CalculatorButton(
                label: '=',
                type: ButtonType.equals,
                onPressed: onEquals,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 5-row x 7-column layout for landscape orientation:
  /// 3 columns of scientific functions on left + 4 columns of standard keys on right.
  Widget _buildLandscapeLayout(BuildContext context) {
    return Column(
      children: [
        // Row 1
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scientific 3 cols
              CalculatorButton(
                label: 'INV',
                type: ButtonType.function,
                fontSize: 13,
                backgroundColor: isInverseMode
                    ? const Color(0xFF347D78).withValues(alpha: 0.2)
                    : null,
                onPressed: onToggleInverse,
              ),
              CalculatorButton(
                label: angleMode,
                type: ButtonType.function,
                fontSize: 13,
                onPressed: onToggleAngleMode,
              ),
              CalculatorButton(
                label: isInverseMode ? 'sin⁻¹' : 'sin',
                type: ButtonType.function,
                fontSize: 13,
                onPressed: () => onFunction(isInverseMode ? 'asin' : 'sin'),
              ),
              // Standard 4 cols
              CalculatorButton(
                label: 'AC',
                type: ButtonType.clear,
                fontSize: 15,
                onPressed: onClear,
              ),
              CalculatorButton(
                label: '+/−',
                type: ButtonType.function,
                fontSize: 15,
                onPressed: onToggleSign,
              ),
              CalculatorButton(
                label: '%',
                type: ButtonType.function,
                fontSize: 15,
                onPressed: onPercent,
              ),
              CalculatorButton(
                label: '÷',
                type: ButtonType.operator,
                fontSize: 18,
                onPressed: () => onInput('÷'),
              ),
            ],
          ),
        ),
        // Row 2
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scientific
              CalculatorButton(
                label: 'ln',
                type: ButtonType.function,
                fontSize: 13,
                onPressed: () => onFunction('ln'),
              ),
              CalculatorButton(
                label: 'log',
                type: ButtonType.function,
                fontSize: 13,
                onPressed: () => onFunction('log'),
              ),
              CalculatorButton(
                label: isInverseMode ? 'cos⁻¹' : 'cos',
                type: ButtonType.function,
                fontSize: 13,
                onPressed: () => onFunction(isInverseMode ? 'acos' : 'cos'),
              ),
              // Standard
              CalculatorButton(
                label: '7',
                fontSize: 18,
                onPressed: () => onInput('7'),
              ),
              CalculatorButton(
                label: '8',
                fontSize: 18,
                onPressed: () => onInput('8'),
              ),
              CalculatorButton(
                label: '9',
                fontSize: 18,
                onPressed: () => onInput('9'),
              ),
              CalculatorButton(
                label: '×',
                type: ButtonType.operator,
                fontSize: 18,
                onPressed: () => onInput('×'),
              ),
            ],
          ),
        ),
        // Row 3
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scientific
              CalculatorButton(
                label: '√',
                type: ButtonType.function,
                fontSize: 15,
                onPressed: () => onFunction('sqrt'),
              ),
              CalculatorButton(
                label: 'x²',
                type: ButtonType.function,
                fontSize: 13,
                onPressed: () => onFunction('square'),
              ),
              CalculatorButton(
                label: isInverseMode ? 'tan⁻¹' : 'tan',
                type: ButtonType.function,
                fontSize: 13,
                onPressed: () => onFunction(isInverseMode ? 'atan' : 'tan'),
              ),
              // Standard
              CalculatorButton(
                label: '4',
                fontSize: 18,
                onPressed: () => onInput('4'),
              ),
              CalculatorButton(
                label: '5',
                fontSize: 18,
                onPressed: () => onInput('5'),
              ),
              CalculatorButton(
                label: '6',
                fontSize: 18,
                onPressed: () => onInput('6'),
              ),
              CalculatorButton(
                label: '−',
                type: ButtonType.operator,
                fontSize: 18,
                onPressed: () => onInput('−'),
              ),
            ],
          ),
        ),
        // Row 4
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scientific
              CalculatorButton(
                label: 'xʸ',
                type: ButtonType.function,
                fontSize: 13,
                onPressed: () => onInput('^'),
              ),
              CalculatorButton(
                label: '1/x',
                type: ButtonType.function,
                fontSize: 13,
                onPressed: () => onFunction('reciprocal'),
              ),
              CalculatorButton(
                label: 'π',
                type: ButtonType.function,
                fontSize: 15,
                onPressed: () => onConstant('π'),
              ),
              // Standard
              CalculatorButton(
                label: '1',
                fontSize: 18,
                onPressed: () => onInput('1'),
              ),
              CalculatorButton(
                label: '2',
                fontSize: 18,
                onPressed: () => onInput('2'),
              ),
              CalculatorButton(
                label: '3',
                fontSize: 18,
                onPressed: () => onInput('3'),
              ),
              CalculatorButton(
                label: '+',
                type: ButtonType.operator,
                fontSize: 18,
                onPressed: () => onInput('+'),
              ),
            ],
          ),
        ),
        // Row 5
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scientific
              CalculatorButton(
                label: '!',
                type: ButtonType.function,
                fontSize: 15,
                onPressed: () => onFunction('factorial'),
              ),
              CalculatorButton(
                label: '( )',
                type: ButtonType.function,
                fontSize: 14,
                onPressed: () => onFunction('parenthesis'),
              ),
              CalculatorButton(
                label: 'e',
                type: ButtonType.function,
                fontSize: 15,
                onPressed: () => onConstant('e'),
              ),
              // Standard
              CalculatorButton(
                label: '0',
                fontSize: 18,
                onPressed: () => onInput('0'),
              ),
              CalculatorButton(
                label: '.',
                fontSize: 18,
                onPressed: () => onInput('.'),
              ),
              CalculatorButton(
                label: '⌫',
                type: ButtonType.function,
                fontSize: 18,
                onPressed: onBackspace,
                onLongPress: onClear,
              ),
              CalculatorButton(
                label: '=',
                type: ButtonType.equals,
                fontSize: 20,
                onPressed: onEquals,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
