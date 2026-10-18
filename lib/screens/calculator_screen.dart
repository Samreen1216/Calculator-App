import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/calculator_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/calculator_display.dart';
import '../widgets/standard_keypad.dart';
import '../widgets/scientific_keypad.dart';
import '../widgets/tab_selector.dart';
import '../widgets/history_sheet.dart';
import '../widgets/memory_bar.dart';
import '../widgets/converter_view.dart';

class CalculatorScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final CalculatorController? controller;

  const CalculatorScreen({
    super.key,
    required this.onToggleTheme,
    this.controller,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final CalculatorController _controller;
  late final FocusNode _focusNode;
  final GlobalKey<ConverterViewState> _converterKey = GlobalKey<ConverterViewState>();
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = CalculatorController();
      _ownsController = true;
    }
    _controller.historyService.init();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final logical = event.logicalKey;
    final char = event.character;

    if (_controller.mode == CalculatorMode.converter) {
      if (logical == LogicalKeyboardKey.backspace) {
        _converterKey.currentState?.handleKey('⌫');
        return KeyEventResult.handled;
      } else if (logical == LogicalKeyboardKey.escape) {
        _converterKey.currentState?.handleKey('AC');
        return KeyEventResult.handled;
      } else if (char != null && '0123456789.'.contains(char)) {
        _converterKey.currentState?.handleKey(char);
        return KeyEventResult.handled;
      } else if (char == ',') {
        _converterKey.currentState?.handleKey('.');
        return KeyEventResult.handled;
      } else if (char == '-' || char == '+') {
        _converterKey.currentState?.handleKey('+/−');
        return KeyEventResult.handled;
      } else if (char == 's' || char == 'S' || logical == LogicalKeyboardKey.tab) {
        _converterKey.currentState?.handleKey('⇄');
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (logical == LogicalKeyboardKey.enter ||
        logical == LogicalKeyboardKey.numpadEnter) {
      _controller.onEquals();
      return KeyEventResult.handled;
    } else if (logical == LogicalKeyboardKey.backspace) {
      _controller.onBackspace();
      return KeyEventResult.handled;
    } else if (logical == LogicalKeyboardKey.escape) {
      _controller.onClear();
      return KeyEventResult.handled;
    } else if (logical == LogicalKeyboardKey.equal && char == '=') {
      _controller.onEquals();
      return KeyEventResult.handled;
    } else if (logical == LogicalKeyboardKey.numpadMultiply) {
      _controller.onInput('×');
      return KeyEventResult.handled;
    } else if (logical == LogicalKeyboardKey.numpadAdd) {
      _controller.onInput('+');
      return KeyEventResult.handled;
    } else if (logical == LogicalKeyboardKey.numpadSubtract) {
      _controller.onInput('−');
      return KeyEventResult.handled;
    } else if (logical == LogicalKeyboardKey.numpadDivide) {
      _controller.onInput('÷');
      return KeyEventResult.handled;
    }

    if (char != null && char.isNotEmpty) {
      if ('0123456789'.contains(char)) {
        _controller.onInput(char);
        return KeyEventResult.handled;
      } else if (char == '.' || char == ',') {
        _controller.onInput('.');
        return KeyEventResult.handled;
      } else if (char == '+') {
        _controller.onInput('+');
        return KeyEventResult.handled;
      } else if (char == '-') {
        _controller.onInput('−');
        return KeyEventResult.handled;
      } else if (char == '*' || char == 'x' || char == 'X') {
        _controller.onInput('×');
        return KeyEventResult.handled;
      } else if (char == '/') {
        _controller.onInput('÷');
        return KeyEventResult.handled;
      } else if (char == '(' || char == ')') {
        _controller.onInput(char);
        return KeyEventResult.handled;
      } else if (char == '^') {
        _controller.onInput('^');
        return KeyEventResult.handled;
      } else if (char == '%') {
        _controller.onPercent();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistorySheet(
        history: _controller.history,
        onClear: _controller.clearHistory,
        onSelect: _controller.selectHistory,
        onDeleteItem: _controller.removeHistoryItem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calcTheme = Theme.of(context).extension<CalculatorTheme>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = calcTheme?.primaryTextColor ??
        (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF202938));
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? 860 : 480,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 12 : 16,
                    ),
                    child: Column(
                      children: [
                        // Header
                        if (isLandscape)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  'Calculator',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 320),
                                  child: TabSelector(
                                    selectedMode: _controller.mode,
                                    onModeChanged: _controller.onModeChanged,
                                  ),
                                ),
                                const Spacer(),
                                if (_controller.mode == CalculatorMode.scientific)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF347D78)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _controller.angleModeLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF347D78),
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.history_rounded, size: 22),
                                  onPressed: _showHistory,
                                  tooltip: 'History',
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    isDark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    size: 22,
                                  ),
                                  onPressed: widget.onToggleTheme,
                                  tooltip: 'Toggle theme',
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Calculator',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (_controller.mode ==
                                        CalculatorMode.scientific)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF347D78)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _controller.angleModeLabel,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF347D78),
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.history_rounded,
                                          size: 24),
                                      onPressed: _showHistory,
                                      tooltip: 'History',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isDark
                                            ? Icons.light_mode_rounded
                                            : Icons.dark_mode_rounded,
                                        size: 24,
                                      ),
                                      onPressed: widget.onToggleTheme,
                                      tooltip: 'Toggle theme',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          TabSelector(
                            selectedMode: _controller.mode,
                            onModeChanged: _controller.onModeChanged,
                          ),
                        ],

                        SizedBox(height: isLandscape ? 6 : 10),

                        // Mode switcher body
                        if (_controller.mode == CalculatorMode.converter)
                          Expanded(child: ConverterView(key: _converterKey))
                        else ...[
                          // Memory registers bar
                          MemoryBar(
                            hasMemory: _controller.hasMemory,
                            onClear: _controller.memoryClear,
                            onRecall: _controller.memoryRecall,
                            onAdd: _controller.memoryAdd,
                            onSubtract: _controller.memorySubtract,
                          ),

                          const SizedBox(height: 4),

                          // Display
                          CalculatorDisplay(
                            expression: _controller.expression,
                            result: _controller.formattedResult,
                            hasResult: _controller.hasResult,
                            onPaste: _controller.paste,
                          ),

                          SizedBox(height: isLandscape ? 6 : 10),

                          // Keypad
                          Expanded(
                            child: _controller.mode == CalculatorMode.standard
                                ? StandardKeypad(
                                    onInput: _controller.onInput,
                                    onClear: _controller.onClear,
                                    onBackspace: _controller.onBackspace,
                                    onEquals: _controller.onEquals,
                                    onToggleSign: _controller.onToggleSign,
                                    onPercent: _controller.onPercent,
                                  )
                                : ScientificKeypad(
                                    onInput: _controller.onInput,
                                    onClear: _controller.onClear,
                                    onBackspace: _controller.onBackspace,
                                    onEquals: _controller.onEquals,
                                    onToggleSign: _controller.onToggleSign,
                                    onPercent: _controller.onPercent,
                                    onFunction: _controller.handleFunction,
                                    onConstant: _controller.handleConstant,
                                    isInverseMode: _controller.isInverseMode,
                                    onToggleInverse:
                                        _controller.onToggleInverse,
                                    angleMode: _controller.angleModeLabel,
                                    onToggleAngleMode:
                                        _controller.onToggleAngleMode,
                                  ),
                          ),
                        ],

                        SizedBox(
                          height: isLandscape
                              ? bottomPadding + 4
                              : bottomPadding + 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
