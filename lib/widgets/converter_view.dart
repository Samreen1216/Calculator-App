import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/calculator_controller.dart';
import '../models/unit_converter.dart';
import '../theme/app_theme.dart';
import 'calculator_button.dart';

class ConverterView extends StatefulWidget {
  final CalculatorController? controller;
  const ConverterView({super.key, this.controller});

  @override
  State<ConverterView> createState() => ConverterViewState();
}

class ConverterViewState extends State<ConverterView> {
  UnitCategory _selectedCategory = UnitCategory.length;
  late ConversionUnit _fromUnit;
  late ConversionUnit _toUnit;
  String _input = '1';
  String _output = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initUnits();
    _recalculate(triggerSave: false);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _saveConversion();
    super.dispose();
  }

  void _initUnits() {
    final units = UnitConverterService.unitsByCategory[_selectedCategory]!;
    _fromUnit = units[0];
    _toUnit = units.length > 1 ? units[1] : units[0];
  }

  void _recalculate({bool triggerSave = true}) {
    if (_input.isEmpty || _input == '−' || _input == '-') {
      _output = '0';
      return;
    }
    final val = double.tryParse(_input) ?? 0.0;
    final converted = UnitConverterService.convert(
      val,
      _fromUnit,
      _toUnit,
      _selectedCategory,
    );
    _output = UnitConverterService.format(converted);
    if (triggerSave) {
      _scheduleSave();
    }
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _saveConversion();
      }
    });
  }

  void saveCurrentConversion() {
    _debounceTimer?.cancel();
    _saveConversion();
  }

  void _saveConversion() {
    if (_input.isEmpty || _input == '0' || _output.isEmpty || _output == '0') {
      return;
    }
    widget.controller?.addConversionHistory(
      category: _selectedCategory.label,
      fromUnit: _fromUnit.symbol,
      toUnit: _toUnit.symbol,
      inputValue: _input,
      outputValue: _output,
    );
  }

  void restoreConversion({
    required String categoryName,
    required String fromUnitSymbol,
    required String toUnitSymbol,
    required String inputValue,
  }) {
    _debounceTimer?.cancel();
    final cat = UnitCategory.values.firstWhere(
      (c) => c.label.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => _selectedCategory,
    );
    final units = UnitConverterService.unitsByCategory[cat] ?? [];
    final from = units.firstWhere(
      (u) => u.symbol == fromUnitSymbol || u.name == fromUnitSymbol,
      orElse: () => units.isNotEmpty ? units[0] : _fromUnit,
    );
    final to = units.firstWhere(
      (u) => u.symbol == toUnitSymbol || u.name == toUnitSymbol,
      orElse: () => units.length > 1 ? units[1] : from,
    );

    setState(() {
      _selectedCategory = cat;
      _fromUnit = from;
      _toUnit = to;
      _input = inputValue;
      _recalculate(triggerSave: false);
    });
  }

  void _onCategoryChanged(UnitCategory category) {
    _debounceTimer?.cancel();
    _saveConversion();
    setState(() {
      _selectedCategory = category;
      _initUnits();
      _recalculate(triggerSave: false);
    });
  }

  void _swapUnits() {
    _debounceTimer?.cancel();
    _saveConversion();
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _recalculate(triggerSave: false);
    });
  }

  /// Public key handler called by keyboard shortcuts or internal buttons
  void handleKey(String key) => _onKeyPress(key);

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'AC') {
        _input = '0';
      } else if (key == '⌫') {
        if (_input.length > 1) {
          _input = _input.substring(0, _input.length - 1);
        } else {
          _input = '0';
        }
      } else if (key == '+/−') {
        if (_selectedCategory == UnitCategory.temperature) {
          if (_input.startsWith('-')) {
            _input = _input.substring(1);
          } else if (_input != '0') {
            _input = '-$_input';
          }
        }
      } else if (key == '.') {
        if (!_input.contains('.')) {
          _input += '.';
        }
      } else if (key == '⇄') {
        _swapUnits();
        return;
      } else {
        if (_input == '0') {
          _input = key;
        } else if (_input.length < 12) {
          _input += key;
        }
      }
      _recalculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final calcTheme = Theme.of(context).extension<CalculatorTheme>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = calcTheme?.primaryTextColor ??
        (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF202938));
    final cardBg = calcTheme?.displayColor ??
        (isDark ? const Color(0xFF2C2C2E) : Colors.white);
    final accentColor = calcTheme?.equalsButtonColor ?? const Color(0xFF347D78);

    final availableUnits =
        UnitConverterService.unitsByCategory[_selectedCategory]!;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useLandscapeLayout = constraints.maxWidth >= 560 || isLandscape;
        if (useLandscapeLayout) {
          return _buildLandscapeLayout(
            context,
            cardBg,
            primaryTextColor,
            accentColor,
            availableUnits,
          );
        } else {
          return _buildPortraitLayout(
            context,
            cardBg,
            primaryTextColor,
            accentColor,
            availableUnits,
          );
        }
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    Color cardBg,
    Color primaryTextColor,
    Color accentColor,
    List<ConversionUnit> availableUnits,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 600;
    final gap = isShort ? 4.0 : 8.0;

    return Column(
      children: [
        _buildCategorySelector(primaryTextColor, cardBg, accentColor),
        SizedBox(height: gap),
        _buildConversionCard(
          cardBg,
          primaryTextColor,
          accentColor,
          availableUnits,
        ),
        SizedBox(height: gap),
        Expanded(child: _buildKeypad()),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    Color cardBg,
    Color primaryTextColor,
    Color accentColor,
    List<ConversionUnit> availableUnits,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildCategorySelector(primaryTextColor, cardBg, accentColor),
              const SizedBox(height: 6),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildConversionCard(
                    cardBg,
                    primaryTextColor,
                    accentColor,
                    availableUnits,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: _buildKeypad(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
    Color primaryTextColor,
    Color cardBg,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: UnitCategory.values.map((cat) {
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              visualDensity: VisualDensity.compact,
              label: Text(
                cat.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : primaryTextColor,
                ),
              ),
              selected: isSelected,
              selectedColor: accentColor,
              backgroundColor: cardBg,
              onSelected: (_) => _onCategoryChanged(cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConversionCard(
    Color cardBg,
    Color primaryTextColor,
    Color accentColor,
    List<ConversionUnit> availableUnits,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 600;
    final cardPadding = isShort ? 8.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 5,
                child: DropdownButton<ConversionUnit>(
                  value: _fromUnit,
                  isDense: true,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: cardBg,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                  items: availableUnits.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text(
                        '${u.name} (${u.symbol})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (u) {
                    if (u != null) {
                      setState(() {
                        _fromUnit = u;
                        _recalculate();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _input,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(child: Divider(height: 14)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.swap_vert_rounded, color: accentColor, size: 20),
                onPressed: _swapUnits,
                tooltip: 'Swap units',
              ),
              const Expanded(child: Divider(height: 14)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 5,
                child: DropdownButton<ConversionUnit>(
                  value: _toUnit,
                  isDense: true,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: cardBg,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                  items: availableUnits.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text(
                        '${u.name} (${u.symbol})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (u) {
                    if (u != null) {
                      setState(() {
                        _toUnit = u;
                        _recalculate();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _output,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(label: '7', onPressed: () => _onKeyPress('7')),
              CalculatorButton(label: '8', onPressed: () => _onKeyPress('8')),
              CalculatorButton(label: '9', onPressed: () => _onKeyPress('9')),
              CalculatorButton(
                label: 'AC',
                type: ButtonType.clear,
                onPressed: () => _onKeyPress('AC'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(label: '4', onPressed: () => _onKeyPress('4')),
              CalculatorButton(label: '5', onPressed: () => _onKeyPress('5')),
              CalculatorButton(label: '6', onPressed: () => _onKeyPress('6')),
              CalculatorButton(
                label: '⌫',
                type: ButtonType.function,
                onPressed: () => _onKeyPress('⌫'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(label: '1', onPressed: () => _onKeyPress('1')),
              CalculatorButton(label: '2', onPressed: () => _onKeyPress('2')),
              CalculatorButton(label: '3', onPressed: () => _onKeyPress('3')),
              CalculatorButton(
                label: '+/−',
                type: ButtonType.function,
                onPressed: () => _onKeyPress('+/−'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CalculatorButton(label: '0', flex: 2, onPressed: () => _onKeyPress('0')),
              CalculatorButton(label: '.', onPressed: () => _onKeyPress('.')),
              CalculatorButton(
                label: '⇄',
                type: ButtonType.function,
                onPressed: _swapUnits,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
