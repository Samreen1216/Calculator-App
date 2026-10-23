import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CalculatorDisplay extends StatelessWidget {
  final String expression;
  final String result;
  final bool hasResult;
  final ValueChanged<String>? onPaste;

  const CalculatorDisplay({
    super.key,
    required this.expression,
    required this.result,
    this.hasResult = false,
    this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    final calcTheme = Theme.of(context).extension<CalculatorTheme>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = calcTheme?.primaryTextColor ??
        (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF202938));
    final secondaryColor = calcTheme?.secondaryTextColor ??
        (isDark ? const Color(0xFF98989D) : const Color(0xFF778196));
    final displayBg = calcTheme?.displayColor ??
        (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF));

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final shortSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    final isLandscape = screenWidth > screenHeight;
    final isShort = screenHeight < 550;
    final scaleFactor = (shortSide / 375).clamp(0.7, 1.4);

    final expressionBase = isShort ? 15.0 : (isLandscape ? 18.0 : 22.0);
    final resultBase = isShort ? 30.0 : (isLandscape ? 36.0 : 46.0);
    final hPadding = (20 * scaleFactor).clamp(12.0, 28.0);
    final vPadding = isShort ? 6.0 : (isLandscape ? 8.0 : (16 * scaleFactor).clamp(8.0, 22.0));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(
        color: displayBg,
        borderRadius: BorderRadius.circular((18 * scaleFactor).clamp(10.0, 22.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expression display
          GestureDetector(
            onLongPress: () => _showClipboardMenu(context, isExpression: true),
            onSecondaryTap: () => _showClipboardMenu(context, isExpression: true),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  expression.isEmpty ? ' ' : expression,
                  style: TextStyle(
                    fontSize: _scaledFontSize(
                      expression,
                      expressionBase * scaleFactor,
                    ),
                    fontWeight: FontWeight.w400,
                    color: hasResult ? secondaryColor : primaryColor,
                    height: 1.25,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
          SizedBox(height: isShort ? 2 : (isLandscape ? 4 : 6)),
          // Result display
          GestureDetector(
            onLongPress: () => _showClipboardMenu(context, isExpression: false),
            onSecondaryTap: () => _showClipboardMenu(context, isExpression: false),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  result.isEmpty ? '0' : result,
                  style: TextStyle(
                    fontSize: _scaledFontSize(
                      result,
                      resultBase * scaleFactor,
                    ),
                    fontWeight: FontWeight.w600,
                    color: hasResult ? primaryColor : secondaryColor,
                    height: 1.15,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClipboardMenu(BuildContext context, {required bool isExpression}) async {
    final hasClipboard = await Clipboard.hasStrings();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(isExpression ? 'Copy Expression' : 'Copy Result'),
                onTap: () {
                  final textToCopy = isExpression ? expression : result;
                  if (textToCopy.isNotEmpty && textToCopy != '0') {
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isExpression ? 'Expression copied' : 'Result copied',
                        ),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  Navigator.pop(sheetContext);
                },
              ),
              if (hasClipboard && onPaste != null)
                ListTile(
                  leading: const Icon(Icons.paste_rounded),
                  title: const Text('Paste from Clipboard'),
                  onTap: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null && data!.text!.isNotEmpty) {
                      onPaste!(data.text!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pasted from clipboard'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  double _scaledFontSize(String text, double baseFontSize) {
    if (text.length <= 10) return baseFontSize;
    if (text.length <= 15) return baseFontSize * 0.85;
    if (text.length <= 20) return baseFontSize * 0.72;
    if (text.length <= 30) return baseFontSize * 0.6;
    return baseFontSize * 0.5;
  }
}
