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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          ),
          const SizedBox(width: 6),
          _buildMemoryButton(
            context,
            label: 'MR',
            isEnabled: hasMemory,
            onTap: onRecall,
            btnColor: btnColor,
            textColor: hasMemory ? accentColor : disabledTextColor,
            badge: hasMemory ? 'M' : null,
            tooltip: 'Memory Recall',
          ),
          const SizedBox(width: 6),
          _buildMemoryButton(
            context,
            label: 'M+',
            isEnabled: true,
            onTap: onAdd,
            btnColor: btnColor,
            textColor: textColor,
            tooltip: 'Memory Add',
          ),
          const SizedBox(width: 6),
          _buildMemoryButton(
            context,
            label: 'M−',
            isEnabled: true,
            onTap: onSubtract,
            btnColor: btnColor,
            textColor: textColor,
            tooltip: 'Memory Subtract',
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
  }) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: btnColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: isEnabled
                ? () {
                    HapticFeedback.lightImpact();
                    onTap();
                  }
                : null,
            child: Container(
              height: 36,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
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
