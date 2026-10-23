import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CalculatorMode { standard, scientific, converter }

class TabSelector extends StatelessWidget {
  final CalculatorMode selectedMode;
  final ValueChanged<CalculatorMode> onModeChanged;

  const TabSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final calcTheme = Theme.of(context).extension<CalculatorTheme>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final bgColor = calcTheme?.numberButtonColor ??
        (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEF0F4));
    final selectedBg = calcTheme?.displayColor ??
        (isDark ? const Color(0xFF48484A) : const Color(0xFFFFFFFF));
    final selectedText = calcTheme?.primaryTextColor ??
        (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF202938));
    final unselectedText = calcTheme?.secondaryTextColor ??
        (isDark ? const Color(0xFF98989D) : const Color(0xFF778196));

    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 500;
    final vPadding = isShort ? 4.0 : (isLandscape ? 6.0 : 8.0);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab(
            label: 'Standard',
            isSelected: selectedMode == CalculatorMode.standard,
            selectedBg: selectedBg,
            selectedText: selectedText,
            unselectedText: unselectedText,
            verticalPadding: vPadding,
            onTap: () => onModeChanged(CalculatorMode.standard),
          ),
          _buildTab(
            label: 'Scientific',
            isSelected: selectedMode == CalculatorMode.scientific,
            selectedBg: selectedBg,
            selectedText: selectedText,
            unselectedText: unselectedText,
            verticalPadding: vPadding,
            onTap: () => onModeChanged(CalculatorMode.scientific),
          ),
          _buildTab(
            label: 'Converter',
            isSelected: selectedMode == CalculatorMode.converter,
            selectedBg: selectedBg,
            selectedText: selectedText,
            unselectedText: unselectedText,
            verticalPadding: vPadding,
            onTap: () => onModeChanged(CalculatorMode.converter),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required Color selectedBg,
    required Color selectedText,
    required Color unselectedText,
    required double verticalPadding,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedText : unselectedText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
