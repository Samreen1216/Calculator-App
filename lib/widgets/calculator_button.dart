import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

enum ButtonType { number, operator, equals, function, clear }

class CalculatorButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final ButtonType type;
  final double flex;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final String? semanticsLabel;

  const CalculatorButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onLongPress,
    this.type = ButtonType.number,
    this.flex = 1,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final calcTheme = Theme.of(context).extension<CalculatorTheme>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final shortSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    final isShort = screenHeight < 500;
    final scaleFactor = isShort ? 0.75 : (shortSide / 375).clamp(0.7, 1.3);

    Color bgColor;
    Color fgColor;
    double size;

    switch (type) {
      case ButtonType.number:
        bgColor = backgroundColor ??
            (calcTheme?.numberButtonColor ?? _getColor(context, 'number'));
        fgColor = textColor ??
            (calcTheme?.primaryTextColor ?? _getTextColor(context, 'primary'));
        size = (fontSize ?? 22) * scaleFactor;
        break;
      case ButtonType.operator:
        bgColor = backgroundColor ??
            (calcTheme?.operatorButtonColor ?? _getColor(context, 'operator'));
        fgColor = textColor ??
            (calcTheme?.primaryTextColor ?? _getTextColor(context, 'primary'));
        size = (fontSize ?? 22) * scaleFactor;
        break;
      case ButtonType.equals:
        bgColor = backgroundColor ??
            (calcTheme?.equalsButtonColor ?? _getColor(context, 'equals'));
        fgColor = textColor ??
            (calcTheme?.equalsTextColor ?? Colors.white);
        size = (fontSize ?? 24) * scaleFactor;
        break;
      case ButtonType.function:
        bgColor = backgroundColor ??
            (calcTheme?.functionButtonColor ?? _getColor(context, 'function'));
        fgColor = textColor ??
            (calcTheme?.secondaryTextColor ?? _getTextColor(context, 'secondary'));
        size = (fontSize ?? 18) * scaleFactor;
        break;
      case ButtonType.clear:
        bgColor = backgroundColor ??
            (calcTheme?.functionButtonColor ?? _getColor(context, 'function'));
        fgColor = textColor ?? const Color(0xFFE74C3C);
        size = (fontSize ?? 20) * scaleFactor;
        break;
    }

    final borderRadius = (16 * scaleFactor).clamp(8.0, 18.0);
    final padding = isShort ? 2.0 : (4 * scaleFactor).clamp(2.0, 6.0);
    final effectiveSemantics = semanticsLabel ?? _deriveSemanticsLabel(label);

    return Expanded(
      flex: flex.toInt(),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Semantics(
          button: true,
          label: effectiveSemantics,
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: () {
                HapticFeedback.lightImpact();
                onPressed();
              },
              onLongPress: onLongPress != null
                  ? () {
                      HapticFeedback.mediumImpact();
                      onLongPress!();
                    }
                  : null,
              child: Container(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: icon != null
                      ? Icon(icon, color: fgColor, size: size)
                      : Text(
                          label,
                          style: TextStyle(
                            fontSize: size,
                            fontWeight: FontWeight.w500,
                            color: fgColor,
                          ),
                          maxLines: 1,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _deriveSemanticsLabel(String text) {
    switch (text) {
      case '÷': return 'divide';
      case '×': return 'multiply';
      case '−': return 'minus';
      case '+': return 'plus';
      case '=': return 'equals';
      case 'AC': return 'all clear';
      case '⌫': return 'backspace';
      case '+/−': return 'toggle sign';
      case '%': return 'percent';
      case 'x²': return 'squared';
      case 'xʸ': return 'power';
      case '√': return 'square root';
      case 'INV': return 'inverse function';
      case 'DEG': return 'degrees';
      case 'RAD': return 'radians';
      default: return text;
    }
  }

  Color _getColor(BuildContext context, String type) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      switch (type) {
        case 'number': return const Color(0xFF3A3A3C);
        case 'operator': return const Color(0xFF2A3A52);
        case 'equals': return const Color(0xFF347D78);
        case 'function': return const Color(0xFF48484A);
        default: return const Color(0xFF3A3A3C);
      }
    } else {
      switch (type) {
        case 'number': return const Color(0xFFEEF0F4);
        case 'operator': return const Color(0xFFDCE7F5);
        case 'equals': return const Color(0xFF347D78);
        case 'function': return const Color(0xFFE5E8EE);
        default: return const Color(0xFFEEF0F4);
      }
    }
  }

  Color _getTextColor(BuildContext context, String type) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return type == 'primary'
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF98989D);
    } else {
      return type == 'primary'
          ? const Color(0xFF202938)
          : const Color(0xFF778196);
    }
  }
}
