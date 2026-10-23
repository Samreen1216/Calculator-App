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
  final CalculatorMode? initialMode;

  const CalculatorScreen({
    super.key,
    required this.onToggleTheme,
    this.controller,
    this.initialMode,
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
    if (widget.initialMode != null) {
      _controller.onModeChanged(widget.initialMode!);
    }
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

  bool _showSideHistory = false;

  void _showHistory() {
    if (_controller.mode == CalculatorMode.converter) {
      _converterKey.currentState?.saveCurrentConversion();
    }

    final width = MediaQuery.of(context).size.width;
    if (width >= 800) {
      setState(() {
        _showSideHistory = !_showSideHistory;
      });
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => HistorySheet(
            history: _controller.history,
            initialFilter: HistoryFilter.all,
            onClear: _controller.clearHistory,
            onSelect: (calc) {
              if (calc.isConversion) {
                _converterKey.currentState?.restoreConversion(
                  categoryName: calc.category ?? '',
                  fromUnitSymbol: calc.fromUnit ?? '',
                  toUnitSymbol: calc.toUnit ?? '',
                  inputValue: calc.inputValue ?? calc.expression.split(' ').first,
                );
              }
              _controller.selectHistory(calc);
            },
            onDeleteItem: (index) {
              final deleted = _controller.history[index];
              _controller.removeHistoryItem(index);
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(deleted.isConversion
                      ? 'Conversion deleted'
                      : 'Calculation deleted'),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      _controller.restoreHistoryItem(index, deleted);
                    },
                  ),
                ),
              );
            },
            onClose: () => Navigator.maybePop(sheetContext),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calcTheme = Theme.of(context).extension<CalculatorTheme>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = calcTheme?.primaryTextColor ??
        (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF202938));
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  final isLandscape = availableWidth > availableHeight;
                  final isShort = availableHeight < 550;
                  final isWide = availableWidth >= 800;
                  final showSidePanel = isWide && _showSideHistory;

                  final verticalGap = isShort ? 4.0 : (isLandscape ? 6.0 : 10.0);
                  final calcMaxWidth = _controller.mode == CalculatorMode.standard
                      ? (isLandscape ? 560.0 : 480.0)
                      : (isLandscape ? 860.0 : 480.0);

                  Widget calculatorColumn = Column(
                    children: [
                      // Header
                      if (isLandscape)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: isShort ? 2 : 4),
                          child: Row(
                            children: [
                              Text(
                                'Calculator',
                                style: TextStyle(
                                  fontSize: isShort ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: primaryTextColor,
                                ),
                              ),
                              SizedBox(width: isShort ? 8 : 12),
                              Flexible(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 320),
                                  child: TabSelector(
                                    selectedMode: _controller.mode,
                                    onModeChanged: _controller.onModeChanged,
                                  ),
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
                                icon: Icon(
                                  showSidePanel
                                      ? Icons.history_toggle_off_rounded
                                      : Icons.history_rounded,
                                  size: 22,
                                  color: showSidePanel
                                      ? const Color(0xFF347D78)
                                      : null,
                                ),
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
                          padding: EdgeInsets.symmetric(vertical: isShort ? 4 : 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Calculator',
                                  style: TextStyle(
                                    fontSize: isShort ? 18 : 22,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_controller.mode ==
                                      CalculatorMode.scientific)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      margin: const EdgeInsets.only(right: 6),
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
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      showSidePanel
                                          ? Icons.history_toggle_off_rounded
                                          : Icons.history_rounded,
                                      size: 24,
                                      color: showSidePanel
                                          ? const Color(0xFF347D78)
                                          : null,
                                    ),
                                    onPressed: _showHistory,
                                    tooltip: 'History',
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
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

                      SizedBox(height: verticalGap),

                      // Mode switcher body
                      if (_controller.mode == CalculatorMode.converter)
                        Expanded(
                          child: ConverterView(
                            key: _converterKey,
                            controller: _controller,
                          ),
                        )
                      else ...[
                        // Memory registers bar
                        MemoryBar(
                          hasMemory: _controller.hasMemory,
                          onClear: _controller.memoryClear,
                          onRecall: _controller.memoryRecall,
                          onAdd: _controller.memoryAdd,
                          onSubtract: _controller.memorySubtract,
                        ),

                        SizedBox(height: isShort ? 2 : 4),

                        // Display
                        CalculatorDisplay(
                          expression: _controller.expression,
                          result: _controller.formattedResult,
                          hasResult: _controller.hasResult,
                          onPaste: _controller.paste,
                        ),

                        SizedBox(height: verticalGap),

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
                        height: isShort
                            ? bottomPadding + 2
                            : (isLandscape
                                ? bottomPadding + 4
                                : bottomPadding + 8),
                      ),
                    ],
                  );

                  if (showSidePanel) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: calcMaxWidth),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isLandscape ? 12 : 16,
                                ),
                                child: calculatorColumn,
                              ),
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        SizedBox(
                          width: 350,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
                            child: ListenableBuilder(
                              listenable: _controller,
                              builder: (context, _) => HistorySheet(
                                history: _controller.history,
                                initialFilter: HistoryFilter.all,
                                onClear: _controller.clearHistory,
                                onSelect: (calc) {
                                  if (calc.isConversion) {
                                    _converterKey.currentState?.restoreConversion(
                                      categoryName: calc.category ?? '',
                                      fromUnitSymbol: calc.fromUnit ?? '',
                                      toUnitSymbol: calc.toUnit ?? '',
                                      inputValue: calc.inputValue ?? calc.expression.split(' ').first,
                                    );
                                  }
                                  _controller.selectHistory(calc);
                                },
                                onDeleteItem: (index) {
                                  final deleted = _controller.history[index];
                                  _controller.removeHistoryItem(index);
                                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(deleted.isConversion
                                          ? 'Conversion deleted'
                                          : 'Calculation deleted'),
                                      duration: const Duration(seconds: 4),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          _controller.restoreHistoryItem(index, deleted);
                                        },
                                      ),
                                    ),
                                  );
                                },
                                isBottomSheet: false,
                                onClose: () => setState(() => _showSideHistory = false),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: calcMaxWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 12 : 16,
                        ),
                        child: calculatorColumn,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
