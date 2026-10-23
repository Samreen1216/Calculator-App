import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class MemoryBar extends StatelessWidget {
  final bool hasMemory;
  final VoidCallback onClear;
  final VoidCallback onRecall;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;

  const MemoryBar({
    super.key,
    required this.hasMemory,
    required this.onClear,
    required this.onRecall,
    required this.onAdd,
    required this.onSubtract,
  });

  @override
  Widget build(BuildContext context) {
    final calcTheme = Theme.of(context).extension<CalculatorTheme>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final btnColor = calcTheme?.functionButtonColor ??
        (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEEF0F4));
    final textColor = calcTheme?.primaryTextColor ??
        (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF202938));
    final disabledTextColor = calcTheme?.secondaryTextColor.withValues(alpha: 0.4) ??
        Colors.grey.withValues(alpha: 0.4);
    final accentColor = calcTheme?.equalsButtonColor ?? const Color(0xFF347D78);

    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 500;
    final barHeight = isShort ? 28.0 : 36.0;
    final barFontSize = isShort ? 11.5 : 13.0;
    final vPadding = isShort ? 2.0 : 4.0;
    final spacing = isShort ? 4.0 : 6.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPadding),
      child: Row(
        children: [
          _buildMemoryButton(
            context,
            label: 'MC',
            isEnabled: hasMemory,
            onTap: onClear,
            btnColor: btnColor,
            textColor: hasMemory ? textColor : disabledTextColor,
            tooltip: 'Memory Clear',
            height: barHeight,
            fontSize: barFontSize,
          ),
          SizedBox(width: spacing),
          _buildMemoryButton(
            context,
            label: 'MR',
            isEnabled: hasMemory,
            onTap: onRecall,
            btnColor: btnColor,
            textColor: hasMemory ? accentColor : disabledTextColor,
            badge: hasMemory ? 'M' : null,
            tooltip: 'Memory Recall',
            height: barHeight,
            fontSize: barFontSize,
          ),
          SizedBox(width: spacing),
          _buildMemoryButton(
            context,
            label: 'M+',
            isEnabled: true,
            onTap: onAdd,
            btnColor: btnColor,
            textColor: textColor,
            tooltip: 'Memory Add',
            height: barHeight,
            fontSize: barFontSize,
          ),
          SizedBox(width: spacing),
          _buildMemoryButton(
            context,
            label: 'M−',
            isEnabled: true,
            onTap: onSubtract,
            btnColor: btnColor,
            textColor: textColor,
            tooltip: 'Memory Subtract',
            height: barHeight,
            fontSize: barFontSize,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryButton(
    BuildContext context, {
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
    required Color btnColor,
    required Color textColor,
    String? badge,
    required String tooltip,
    required double height,
    required double fontSize,
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: btnColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            mouseCursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            borderRadius: BorderRadius.circular(10),
            onTap: isEnabled
                ? () {
                    HapticFeedback.lightImpact();
                    onTap();
                  }
                : null,
            child: Container(
              height: height,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 3),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: textColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
