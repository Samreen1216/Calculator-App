import 'package:flutter/material.dart';
import '../models/calculation.dart';
import '../theme/app_theme.dart';
import '../controllers/calculator_controller.dart';

class HistorySheet extends StatelessWidget {
  final List<Calculation> history;
  final VoidCallback onClear;
  final ValueChanged<Calculation> onSelect;
  final ValueChanged<int>? onDeleteItem;

  const HistorySheet({
    super.key,
    required this.history,
    required this.onClear,
    required this.onSelect,
    this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    final calcTheme = Theme.of(context).extension<CalculatorTheme>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = calcTheme?.displayColor ??
        (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF));
    final primaryText = calcTheme?.primaryTextColor ??
        (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF202938));
    final secondaryText = calcTheme?.secondaryTextColor ??
        (isDark ? const Color(0xFF98989D) : const Color(0xFF778196));
    final dividerColor = calcTheme?.numberButtonColor ??
        (isDark ? const Color(0xFF48484A) : const Color(0xFFEEF0F4));

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                      ),
                    ),
                    if (history.isNotEmpty)
                      TextButton(
                        onPressed: () => _confirmClear(context),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            color: Color(0xFFE74C3C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: dividerColor),
              // History list
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: secondaryText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No history yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final calc = history[index];
                      return Dismissible(
                        key: ValueKey('${calc.timestamp.millisecondsSinceEpoch}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: const Color(0xFFE74C3C),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          if (onDeleteItem != null) {
                            onDeleteItem!(index);
                          }
                        },
                        child: InkWell(
                          onTap: () {
                            onSelect(calc);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  _formatTime(calc.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryText.withValues(alpha: 0.8),
                                  ),
                                ),
                                const Spacer(),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        calc.expression,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: secondaryText,
                                        ),
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '= ${CalculatorController.formatNumber(calc.result)}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: primaryText,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all saved calculations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              onClear();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
