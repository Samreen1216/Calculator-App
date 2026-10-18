import 'package:flutter/material.dart';
import 'calculator_button.dart';

class StandardKeypad extends StatelessWidget {
  final void Function(String) onInput;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onEquals;
  final VoidCallback onToggleSign;
  final VoidCallback onPercent;

  const StandardKeypad({
    super.key,
    required this.onInput,
    required this.onClear,
    required this.onBackspace,
    required this.onEquals,
    required this.onToggleSign,
    required this.onPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: AC, +/-, %, ÷
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
        // Row 2: 7, 8, 9, ×
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
        // Row 3: 4, 5, 6, −
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
        // Row 4: 1, 2, 3, +
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
        // Row 5: 0, ., ⌫, =
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
}
